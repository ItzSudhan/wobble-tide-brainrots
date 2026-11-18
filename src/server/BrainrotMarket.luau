--!strict
-- BrainrotMarket: spawns brainrots that waddle down the Brainrot Runway, sells them through
-- ProximityPrompts, and handles the bought brainrot riding on the buyer's head until it is placed or lost.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local Builder = require(game:GetService("ServerStorage").WorldBuilder.BrainrotBuilder)
local PlayerState = require(script.Parent.PlayerState)

local Market = {}

type Walker = { model: Model, x: number, id: string, mutation: string, price: number, phase: number }

local walkers: { Walker } = {}
local carried: { [Player]: Model } = {}
local rng = Random.new()
local world: any
local remotes: any
local runwayFolder: Folder

local function notify(player: Player, text: string, color: Color3?)
	remotes.Notify:FireClient(player, text, color or Color3.new(1, 1, 1))
end

local function removeWalker(walker: Walker)
	local i = table.find(walkers, walker)
	if i then
		table.remove(walkers, i)
	end
end

-- Weld a freshly built copy of the brainrot above the player's head.
local function attachCarriedModel(player: Player, id: string, mutation: string)
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head or not character then
		return
	end
	local model = Builder.buildBrainrot(id, mutation)
	model:ScaleTo(model:GetScale() * 0.6)
	Builder.attachLabel(model, id, mutation, nil)
	local root = model.PrimaryPart :: BasePart
	root.Anchored = false
	model:PivotTo(head.CFrame * CFrame.new(0, 1.2, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = root
	weld.Parent = root
	model.Name = "CarriedBrainrot"
	model.Parent = character
	carried[player] = model
end

local function onBuyPrompt(walker: Walker, player: Player)
	local state = PlayerState.get(player)
	if not state or not walker.model.Parent then
		return
	end
	if state.carrying then
		notify(player, "Hands full! Run your brainrot home first.", Color3.fromRGB(255, 170, 80))
		return
	end
	if PlayerState.freeSlot(state) == nil then
		notify(player, "Your base is full! Rebirth or wait for the gull...", Color3.fromRGB(255, 170, 80))
		return
	end
	if not PlayerState.trySpend(player, walker.price) then
		notify(player, "Not enough money for " .. Catalog.ById[walker.id].name, Color3.fromRGB(255, 90, 90))
		return
	end
	local pos = walker.model:GetPivot().Position
	removeWalker(walker)
	walker.model:Destroy()
	state.carrying = { id = walker.id, mutation = walker.mutation }
	state.caught += 1
	attachCarriedModel(player, walker.id, walker.mutation)
	PlayerState.publish(player)
	local entry = Catalog.ById[walker.id]
	remotes.Fx:FireAllClients("burst", pos, Catalog.rarityOf(entry).color)
	notify(player, "Bought " .. entry.name .. "! Run it home before the wave!", Catalog.rarityOf(entry).color)
end

local function spawnWalker()
	local luck = 0
	for _, state in PlayerState.all() do
		luck = math.max(luck, state.rebirths)
	end
	local entry = Catalog.rollBrainrot(rng, luck)
	local mutation = Catalog.rollMutation(rng)
	local price = Catalog.priceOf(entry.id, mutation)
	local model = Builder.buildBrainrot(entry.id, mutation)
	Builder.attachLabel(model, entry.id, mutation, Catalog.formatMoney(price))
	local walker: Walker = { model = model, x = world.RunwayStartX, id = entry.id, mutation = mutation, price = price, phase = rng:NextNumber() * 6 }
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. Catalog.formatMoney(price)
	prompt.ObjectText = entry.name
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 14
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		onBuyPrompt(walker, player)
	end)
	model:PivotTo(CFrame.new(walker.x, 0.6, world.RunwayZ))
	model.Parent = runwayFolder
	table.insert(walkers, walker)
end

-- Waddle every walker along the runway; despawn at the far end.
local function stepWalkers(dt: number)
	local t = os.clock()
	for i = #walkers, 1, -1 do
		local w = walkers[i]
		w.x += Catalog.Tuning.WalkSpeed * dt
		if w.x > world.RunwayEndX then
			w.model:Destroy()
			table.remove(walkers, i)
		else
			local bob = math.abs(math.sin(t * 6 + w.phase)) * 0.6
			local tilt = math.sin(t * 6 + w.phase) * 0.12
			w.model:PivotTo(CFrame.new(w.x, 0.6 + bob, world.RunwayZ) * CFrame.Angles(0, 0, tilt))
		end
	end
end

-- Hand the carried brainrot over (to be placed on a pedestal); returns what was carried.
function Market.takeCarried(player: Player)
	local state = PlayerState.get(player)
	if not state or not state.carrying then
		return nil
	end
	local owned = state.carrying
	state.carrying = nil
	if carried[player] then
		carried[player]:Destroy()
		carried[player] = nil
	end
	PlayerState.publish(player)
	return owned
end

-- The tide (or a fall) takes the carried brainrot: it tumbles off and floats out to sea.
function Market.loseCarried(player: Player): string?
	local state = PlayerState.get(player)
	if not state or not state.carrying then
		return nil
	end
	local name = Catalog.ById[state.carrying.id].name
	state.carrying = nil
	local model = carried[player]
	carried[player] = nil
	if model then
		local root = model.PrimaryPart :: BasePart
		for _, d in root:GetChildren() do
			if d:IsA("WeldConstraint") and d.Part0 ~= root then
				d:Destroy()
			end
		end
		root.Anchored = true
		model.Parent = runwayFolder
		local value = Instance.new("CFrameValue")
		value.Value = model:GetPivot()
		value.Changed:Connect(function(cf)
			model:PivotTo(cf)
		end)
		local goal = model:GetPivot() * CFrame.new(0, 8, -40) * CFrame.Angles(math.rad(200), 0, math.rad(90))
		TweenService:Create(value, TweenInfo.new(2.5, Enum.EasingStyle.Quad), { Value = goal }):Play()
		task.delay(2.6, function()
			model:Destroy()
			value:Destroy()
		end)
	end
	PlayerState.publish(player)
	return name
end

function Market.dropOnDeath(player: Player)
	local state = PlayerState.get(player)
	if state and state.carrying then
		state.carrying = nil
		carried[player] = nil
		PlayerState.publish(player)
	end
end

-- The wave sweeps the runway clean; every walker it touches is washed off.
function Market.washRunway()
	for i = #walkers, 1, -1 do
		local w = walkers[i]
		table.remove(walkers, i)
		local model = w.model
		local value = Instance.new("CFrameValue")
		value.Value = model:GetPivot()
		value.Changed:Connect(function(cf)
			model:PivotTo(cf)
		end)
		TweenService:Create(value, TweenInfo.new(1.6, Enum.EasingStyle.Quad), { Value = value.Value * CFrame.new(0, 6, 30) * CFrame.Angles(math.rad(160), 0, 0) }):Play()
		task.delay(1.7, function()
			model:Destroy()
			value:Destroy()
		end)
	end
end

function Market.start(deps)
	world = deps.world
	remotes = deps.remotes
	runwayFolder = Instance.new("Folder")
	runwayFolder.Name = "RunwayBrainrots"
	runwayFolder.Parent = workspace
	RunService.Heartbeat:Connect(stepWalkers)
	-- pre-fill the runway so the island is busy from the first second
	for x = world.RunwayStartX, world.RunwayEndX - 20, 20 do
		spawnWalker()
		walkers[#walkers].x = x
	end
	task.spawn(function()
		while true do
			task.wait(Catalog.Tuning.SpawnInterval)
			spawnWalker()
		end
	end)
end

return Market
