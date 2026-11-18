--!strict
-- ThreatDirector: the island's two timed threats, with countdowns published on ReplicatedStorage.
--  * Tidal wave: every WaveInterval seconds a wave sweeps the island; anyone caught outside a safe
--    zone is wiped out and loses the brainrot on their head, and the runway is washed clean.
--  * The Crumb Bandit: every RaidInterval seconds a masked gull raids a base; a locked base bounces
--    it off, an unlocked one loses a random brainrot, carried off to sea.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local PlayerState = require(script.Parent.PlayerState)
local Market = require(script.Parent.BrainrotMarket)
local Base = require(script.Parent.BaseService)

local Threats = {}

local WAVE_SECONDS = 11
local WAVE_DEPTH = 26
local world: any
local remotes: any
local rng = Random.new()

local function anchoredPart(model: Model, shape: Enum.PartType | string, size: Vector3, color: Color3, cf: CFrame, props: { [string]: any }?): BasePart
	local p: BasePart
	if shape == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		part.Shape = shape :: Enum.PartType
		p = part
	end
	p.Size, p.Color, p.CFrame = size, color, cf
	p.Anchored, p.CanCollide, p.CanQuery = true, false, false
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props or {} do
		(p :: any)[k] = v
	end
	p.Parent = model
	return p
end

local function tweenModel(model: Model, goal: CFrame, seconds: number)
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

-- A curling wall of water with a foam crest and spray, facing -Z (towards the bases).
local function buildWaveModel(): Model
	local model = Instance.new("Model")
	model.Name = "TidalWave"
	local block = Enum.PartType.Block
	local body = anchoredPart(model, block, Vector3.new(470, 34, WAVE_DEPTH), Color3.fromRGB(30, 140, 210), CFrame.new(0, 15, 0), { Transparency = 0.15, CastShadow = false })
	anchoredPart(model, "Wedge", Vector3.new(470, 36, 16), Color3.fromRGB(50, 170, 230), CFrame.new(0, 16, -WAVE_DEPTH / 2 - 8) * CFrame.Angles(0, math.pi, 0), { Transparency = 0.2 })
	local crest = anchoredPart(model, block, Vector3.new(470, 5, WAVE_DEPTH + 14), Color3.fromRGB(235, 250, 255), CFrame.new(0, 33.5, -7), { Material = Enum.Material.Neon, Transparency = 0.05 })
	anchoredPart(model, block, Vector3.new(470, 4, 9), Color3.fromRGB(220, 245, 255), CFrame.new(0, 30, -WAVE_DEPTH / 2 - 13), { Transparency = 0.1 })
	local spray = Instance.new("ParticleEmitter")
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0) })
	spray.Transparency = NumberSequence.new(0.2, 1)
	spray.Lifetime = NumberRange.new(0.6, 1.2)
	spray.Rate = 300
	spray.Speed = NumberRange.new(10, 25)
	spray.SpreadAngle = Vector2.new(60, 60)
	spray.Parent = crest
	model.PrimaryPart = body
	return model
end

local function wipeOut(player: Player)
	local lost = Market.loseCarried(player)
	remotes.Fx:FireClient(player, "wipeout")
	local msg = lost and ("WIPED OUT! The tide stole your " .. lost .. "!") or "WIPED OUT! Hide in a SAFE ZONE next time."
	remotes.Notify:FireClient(player, msg, Color3.fromRGB(255, 90, 80))
end

-- Roll the wave across the island, checking who it hits as its front passes them.
function Threats.runTidalWave()
	ReplicatedStorage:SetAttribute("WaveActive", true)
	remotes.Fx:FireAllClients("wave")
	local model = buildWaveModel()
	model.Parent = workspace
	local hit: { [Player]: boolean } = {}
	local washed = false
	local start = os.clock()
	while true do
		local alpha = math.min((os.clock() - start) / WAVE_SECONDS, 1)
		local z = world.WaveStartZ + (world.WaveEndZ - world.WaveStartZ) * alpha
		model:PivotTo(CFrame.new(0, -4 + math.sin(alpha * math.pi) * 3, z))
		local front = z - WAVE_DEPTH / 2 - 16
		if not washed and front <= world.RunwayZ then
			washed = true
			Market.washRunway()
		end
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and not hit[player] and root.Position.Z >= front and root.Position.Z <= z + WAVE_DEPTH / 2 then
				hit[player] = true
				if not world.isSafe(root.Position) then
					wipeOut(player)
				end
			end
		end
		if alpha >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	model:Destroy()
	ReplicatedStorage:SetAttribute("WaveActive", false)
end

