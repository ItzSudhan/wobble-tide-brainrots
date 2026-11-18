--!strict
-- WaveHazard: every WaveInterval seconds a tidal wave rolls in from the sea and sweeps the whole island.
-- Anyone it catches outside a safe zone is wiped out and loses the brainrot on their head; it also
-- washes the runway clean. The countdown is published on ReplicatedStorage for the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local Market = require(script.Parent.BrainrotMarket)

local Wave = {}

local WAVE_SECONDS = 11
local WAVE_DEPTH = 26

local world: any
local remotes: any
Wave.count = 0

local function wavePart(model: Model, props: { [string]: any }, wedge: boolean?): BasePart
	local p: BasePart = wedge and Instance.new("WedgePart") or Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = model
	return p
end

-- A curling wall of water with a foam crest and spray, built facing -Z (towards the bases).
local function buildWaveModel(): Model
	local model = Instance.new("Model")
	model.Name = "TidalWave"
	local body = wavePart(model, { Name = "WaveBody", Size = Vector3.new(470, 22, WAVE_DEPTH), CFrame = CFrame.new(0, 9, 0), Color = Color3.fromRGB(30, 140, 210), Transparency = 0.2 })
	wavePart(model, { Name = "WaveFace", Size = Vector3.new(470, 24, 16), CFrame = CFrame.new(0, 10, -WAVE_DEPTH / 2 - 8) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromRGB(50, 170, 230), Transparency = 0.25 }, true)
	local crest = wavePart(model, { Name = "Crest", Size = Vector3.new(470, 4, WAVE_DEPTH + 12), CFrame = CFrame.new(0, 21.5, -6), Color = Color3.fromRGB(235, 250, 255), Material = Enum.Material.Neon, Transparency = 0.1 })
	wavePart(model, { Name = "Lip", Size = Vector3.new(470, 3, 8), CFrame = CFrame.new(0, 19, -WAVE_DEPTH / 2 - 12), Color = Color3.fromRGB(220, 245, 255), Transparency = 0.15 })
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.new(1, 1, 1))
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
	if lost then
		remotes.Notify:FireClient(player, "WIPED OUT! The tide stole your " .. lost .. "!", Color3.fromRGB(255, 80, 80))
	else
		remotes.Notify:FireClient(player, "WIPED OUT! Hide in a SAFE ZONE next time.", Color3.fromRGB(255, 120, 80))
	end
end

-- Roll the wave across the island, checking who it hits as its front passes them.
function Wave.runWave()
	Wave.count += 1
	ReplicatedStorage:SetAttribute("WaveActive", true)
	remotes.Fx:FireAllClients("wave")
	local model = buildWaveModel()
	model.Parent = workspace
	local hit: { [Player]: boolean } = {}
	local washed = false
	local start = os.clock()
	local done = false
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local alpha = math.min((os.clock() - start) / WAVE_SECONDS, 1)
		local z = world.WaveStartZ + (world.WaveEndZ - world.WaveStartZ) * alpha
		local rise = math.sin(alpha * math.pi) * 3
		model:PivotTo(CFrame.new(0, -4 + rise, z))
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
			conn:Disconnect()
			done = true
		end
	end)
	while not done do
		task.wait()
	end
	model:Destroy()
	ReplicatedStorage:SetAttribute("WaveActive", false)
end

function Wave.start(deps)
	world = deps.world
	remotes = deps.remotes
	task.spawn(function()
		while true do
			local waveAt = workspace:GetServerTimeNow() + Catalog.Tuning.WaveInterval
			ReplicatedStorage:SetAttribute("WaveAt", waveAt)
			task.wait(Catalog.Tuning.WaveInterval - Catalog.Tuning.WaveWarning)
			remotes.Fx:FireAllClients("waveWarning")
			task.wait(Catalog.Tuning.WaveWarning)
			Wave.runWave()
		end
	end)
end

return Wave
