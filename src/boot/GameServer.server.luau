--!strict
-- GameServer: boots Wobble Tide Brainrots. Builds the island, creates the remotes, starts every
-- service and wires players in and out. The server owns money,
-- inventory, spawning and both threats; the client (ReplicatedFirst.HudController) only draws and asks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Modules = script.Parent

local World = require(ServerStorage.WorldBuilder)
local PlayerState = require(Modules.PlayerState)
local Market = require(Modules.BrainrotMarket)
local Base = require(Modules.BaseService)
local Threats = require(Modules.ThreatDirector)

local function createRemotes()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	local remotes = {}
	for _, name in { "Notify", "Fx", "Action" } do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		remotes[name] = event
	end
	folder.Parent = ReplicatedStorage
	return remotes
end

local remotes = createRemotes()
local world = World.buildIsland()
local deps = { world = world, remotes = remotes }
Market.start(deps)
Base.start(deps)
Threats.start(deps)

local function onCharacterAdded(player: Player, character: Model)
	local state = PlayerState.get(player)
	local plot = state and world.Plots[state.plot]
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if plot then
		task.defer(function()
			root.CFrame = plot.spawn
		end)
	end
	PlayerState.applyWalkSpeed(player)
	humanoid.Died:Connect(function()
		Market.dropOnDeath(player)
	end)
end

local function onPlayerAdded(player: Player)
	local plot = Base.claimPlot(player) or 0
	PlayerState.create(player, plot)
	Base.refreshPedestals(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	if plot == 0 then
		remotes.Notify:FireClient(player, "All four bases are taken: you can still watch the chaos!", Color3.fromRGB(255, 200, 80))
	end
end

-- The client may only ask; the server checks and applies every purchase.
local lastAction: { [Player]: number } = {}
remotes.Action.OnServerEvent:Connect(function(player: Player, action: unknown)
	if os.clock() - (lastAction[player] or 0) < 0.3 then
		return
	end
	lastAction[player] = os.clock()
	if action == "Rebirth" then
		if PlayerState.rebirthPlayer(player) then
			Base.refreshPedestals(player)
			remotes.Fx:FireClient(player, "rebirth")
			remotes.Notify:FireClient(player, "REBIRTH! Income x" .. PlayerState.multiplier(PlayerState.get(player) :: any) .. " and luckier spawns", Color3.fromRGB(255, 120, 255))
		else
			remotes.Notify:FireClient(player, "Not enough money to rebirth yet", Color3.fromRGB(255, 90, 90))
		end
	elseif action == "Lock" then
		Base.lockBase(player)
	elseif action == "Speed" then
		if PlayerState.buySpeedUpgrade(player) then
			remotes.Notify:FireClient(player, "Faster feet! Outrun that wave.", Color3.fromRGB(120, 255, 140))
		else
			remotes.Notify:FireClient(player, "Can't buy speed right now", Color3.fromRGB(255, 90, 90))
		end
	end
end)

-- Studio-only play-test hook (never exists in a live server): grant money or fill a base for testing.
local function setupStudioTestHook()
	if not game:GetService("RunService"):IsStudio() then
		return
	end
	local hook = Instance.new("BindableFunction")
	hook.Name = "StudioTestHook"
	hook.OnInvoke = function(command: string, arg: any)
		local player = Players:GetPlayers()[1]
		local state = player and PlayerState.get(player)
		if not state then
			return "no player"
		end
		if command == "grant" then
			PlayerState.addMoney(player, arg)
		elseif command == "fill" then
			for i, owned in arg do
				state.slots[i] = owned
			end
			PlayerState.publish(player)
			Base.refreshPedestals(player)
		end
		return "ok"
	end
	hook.Parent = ServerStorage
end
setupStudioTestHook()

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerRemoving:Connect(function(player)
	Market.dropOnDeath(player)
	Base.releasePlot(player)
	PlayerState.remove(player)
	lastAction[player] = nil
end)