-- The Crumb Bandit: round white body, grey wings, orange beak, black bandit mask, red name tag.
local function buildCrumbBandit(): Model
	local model = Instance.new("Model")
	model.Name = "CrumbBandit"
	local ball, block = Enum.PartType.Ball, Enum.PartType.Block
	local white, grey = Color3.fromRGB(250, 250, 250), Color3.fromRGB(150, 155, 165)
	local body = anchoredPart(model, ball, Vector3.one * 5, white, CFrame.new())
	model.PrimaryPart = body
	anchoredPart(model, ball, Vector3.one * 3.4, white, CFrame.new(0, 1.8, -2.6))
	anchoredPart(model, block, Vector3.new(3.5, 0.9, 0.4), Color3.fromRGB(20, 20, 25), CFrame.new(0, 2.2, -4.2))
	for _, side in { -1, 1 } do
		anchoredPart(model, ball, Vector3.one * 0.7, white, CFrame.new(side * 0.8, 2.2, -4.45))
		anchoredPart(model, block, Vector3.new(9, 0.4, 3.5), grey, CFrame.new(side * 6.5, 0.8, 0) * CFrame.Angles(0, 0, side * math.rad(15)))
	end
	anchoredPart(model, block, Vector3.new(1, 0.7, 2.4), Color3.fromRGB(255, 150, 30), CFrame.new(0, 1.4, -5.2))
	anchoredPart(model, block, Vector3.new(3, 0.4, 2.5), grey, CFrame.new(0, 0.4, 3.2))
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

local function chooseRaidTarget(): Player?
	local candidates = {}
	for player, state in PlayerState.all() do
		if world.Plots[state.plot] and next(state.slots) ~= nil then
			table.insert(candidates, player)
		end
	end
	return #candidates > 0 and candidates[rng:NextInteger(1, #candidates)] or nil
end

-- Fly in over the target base; steal unless the base is locked or nearly empty.
function Threats.launchGullRaid(target: Player)
	local state = PlayerState.get(target)
	local plot = state and world.Plots[state.plot]
	if not state or not plot then
		return
	end
	local function facingSea(pos: Vector3): CFrame
		return CFrame.lookAt(pos, pos - Vector3.new(0, 0, 60))
	end
	local gull = buildCrumbBandit()
	gull:PivotTo(CFrame.new(plot.center + Vector3.new(0, 70, 320)))
	gull.Parent = workspace
	tweenModel(gull, facingSea(plot.center + Vector3.new(0, 26, 0)), 4)

	local slots = {}
	for slot in state.slots do
		table.insert(slots, slot)
	end
	local name = target.DisplayName
	if Base.isShielded(target) then
		remotes.Fx:FireAllClients("bonk", plot.center + Vector3.new(0, 26, 0))
		remotes.Notify:FireAllClients("BONK! " .. name .. "'s shield sent the Crumb Bandit packing!", Color3.fromRGB(110, 210, 255))
	elseif #slots <= 1 then
		remotes.Notify:FireAllClients("The Crumb Bandit sniffs " .. name .. "'s base... too poor to rob.", Color3.fromRGB(255, 220, 120))
	else
		local slot = slots[rng:NextInteger(1, #slots)]
		local owned = state.slots[slot] :: any
		local victim = Base.pedestalModel(target, slot)
		tweenModel(gull, facingSea(plot.pedestals[slot].Position + Vector3.new(0, 9, 0)), 1.2)
		state.slots[slot] = nil
		if victim then
			local loot = victim:Clone()
			victim:Destroy()
			loot.Parent = gull
			loot:PivotTo(gull:GetPivot() * CFrame.new(0, -7, 0))
		end
		Base.refreshPedestals(target)
		PlayerState.publish(target)
		remotes.Notify:FireAllClients("The Crumb Bandit stole " .. name .. "'s " .. Catalog.ById[owned.id].name .. "! Lock your base!", Color3.fromRGB(255, 80, 80))
	end
	tweenModel(gull, CFrame.new(plot.center + Vector3.new(rng:NextNumber(-200, 200), 90, 420)), 5)
	gull:Destroy()
end

function Threats.start(deps)
	world = deps.world
	remotes = deps.remotes
	local T = Catalog.Tuning
	task.spawn(function()
		while true do
			ReplicatedStorage:SetAttribute("WaveAt", workspace:GetServerTimeNow() + T.WaveInterval)
			task.wait(T.WaveInterval - T.WaveWarning)
			remotes.Fx:FireAllClients("waveWarning")
			task.wait(T.WaveWarning)
			Threats.runTidalWave()
		end
	end)
	task.spawn(function()
		while true do
			ReplicatedStorage:SetAttribute("RaidAt", workspace:GetServerTimeNow() + T.RaidInterval)
			task.wait(T.RaidInterval)
			local target = chooseRaidTarget()
			if target then
				remotes.Fx:FireAllClients("raid", target.DisplayName)
				Threats.launchGullRaid(target)
			end
		end
	end)
end

return Threats
