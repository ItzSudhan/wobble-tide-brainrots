--!strict
-- WorldBuilder: builds Wobble Tide island from primitives: terrain ocean, sand island, the Brainrot
-- Runway, four player bases with pedestals, shield domes and lock pads, lifeguard safe zones and decor.

local Lighting = game:GetService("Lighting")

local World = {}

local SAND = Color3.fromRGB(238, 214, 160)
local PLOT_COLORS = {
	Color3.fromRGB(255, 140, 190),
	Color3.fromRGB(100, 210, 220),
	Color3.fromRGB(170, 130, 255),
	Color3.fromRGB(255, 180, 90),
}

World.RunwayZ = 80
World.RunwayStartX = -140
World.RunwayEndX = 140
World.WaveStartZ = 260
World.WaveEndZ = -215
World.Plots = {} :: { any }
World.SafeDiscs = {} :: { { center: Vector3, radius: number } }

local folder: Folder

local function part(props: { [string]: any }): BasePart
	local p: BasePart
	if props.Wedge then
		p = Instance.new("WedgePart")
		props.Wedge = nil
	else
		p = Instance.new("Part")
	end
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	if not p.Parent then
		p.Parent = folder
	end
	return p
end

local function surfaceText(target: BasePart, face: Enum.NormalId, text: string, color: Color3, bg: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = bg or Color3.new(0, 0, 0)
	label.BackgroundTransparency = bg and 0 or 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = target
	return label
end

local function floatingSign(adornee: BasePart, text: string, color: Color3, offsetY: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(14, 3.5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 220
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = adornee
end

local function buildOceanAndIsland()
	local terrain = workspace.Terrain
	terrain:FillBlock(CFrame.new(0, -18, 0), Vector3.new(1100, 6, 1100), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(1100, 14, 1100), Enum.Material.Water)
	terrain.WaterColor = Color3.fromRGB(40, 170, 200)
	terrain.WaterWaveSize = 0.3
	terrain.WaterTransparency = 0.6

	part({ Name = "Island", Size = Vector3.new(400, 12, 380), Position = Vector3.new(0, -6, 0), Color = SAND, Material = Enum.Material.Sand })
	-- rounded shoreline lobes
	for _, pos in { Vector3.new(-200, 0, 0), Vector3.new(200, 0, 0), Vector3.new(0, 0, 190), Vector3.new(0, 0, -190) } do
		part({ Name = "Shore", Shape = Enum.PartType.Cylinder, Size = Vector3.new(11.6, 180, 180), CFrame = CFrame.new(pos + Vector3.new(0, -5.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = SAND, Material = Enum.Material.Sand })
	end
	part({ Name = "WetSand", Size = Vector3.new(400, 0.2, 40), Position = Vector3.new(0, 0.05, 170), Color = Color3.fromRGB(205, 180, 130), Material = Enum.Material.Sand })
	part({ Name = "Lawn", Size = Vector3.new(400, 0.3, 120), Position = Vector3.new(0, 0.1, -125), Color = Color3.fromRGB(110, 190, 90), Material = Enum.Material.Grass })
end

local function buildRunway()
	local length = World.RunwayEndX - World.RunwayStartX + 20
	part({ Name = "Runway", Size = Vector3.new(length, 0.6, 16), Position = Vector3.new(0, 0.3, World.RunwayZ), Color = Color3.fromRGB(45, 45, 55) })
	for _, dz in { -8.5, 8.5 } do
		part({ Name = "RunwayEdge", Size = Vector3.new(length, 0.8, 1), Position = Vector3.new(0, 0.4, World.RunwayZ + dz), Color = Color3.fromRGB(255, 210, 40), Material = Enum.Material.Neon })
	end
	for x = World.RunwayStartX, World.RunwayEndX, 20 do
		part({ Name = "Chevron", Wedge = true, Size = Vector3.new(4, 0.2, 3), CFrame = CFrame.new(x, 0.65, World.RunwayZ) * CFrame.Angles(0, math.rad(-90), 0), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon, Transparency = 0.4 })
	end
	-- the arch the brainrots march out of
	local ax = World.RunwayStartX - 4
	for _, dz in { -11, 11 } do
		part({ Name = "ArchPillar", Size = Vector3.new(3, 18, 3), Position = Vector3.new(ax, 9, World.RunwayZ + dz), Color = Color3.fromRGB(255, 90, 160) })
	end
	local beam = part({ Name = "ArchSign", Size = Vector3.new(3, 6, 26), Position = Vector3.new(ax, 19, World.RunwayZ), Color = Color3.fromRGB(40, 30, 70) })
	surfaceText(beam, Enum.NormalId.Right, "BRAINROT RUNWAY", Color3.fromRGB(255, 230, 80))
	surfaceText(beam, Enum.NormalId.Left, "BRAINROT RUNWAY", Color3.fromRGB(255, 230, 80))
	local banner = part({ Name = "RunwayBanner", Size = Vector3.new(60, 6, 1), Position = Vector3.new(0, 10, World.RunwayZ + 14), Color = Color3.fromRGB(40, 30, 70) })
	surfaceText(banner, Enum.NormalId.Front, "BUY A BRAINROT, RUN IT HOME!", Color3.fromRGB(120, 255, 200))
	for _, dx in { -28, 28 } do
		part({ Name = "BannerPole", Size = Vector3.new(1, 13, 1), Position = Vector3.new(dx, 6.5, World.RunwayZ + 14), Color = Color3.fromRGB(230, 230, 230) })
	end
end

local function buildPedestal(plotIndex: number, cf: CFrame, color: Color3): BasePart
	local base = part({ Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 12, 12), CFrame = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(245, 245, 250) })
	part({ Name = "PedestalRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 12.4, 12.4), CFrame = cf * CFrame.new(0, 2.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = Enum.Material.Neon })
	base:SetAttribute("Plot", plotIndex)
	return base
end

local function buildPlot(index: number, x: number)
	local z = -125
	local color = PLOT_COLORS[index]
	local pad = part({ Name = "BasePad" .. index, Size = Vector3.new(76, 1, 60), Position = Vector3.new(x, 0.5, z), Color = color:Lerp(Color3.new(1, 1, 1), 0.45) })
	part({ Name = "SafeStrip", Size = Vector3.new(76, 0.3, 2.5), Position = Vector3.new(x, 1.1, z + 29), Color = Color3.fromRGB(80, 255, 120), Material = Enum.Material.Neon })
	part({ Name = "BackWall", Size = Vector3.new(76, 7, 1.5), Position = Vector3.new(x, 4.5, z - 30), Color = color })
	for _, dx in { -38, 38 } do
		part({ Name = "SideWall", Size = Vector3.new(1.5, 4, 60), Position = Vector3.new(x + dx, 3, z), Color = color })
	end
	local board = part({ Name = "OwnerBoard", Size = Vector3.new(36, 7, 1), Position = Vector3.new(x, 11, z - 30), Color = Color3.fromRGB(30, 25, 50) })
	local ownerLabel = surfaceText(board, Enum.NormalId.Back, "EMPTY BASE", color)
	local pedestals = {}
	for row, dz in { -14, 8 } do
		for col, dx in { -28, -9.5, 9.5, 28 } do
			local cf = CFrame.new(x + dx, 1, z + dz)
			buildPedestal(index, cf, color)
			pedestals[(row - 1) * 4 + col] = CFrame.new(x + dx, 4, z + dz) * CFrame.Angles(0, math.pi, 0)
		end
	end
	local shield = part({ Name = "ShieldDome", Shape = Enum.PartType.Ball, Size = Vector3.new(86, 86, 86), Position = Vector3.new(x, 0, z), Color = Color3.fromRGB(90, 200, 255), Material = Enum.Material.ForceField, Transparency = 1, CanCollide = false, CanQuery = false })
	local lockPad = part({ Name = "LockPad", Size = Vector3.new(6, 1, 6), Position = Vector3.new(x + 30, 1.2, z + 22), Color = Color3.fromRGB(255, 70, 70), Material = Enum.Material.Neon })
	floatingSign(lockPad, "LOCK BASE", Color3.fromRGB(255, 120, 120), 4)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lock Base"
	prompt.ObjectText = "Shield"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.Parent = lockPad
	table.insert(World.Plots, {
		index = index,
		center = Vector3.new(x, 1, z),
		halfSize = Vector3.new(38, 20, 30),
		pad = pad,
		pedestals = pedestals,
		shield = shield,
		lockPrompt = prompt,
		ownerLabel = ownerLabel,
		color = color,
		spawn = CFrame.new(x, 4, z + 20),
	})
end

local function buildLifeguardSafeZone(center: Vector3)
	part({ Name = "SafeDisc", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 26, 26), CFrame = CFrame.new(center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 255, 120), Material = Enum.Material.Neon, Transparency = 0.35 })
	for _, off in { Vector3.new(-3, 0, -3), Vector3.new(3, 0, -3), Vector3.new(-3, 0, 3), Vector3.new(3, 0, 3) } do
		part({ Name = "TowerLeg", Size = Vector3.new(0.8, 10, 0.8), Position = center + off + Vector3.new(0, 5, 0), Color = Color3.fromRGB(255, 255, 255) })
	end
	local seat = part({ Name = "TowerSeat", Size = Vector3.new(8, 1, 8), Position = center + Vector3.new(0, 10.5, 0), Color = Color3.fromRGB(230, 50, 50) })
	part({ Name = "TowerRoof", Wedge = true, Size = Vector3.new(9, 3, 9), Position = center + Vector3.new(0, 15, 0), Color = Color3.fromRGB(255, 255, 255) })
	floatingSign(seat, "SAFE ZONE", Color3.fromRGB(120, 255, 140), 9)
	table.insert(World.SafeDiscs, { center = center, radius = 13 })
end

local function buildPalm(pos: Vector3, height: number)
	for i = 0, 5 do
		part({ Name = "PalmTrunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height / 6 + 0.3, 1.6 - i * 0.12, 1.6 - i * 0.12), CFrame = CFrame.new(pos + Vector3.new(i * 0.35, (i + 0.5) * height / 6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(140, 100, 60) })
	end
	local crown = pos + Vector3.new(2, height, 0)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		part({ Name = "PalmLeaf", Size = Vector3.new(1, 0.3, 9), CFrame = CFrame.new(crown) * CFrame.Angles(0, a, 0) * CFrame.new(0, -1, 4) * CFrame.Angles(math.rad(-20), 0, 0), Color = Color3.fromRGB(60, 160, 70), Material = Enum.Material.Grass })
	end
	part({ Name = "Coconut", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, Position = crown + Vector3.new(0, -1.2, 0.6), Color = Color3.fromRGB(90, 60, 30) })
end

local function buildLighthouse(pos: Vector3)
	for i = 0, 5 do
		part({ Name = "Lighthouse", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 9 - i * 0.6, 9 - i * 0.6), CFrame = CFrame.new(pos + Vector3.new(0, 3 + i * 6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = i % 2 == 0 and Color3.fromRGB(240, 60, 60) or Color3.fromRGB(250, 250, 250) })
	end
	local lamp = part({ Name = "LighthouseLamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 5, Position = pos + Vector3.new(0, 38, 0), Color = Color3.fromRGB(255, 240, 150), Material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 3
	light.Parent = lamp
end

local function buildUmbrella(pos: Vector3, color: Color3)
	part({ Name = "UmbrellaPole", Size = Vector3.new(0.4, 8, 0.4), Position = pos + Vector3.new(0, 4, 0), Color = Color3.fromRGB(250, 250, 250) })
	part({ Name = "Umbrella", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 10, 10), CFrame = CFrame.new(pos + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = color })
	part({ Name = "Towel", Size = Vector3.new(4, 0.15, 7), Position = pos + Vector3.new(3, 0.1, 2), Color = color:Lerp(Color3.new(1, 1, 1), 0.4) })
end

local function setMood()
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Haze = 1
	atmosphere.Color = Color3.fromRGB(200, 230, 255)
	atmosphere.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.25
	cc.Contrast = 0.08
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

-- Is this point protected from the wave? Base pads and lifeguard discs are safe.
function World.isSafe(pos: Vector3): boolean
	for _, plot in World.Plots do
		local d = pos - plot.center
		if math.abs(d.X) <= plot.halfSize.X and math.abs(d.Z) <= plot.halfSize.Z then
			return true
		end
	end
	for _, disc in World.SafeDiscs do
		local flat = Vector3.new(pos.X - disc.center.X, 0, pos.Z - disc.center.Z)
		if flat.Magnitude <= disc.radius then
			return true
		end
	end
	return false
end

function World.plotContaining(pos: Vector3)
	for _, plot in World.Plots do
		local d = pos - plot.center
		if math.abs(d.X) <= plot.halfSize.X and math.abs(d.Z) <= plot.halfSize.Z then
			return plot
		end
	end
	return nil
end

function World.buildIsland()
	folder = Instance.new("Folder")
	folder.Name = "WobbleTideIsland"
	folder.Parent = workspace
	buildOceanAndIsland()
	buildRunway()
	for i, x in { -135, -45, 45, 135 } do
		buildPlot(i, x)
	end
	buildLifeguardSafeZone(Vector3.new(-90, 0, -10))
	buildLifeguardSafeZone(Vector3.new(90, 0, -10))
	for _, p in { Vector3.new(-185, 0, 40), Vector3.new(185, 0, 30), Vector3.new(-170, 0, 130), Vector3.new(175, 0, 140), Vector3.new(-20, 0, 30), Vector3.new(30, 0, -40), Vector3.new(-185, 0, -60), Vector3.new(185, 0, -70) } do
		buildPalm(p, 18 + (p.X % 7))
	end
	buildLighthouse(Vector3.new(-160, 0, 150))
	buildUmbrella(Vector3.new(60, 0, 135), Color3.fromRGB(255, 90, 120))
	buildUmbrella(Vector3.new(-60, 0, 140), Color3.fromRGB(80, 180, 255))
	buildUmbrella(Vector3.new(120, 0, 30), Color3.fromRGB(255, 200, 60))
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.6, -60)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Parent = folder
	setMood()
	return World
end

return World
