--!strict
-- GullRaid: the Crumb Bandit, a masked seagull, raids a base every RaidInterval seconds. A locked
-- base (shield dome) bounces it off; an unlocked one loses a random brainrot, carried off to sea.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.BaseService)

local Raid = {}

local world: any
local remotes: any
local rng = Random.new()

local function gullPart(model: Model, shape: Enum.PartType, size: Vector3, color: Color3, cf: CFrame, wedge: boolean?): BasePart
	local p: BasePart
	if wedge then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		part.Shape = shape
		p = part
	end
	p.Size = size
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = cf
	p.Parent = model
	return p
end

-- The Crumb Bandit: round white body, grey wings, orange beak, black bandit mask.
local function buildCrumbBandit(): Model
	local model = Instance.new("Model")
	model.Name = "CrumbBandit"
	local body = gullPart(model, Enum.PartType.Ball, Vector3.one * 5, Color3.fromRGB(250, 250, 250), CFrame.new())
	model.PrimaryPart = body
	gullPart(model, Enum.PartType.Ball, Vector3.one * 3.4, Color3.fromRGB(250, 250, 250), CFrame.new(0, 1.8, -2.6))
	gullPart(model, Enum.PartType.Block, Vector3.new(3.5, 0.9, 0.4), Color3.fromRGB(20, 20, 25), CFrame.new(0, 2.2, -4.2))
	for _, side in { -1, 1 } do
		gullPart(model, Enum.PartType.Ball, Vector3.one * 0.7, Color3.new(1, 1, 1), CFrame.new(side * 0.8, 2.2, -4.45))
		gullPart(model, Enum.PartType.Block, Vector3.new(9, 0.4, 3.5), Color3.fromRGB(150, 155, 165), CFrame.new(side * 6.5, 0.8, 0) * CFrame.Angles(0, 0, side * math.rad(15)))
	end
	gullPart(model, Enum.PartType.Block, Vector3.new(1, 0.7, 2.4), Color3.fromRGB(255, 150, 30), CFrame.new(0, 1.4, -5.2))
	gullPart(model, Enum.PartType.Block, Vector3.new(3, 0.4, 2.5), Color3.fromRGB(150, 155, 165), CFrame.new(0, 0.4, 3.2))
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(22, 4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "THE CRUMB BANDIT"
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	gui.Parent = body
	return model
end

local function flyTo(model: Model, goal: CFrame, seconds: number)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()
	value.Changed:Connect(function(cf)
		model:PivotTo(cf)
	end)
	local tween = TweenService:Create(value, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Value = goal })
	tween:Play()
	tween.Completed:Wait()
	value:Destroy()
end

local function chooseTarget(): Player?
	local candidates = {}
	for player, state in PlayerState.all() do
		if world.Plots[state.plot] and next(state.slots) ~= nil then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

-- Fly in over the target base; steal unless the base is locked or nearly empty.
function Raid.launchGullRaid(target: Player)
	local state = PlayerState.get(target)
	local plot = state and world.Plots[state.plot]
	if not state or not plot then
		return
	end
	local gull = buildCrumbBandit()
	local hover = CFrame.lookAt(plot.center + Vector3.new(0, 26, 0), plot.center + Vector3.new(0, 26, 60)) * CFrame.Angles(0, math.pi, 0)
	gull:PivotTo(CFrame.new(plot.center + Vector3.new(0, 70, 320)))
	gull.Parent = workspace
	flyTo(gull, hover, 4)

	local slots = {}
	for slot in state.slots do
		table.insert(slots, slot)
	end
	if Base.isShielded(target) then
		remotes.Fx:FireAllClients("bonk", plot.center + Vector3.new(0, 26, 0))
		remotes.Notify:FireAllClients("BONK! " .. target.DisplayName .. "'s shield sent the Crumb Bandit packing!", Color3.fromRGB(110, 210, 255))
	elseif #slots <= 1 then
		remotes.Notify:FireAllClients("The Crumb Bandit sniffs " .. target.DisplayName .. "'s base... too poor to rob.", Color3.fromRGB(255, 220, 120))
	else
		local slot = slots[rng:NextInteger(1, #slots)]
		local owned = state.slots[slot] :: any
		local victim = Base.pedestalModel(target, slot)
		local spot = plot.pedestals[slot].Position
		flyTo(gull, CFrame.lookAt(spot + Vector3.new(0, 9, 0), spot + Vector3.new(0, 9, 60)) * CFrame.Angles(0, math.pi, 0), 1.2)
		state.slots[slot] = nil
		local loot: Model? = nil
		if victim then
			loot = victim:Clone()
			victim:Destroy()
			Base.refreshPedestals(target)
			loot.Parent = gull
			loot:PivotTo(gull:GetPivot() * CFrame.new(0, -7, 0))
		end
		PlayerState.publish(target)
		remotes.Notify:FireAllClients("The Crumb Bandit stole " .. target.DisplayName .. "'s " .. Catalog.ById[owned.id].name .. "! Lock your base!", Color3.fromRGB(255, 80, 80))
	end
	flyTo(gull, CFrame.new(plot.center + Vector3.new(rng:NextNumber(-200, 200), 90, 420)), 5)
	gull:Destroy()
end

function Raid.start(deps)
	world = deps.world
	remotes = deps.remotes
	task.spawn(function()
		while true do
			ReplicatedStorage:SetAttribute("RaidAt", workspace:GetServerTimeNow() + Catalog.Tuning.RaidInterval)
			task.wait(Catalog.Tuning.RaidInterval)
			local target = chooseTarget()
			if target then
				ReplicatedStorage:SetAttribute("RaidTarget", target.DisplayName)
				remotes.Fx:FireAllClients("raid", target.DisplayName)
				Raid.launchGullRaid(target)
			end
		end
	end)
end

return Raid
