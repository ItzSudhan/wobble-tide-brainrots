--!strict
-- BaseService: each player's base. Assigns plots, shows owned brainrots on pedestals, places a carried
-- brainrot when its owner steps onto the base, pays income every second and runs the base-lock shield.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local Builder = require(game:GetService("ServerStorage").WorldBuilder.BrainrotBuilder)
local PlayerState = require(script.Parent.PlayerState)
local Market = require(script.Parent.BrainrotMarket)

local Base = {}

local world: any
local remotes: any
local plotOwners: { [number]: Player } = {}
local pedestalModels: { [Player]: { [number]: Model } } = {}

local function plotOf(player: Player)
	local state = PlayerState.get(player)
	return state and world.Plots[state.plot]
end

function Base.claimPlot(player: Player): number?
	for i = 1, #world.Plots do
		if plotOwners[i] == nil then
			plotOwners[i] = player
			world.Plots[i].ownerLabel.Text = string.upper(player.DisplayName) .. "'S BASE"
			return i
		end
	end
	return nil
end

function Base.releasePlot(player: Player)
	for i, owner in plotOwners do
		if owner == player then
			plotOwners[i] = nil
			world.Plots[i].ownerLabel.Text = "EMPTY BASE"
			world.Plots[i].shield.Transparency = 1
		end
	end
	for _, model in pedestalModels[player] or {} do
		model:Destroy()
	end
	pedestalModels[player] = nil
end

-- Make the pedestals match the player's slots: build what is new, remove what is gone.
function Base.refreshPedestals(player: Player)
	local state = PlayerState.get(player)
	local plot = plotOf(player)
	if not state or not plot then
		return
	end
	local models = pedestalModels[player] or {}
	pedestalModels[player] = models
	for i = 1, Catalog.Tuning.PedestalsPerBase do
		local owned = state.slots[i]
		local model = models[i]
		local matches = model and owned and model:GetAttribute("BrainrotId") == owned.id and model:GetAttribute("Mutation") == owned.mutation
		if not matches then
			if model then
				model:Destroy()
				models[i] = nil
			end
			if owned then
				local fresh = Builder.buildBrainrot(owned.id, owned.mutation)
				Builder.attachLabel(fresh, owned.id, owned.mutation, nil)
				fresh:PivotTo(plot.pedestals[i])
				fresh:SetAttribute("Slot", i)
				fresh.Parent = workspace
				models[i] = fresh
			end
		end
	end
end

function Base.pedestalModel(player: Player, slot: number): Model?
	local models = pedestalModels[player]
	return models and models[slot]
end

-- Stepping onto your own base with a brainrot on your head puts it on the first free pedestal.
local function tryPlaceCarried(player: Player)
	local state = PlayerState.get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not state or not state.carrying or not root then
		return
	end
	local plot = world.plotContaining(root.Position)
	if not plot or plot.index ~= state.plot then
		return
	end
	local slot = PlayerState.freeSlot(state)
	if not slot then
		return
	end
	local owned = Market.takeCarried(player)
	if not owned then
		return
	end
	state.slots[slot] = owned
	PlayerState.publish(player)
	Base.refreshPedestals(player)
	local entry = Catalog.ById[owned.id]
	local model = Base.pedestalModel(player, slot)
	if model then
		remotes.Fx:FireAllClients("place", model, Catalog.rarityOf(entry).color)
	end
	remotes.Notify:FireClient(player, entry.name .. " placed! +" .. Catalog.formatMoney(Catalog.incomeOf(owned.id, owned.mutation) * PlayerState.multiplier(state)) .. "/s", Color3.fromRGB(120, 255, 140))
end

-- Pay every player their income each second and float a +$ over each earning brainrot.
local function payIncome()
	for player, state in PlayerState.all() do
		local mult = PlayerState.multiplier(state)
		local total = 0
		local popups = {}
		for slot, owned in state.slots do
			local amount = Catalog.incomeOf(owned.id, owned.mutation) * mult
			total += amount
			local model = Base.pedestalModel(player, slot)
			if model then
				table.insert(popups, { model, amount })
			end
		end
		if total > 0 then
			PlayerState.addMoney(player, total)
			remotes.Fx:FireClient(player, "income", popups)
		end
	end
end

function Base.isShielded(player: Player): boolean
	local state = PlayerState.get(player)
	return state ~= nil and workspace:GetServerTimeNow() < state.shieldUntil
end

-- Base lock: a force-field dome for ShieldSeconds, then a cooldown.
function Base.lockBase(player: Player)
	local state = PlayerState.get(player)
	local plot = plotOf(player)
	if not state or not plot then
		return
	end
	local now = workspace:GetServerTimeNow()
	if now < state.shieldReadyAt then
		remotes.Notify:FireClient(player, string.format("Shield recharging: %ds", math.ceil(state.shieldReadyAt - now)), Color3.fromRGB(255, 170, 80))
		return
	end
	state.shieldUntil = now + Catalog.Tuning.ShieldSeconds
	state.shieldReadyAt = state.shieldUntil + Catalog.Tuning.ShieldCooldown
	plot.shield.Transparency = 0.2
	PlayerState.publish(player)
	remotes.Notify:FireClient(player, "BASE LOCKED! The gull can't touch you for " .. Catalog.Tuning.ShieldSeconds .. "s", Color3.fromRGB(110, 210, 255))
	task.delay(Catalog.Tuning.ShieldSeconds, function()
		if workspace:GetServerTimeNow() >= state.shieldUntil - 0.1 then
			plot.shield.Transparency = 1
		end
	end)
end

function Base.start(deps)
	world = deps.world
	remotes = deps.remotes
	for _, plot in world.Plots do
		plot.lockPrompt.Triggered:Connect(function(player)
			local state = PlayerState.get(player)
			if state and state.plot == plot.index then
				Base.lockBase(player)
			else
				remotes.Notify:FireClient(player, "That's not your base!", Color3.fromRGB(255, 90, 90))
			end
		end)
	end
	task.spawn(function()
		while true do
			task.wait(1)
			payIncome()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			for _, player in Players:GetPlayers() do
				tryPlaceCarried(player)
			end
		end
	end)
end

return Base
