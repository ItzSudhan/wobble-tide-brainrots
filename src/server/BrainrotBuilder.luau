--!strict
-- BrainrotBuilder: assembles a brainrot Model out of plain parts (body, googly face, extras),
-- applies its mutation finish and hangs a floating name / rarity / income label over it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

local Builder = {}

local DARK = Color3.fromRGB(35, 35, 40)
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- Roblox cylinders lie along X; this stands them up

type Ctx = { model: Model, root: BasePart, hx: number, hy: number, hz: number, legH: number, accent: Color3 }

local function addPart(ctx: Ctx, shape: Enum.PartType | string, size: Vector3, color: Color3, cf: CFrame, props: { [string]: any }?): BasePart
	local part: BasePart
	if shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		p.Shape = shape :: Enum.PartType
		part = p
	end
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.Anchored = false
	part.Massless = true
	part.CFrame = ctx.root.CFrame * cf
	if props then
		for k, v in props do
			(part :: any)[k] = v
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ctx.root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = ctx.model
	return part
end

local function bodyCenter(ctx: Ctx): number
	return ctx.legH + ctx.hy
end

local function top(ctx: Ctx): number
	return ctx.legH + ctx.hy * 2
end

-- Two googly eyes and a goofy mouth on the front (-Z) face.
local function addGooglyFace(ctx: Ctx)
	local y = bodyCenter(ctx) + ctx.hy * 0.3
	local z = -ctx.hz - 0.05
	local eye = math.clamp(math.min(ctx.hx, ctx.hy) * 0.55, 0.45, 1.1)
	for _, side in { -1, 1 } do
		local x = side * math.max(ctx.hx * 0.42, eye * 0.6)
		addPart(ctx, Enum.PartType.Ball, Vector3.one * eye, Color3.new(1, 1, 1), CFrame.new(x, y, z), { Name = "Eye" }):SetAttribute("Face", true)
		local wobble = side == 1 and 0.12 or -0.08
		addPart(ctx, Enum.PartType.Ball, Vector3.one * eye * 0.5, DARK, CFrame.new(x + wobble * eye, y - 0.1 * eye, z - eye * 0.35), { Name = "Pupil" }):SetAttribute("Face", true)
	end
	local mouthW = math.max(ctx.hx * 0.9, 0.6)
	addPart(ctx, Enum.PartType.Block, Vector3.new(mouthW, 0.22, 0.2), Color3.fromRGB(120, 30, 40), CFrame.new(0, bodyCenter(ctx) - ctx.hy * 0.35, z) * CFrame.Angles(0, 0, math.rad(6)), { Name = "Mouth" }):SetAttribute("Face", true)
end

local function addLegs(ctx: Ctx, count: number)
	local positions = {}
	if count == 2 then
		positions = { Vector3.new(-ctx.hx * 0.5, 0, 0), Vector3.new(ctx.hx * 0.5, 0, 0) }
	elseif count == 4 then
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				table.insert(positions, Vector3.new(sx * ctx.hx * 0.7, 0, sz * ctx.hz * 0.6))
			end
		end
	else
		for i = 0, count - 1 do
			local a = (i / count) * math.pi * 2
			table.insert(positions, Vector3.new(math.cos(a) * ctx.hx * 0.8, 0, math.sin(a) * ctx.hz * 1.6))
		end
	end
	for _, p in positions do
		addPart(ctx, Enum.PartType.Cylinder, Vector3.new(ctx.legH, 0.4, 0.4), count >= 8 and ctx.accent or DARK, CFrame.new(p.X, ctx.legH / 2, p.Z) * UPRIGHT)
		addPart(ctx, Enum.PartType.Block, Vector3.new(0.6, 0.3, 0.9), DARK, CFrame.new(p.X, 0.15, p.Z - 0.2))
	end
end

-- One small function per silly accessory, keyed by the catalog's extras names.
local Extras: { [string]: (Ctx) -> () } = {}

Extras.legs2 = function(ctx) addLegs(ctx, 2) end
Extras.legs4 = function(ctx) addLegs(ctx, 4) end
Extras.legs8 = function(ctx) addLegs(ctx, 8) end

Extras.toast = function(ctx)
	for _, x in { -0.55, 0.55 } do
		addPart(ctx, Enum.PartType.Block, Vector3.new(0.35, 1.6, 1.7), ctx.accent, CFrame.new(x, top(ctx) + 0.4, 0))
	end
end

Extras.stripes = function(ctx)
	for _, f in { 0.45, 0.75 } do
		addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.35, ctx.hx * 2 + 0.1, ctx.hz * 2 + 0.1), ctx.accent, CFrame.new(0, ctx.legH + ctx.hy * 2 * f, 0) * UPRIGHT)
	end
end

Extras.fishtail = function(ctx)
	addPart(ctx, "Wedge", Vector3.new(0.3, ctx.hy * 2, 1.6), ctx.accent, CFrame.new(ctx.hx + 0.7, bodyCenter(ctx), 0) * CFrame.Angles(0, math.rad(90), 0))
end

Extras.fin = function(ctx)
	addPart(ctx, "Wedge", Vector3.new(0.25, 1, 1.6), ctx.accent, CFrame.new(0, top(ctx) + 0.5, 0) * CFrame.Angles(0, math.rad(90), 0))
end

Extras.tophat = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.2, 2.2, 2.2), ctx.accent, CFrame.new(0, top(ctx) + 0.1, 0) * UPRIGHT)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(1.6, 1.4, 1.4), ctx.accent, CFrame.new(0, top(ctx) + 0.9, 0) * UPRIGHT)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.3, 1.45, 1.45), Color3.fromRGB(200, 40, 50), CFrame.new(0, top(ctx) + 0.4, 0) * UPRIGHT)
end

Extras.arms = function(ctx)
	for _, side in { -1, 1 } do
		addPart(ctx, Enum.PartType.Cylinder, Vector3.new(1.8, 0.35, 0.35), ctx.model:GetAttribute("BodyColor") :: Color3? or DARK,
			CFrame.new(side * (ctx.hx + 0.6), bodyCenter(ctx) + 0.4, 0) * CFrame.Angles(0, 0, side * math.rad(35)))
	end
end

Extras.mophead = function(ctx)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		addPart(ctx, Enum.PartType.Cylinder, Vector3.new(1.8, 0.3, 0.3), ctx.accent,
			CFrame.new(math.cos(a) * 0.6, top(ctx) + 0.6, math.sin(a) * 0.6) * CFrame.Angles(0, -a, math.rad(60)))
	end
	addPart(ctx, Enum.PartType.Ball, Vector3.one * 1.4, ctx.accent, CFrame.new(0, top(ctx) + 0.6, 0))
end

Extras.crown = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.6, 1.8, 1.8), ctx.accent, CFrame.new(0, top(ctx) + 0.3, 0) * UPRIGHT, { Material = Enum.Material.Neon })
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		addPart(ctx, Enum.PartType.Block, Vector3.new(0.3, 0.7, 0.3), ctx.accent, CFrame.new(math.cos(a) * 0.75, top(ctx) + 0.9, math.sin(a) * 0.75))
	end
end

Extras.jelly = function(ctx)
	local body = ctx.model:FindFirstChild("Body") :: BasePart
	body.Transparency = 0.3
	body.Material = Enum.Material.Glass
	addPart(ctx, Enum.PartType.Ball, Vector3.one * ctx.hy, ctx.accent, CFrame.new(0, bodyCenter(ctx), 0), { Material = Enum.Material.Neon })
end

Extras.spikes = function(ctx)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local y = ctx.legH + ctx.hy * 2 * ((i % 3) + 1) / 4
		addPart(ctx, Enum.PartType.Block, Vector3.new(0.15, 0.15, 0.7), Color3.fromRGB(250, 240, 180),
			CFrame.new(math.cos(a) * ctx.hx, y, math.sin(a) * ctx.hz) * CFrame.Angles(0, -a + math.pi / 2, 0))
	end
	addPart(ctx, Enum.PartType.Ball, Vector3.one * 0.9, Color3.fromRGB(255, 90, 160), CFrame.new(0, top(ctx) + 0.3, 0))
end

Extras.mic = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(1.2, 0.4, 0.4), DARK, CFrame.new(ctx.hx + 1.3, bodyCenter(ctx) + 1.3, -0.4) * UPRIGHT)
	addPart(ctx, Enum.PartType.Ball, Vector3.one * 0.7, Color3.fromRGB(190, 190, 200), CFrame.new(ctx.hx + 1.3, bodyCenter(ctx) + 2.0, -0.4), { Material = Enum.Material.Metal })
end

Extras.dinotail = function(ctx)
	for i = 1, 3 do
		local s = 1.4 - i * 0.3
		addPart(ctx, Enum.PartType.Block, Vector3.new(s, s, 1.4), ctx.accent, CFrame.new(0, ctx.legH + 1 - i * 0.25, ctx.hz + i * 1.1))
	end
	for i = 0, 3 do
		addPart(ctx, "Wedge", Vector3.new(0.2, 0.6, 0.6), ctx.accent, CFrame.new(0, top(ctx) - i * 0.9 + 0.2, ctx.hz + 0.2) * CFrame.Angles(math.rad(-90), 0, 0))
	end
end

Extras.handle = function(ctx)
	addPart(ctx, Enum.PartType.Block, Vector3.new(0.2, ctx.hy * 1.2, 0.3), Color3.fromRGB(150, 150, 160), CFrame.new(ctx.hx * 0.7, bodyCenter(ctx) - ctx.hy * 0.2, -ctx.hz - 0.25), { Material = Enum.Material.Metal })
	addPart(ctx, Enum.PartType.Block, Vector3.new(ctx.hx * 2 + 0.05, 0.12, ctx.hz * 2 + 0.05), DARK, CFrame.new(0, ctx.legH + ctx.hy * 1.25, 0))
end

Extras.spout = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(1.8, 0.5, 0.5), ctx.model:GetAttribute("BodyColor") :: Color3? or DARK,
		CFrame.new(ctx.hx + 0.5, bodyCenter(ctx) + 0.4, 0) * CFrame.Angles(0, 0, math.rad(35)))
	addPart(ctx, Enum.PartType.Ball, Vector3.one * 0.6, DARK, CFrame.new(0, top(ctx) + 0.1, 0))
end

Extras.drumsticks = function(ctx)
	for _, side in { -1, 1 } do
		addPart(ctx, Enum.PartType.Cylinder, Vector3.new(2.6, 0.18, 0.18), ctx.accent,
			CFrame.new(side * (ctx.hx + 0.3), top(ctx) + 0.3, -0.3) * CFrame.Angles(0, 0, side * math.rad(-60)))
		addPart(ctx, Enum.PartType.Ball, Vector3.one * 0.45, ctx.accent, CFrame.new(side * (ctx.hx + 0.95), top(ctx) + 1.4, -0.3))
	end
end

Extras.beret = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.35, 1.9, 1.9), Color3.fromRGB(30, 30, 60), CFrame.new(0.2, top(ctx) + 0.1, 0) * CFrame.Angles(0, 0, math.rad(80)))
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.4, 0.15, 0.15), Color3.fromRGB(30, 30, 60), CFrame.new(0.3, top(ctx) + 0.45, 0) * UPRIGHT)
end

Extras.sprinkles = function(ctx)
	local colors = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 200, 255), Color3.fromRGB(255, 240, 80), Color3.fromRGB(120, 255, 120) }
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.3, ctx.hy * 2 - 0.2, ctx.hy * 2 - 0.2), ctx.accent, CFrame.new(0, bodyCenter(ctx), -ctx.hz - 0.05) * CFrame.Angles(0, math.rad(90), 0))
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.5, ctx.hy * 0.7, ctx.hy * 0.7), DARK, CFrame.new(0, bodyCenter(ctx), -ctx.hz - 0.1) * CFrame.Angles(0, math.rad(90), 0))
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local r = ctx.hy * 0.68
		addPart(ctx, Enum.PartType.Block, Vector3.new(0.45, 0.14, 0.14), colors[i % 4 + 1], CFrame.new(math.cos(a) * r, bodyCenter(ctx) + math.sin(a) * r, -ctx.hz - 0.25) * CFrame.Angles(0, 0, a * 2))
	end
end

Extras.antenna = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(1.5, 0.15, 0.15), DARK, CFrame.new(0, top(ctx) + 0.75, 0) * UPRIGHT)
	addPart(ctx, Enum.PartType.Ball, Vector3.one * 0.6, Color3.fromRGB(255, 60, 60), CFrame.new(0, top(ctx) + 1.6, 0), { Material = Enum.Material.Neon })
end

Extras.lampshade = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(2, 3.6, 3.6), ctx.accent, CFrame.new(0, top(ctx) + 0.9, 0) * UPRIGHT, { Material = Enum.Material.Neon, Transparency = 0.1 })
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.3, 2.4, 2.4), DARK, CFrame.new(0, ctx.legH + 0.15, 0) * UPRIGHT)
end

Extras.glow = function(ctx)
	local light = Instance.new("PointLight")
	light.Color = ctx.accent
	light.Range = 14
	light.Brightness = 2
	light.Parent = ctx.model:FindFirstChild("Body")
end

Extras.cape = function(ctx)
	addPart(ctx, Enum.PartType.Block, Vector3.new(ctx.hx * 2 + 0.6, ctx.hy * 2 + 0.6, 0.15), ctx.accent, CFrame.new(0, bodyCenter(ctx) - 0.2, ctx.hz + 0.35) * CFrame.Angles(math.rad(-10), 0, 0))
end

Extras.handlestick = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(ctx.legH, 0.5, 0.5), Color3.fromRGB(40, 30, 30), CFrame.new(0, ctx.legH / 2, 0) * UPRIGHT)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.3, 1.6, 1.6), DARK, CFrame.new(0, 0.15, 0) * UPRIGHT)
	for i = -1, 1 do
		addPart(ctx, Enum.PartType.Block, Vector3.new(0.25, ctx.hy * 0.9, 0.3), DARK, CFrame.new(i * ctx.hx * 0.5, top(ctx) - ctx.hy * 0.55, -ctx.hz))
	end
end

Extras.halo = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.2, 2.6, 2.6), Color3.fromRGB(255, 240, 120), CFrame.new(0, top(ctx) + 1.6, 0) * UPRIGHT, { Material = Enum.Material.Neon, Transparency = 0.2 })
end

Extras.garagedoor = function(ctx)
	addPart(ctx, Enum.PartType.Block, Vector3.new(ctx.hx * 1.6, ctx.hy * 1.1, 0.2), Color3.fromRGB(220, 220, 225), CFrame.new(0, ctx.legH + ctx.hy * 0.55, -ctx.hz - 0.1))
	for i = 1, 3 do
		addPart(ctx, Enum.PartType.Block, Vector3.new(ctx.hx * 1.6, 0.08, 0.3), DARK, CFrame.new(0, ctx.legH + ctx.hy * 0.27 * i, -ctx.hz - 0.15))
	end
	addPart(ctx, "Wedge", Vector3.new(ctx.hx * 2 + 0.4, 1.2, ctx.hz + 0.2), Color3.fromRGB(170, 60, 50), CFrame.new(0, top(ctx) + 0.6, -ctx.hz / 2 - 0.1))
	addPart(ctx, "Wedge", Vector3.new(ctx.hx * 2 + 0.4, 1.2, ctx.hz + 0.2), Color3.fromRGB(170, 60, 50), CFrame.new(0, top(ctx) + 0.6, ctx.hz / 2 + 0.1) * CFrame.Angles(0, math.pi, 0))
end

Extras.duckhead = function(ctx)
	addPart(ctx, Enum.PartType.Ball, Vector3.one * 2.4, ctx.accent, CFrame.new(0, top(ctx) + 2.2, -0.6))
	addPart(ctx, Enum.PartType.Block, Vector3.new(1.2, 0.4, 1.2), Color3.fromRGB(255, 140, 30), CFrame.new(0, top(ctx) + 2.0, -2.2))
	for _, side in { -1, 1 } do
		addPart(ctx, Enum.PartType.Ball, Vector3.one * 0.5, DARK, CFrame.new(side * 0.55, top(ctx) + 2.6, -1.7))
	end
end

Extras.lightning = function(ctx)
	for _, side in { -1, 1 } do
		for i = 0, 2 do
			addPart(ctx, Enum.PartType.Block, Vector3.new(0.2, 1.1, 0.3), ctx.accent,
				CFrame.new(side * (ctx.hx + 0.1), ctx.legH + 1 + i * 1, (i % 2 == 0) and -0.3 or 0.3) * CFrame.Angles((i % 2 == 0) and 0.6 or -0.6, 0, 0), { Material = Enum.Material.Neon })
		end
	end
end

Extras.glasses = function(ctx)
	local y = bodyCenter(ctx) + ctx.hy * 0.3
	addPart(ctx, Enum.PartType.Block, Vector3.new(ctx.hx * 2.1, 0.15, 0.15), DARK, CFrame.new(0, y + 0.25, -ctx.hz - 0.7))
	for _, side in { -1, 1 } do
		addPart(ctx, Enum.PartType.Block, Vector3.new(0.9, 0.9, 0.08), Color3.fromRGB(120, 220, 255), CFrame.new(side * ctx.hx * 0.45, y, -ctx.hz - 0.75), { Transparency = 0.5 })
	end
end

Extras.rings = function(ctx)
	addPart(ctx, Enum.PartType.Cylinder, Vector3.new(0.15, ctx.hx * 3.2, ctx.hx * 3.2), ctx.accent, CFrame.new(0, bodyCenter(ctx), 0) * CFrame.Angles(math.rad(15), 0, math.rad(90)), { Transparency = 0.25, Material = Enum.Material.Neon })
end

local function legHeightFor(extras: { string }): number
	for _, e in extras do
		if e == "handlestick" then
			return 2.6
		elseif string.sub(e, 1, 4) == "legs" then
			return 1.4
		end
	end
	return 0.1
end

-- Gold turns the body shiny gold; Rainbow paints every part a different hue and adds sparkles.
local function applyMutationFinish(model: Model, mutation: string)
	if mutation == "Normal" then
		return
	end
	local i = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "Root" and not part:GetAttribute("Face") then
			i += 1
			if mutation == "Gold" then
				part.Color = Color3.fromRGB(255, 196, 40):Lerp(part.Color, 0.15)
				part.Material = Enum.Material.Metal
				part.Reflectance = 0.25
			else
				part.Color = Color3.fromHSV((i * 0.13) % 1, 0.75, 1)
			end
		end
	end
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Catalog.mutationByName(mutation).color
	sparkles.Parent = model:FindFirstChild("Body")
end

local function makeLine(parent: Instance, text: string, color: Color3, order: number, height: number, font: Enum.Font): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, height, 0)
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = true
	label.Font = font
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

-- Floating BillboardGui: name, rarity (+mutation), income per second, and a price line while for sale.
function Builder.attachLabel(model: Model, id: string, mutation: string, priceText: string?)
	local entry = Catalog.ById[id]
	local rarity = Catalog.rarityOf(entry)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	-- sized in studs so neighbouring labels never overlap, however far the camera is
	gui.Size = UDim2.fromScale(15, priceText and 7.4 or 5.8)
	gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y + 3.2, 0)
	gui.MaxDistance = 170
	gui.LightInfluence = 0
	gui.Adornee = model.PrimaryPart
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = gui
	local n = priceText and 4 or 3
	makeLine(gui, entry.name, Color3.new(1, 1, 1), 1, 1.15 / n, Enum.Font.FredokaOne)
	local tag = mutation == "Normal" and rarity.name or (mutation .. " " .. rarity.name)
	makeLine(gui, tag, mutation == "Normal" and rarity.color or Catalog.mutationByName(mutation).color, 2, 0.9 / n, Enum.Font.GothamBold)
	makeLine(gui, Catalog.formatMoney(Catalog.incomeOf(id, mutation)) .. "/s", Color3.fromRGB(110, 255, 120), 3, 1 / n, Enum.Font.GothamBlack)
	if priceText then
		makeLine(gui, priceText, Color3.fromRGB(255, 225, 70), 4, 1 / n, Enum.Font.GothamBlack)
	end
	gui.Parent = model
	return gui
end

-- Build a brainrot facing -Z with its feet at the model pivot. Anchored at the root until carried.
function Builder.buildBrainrot(id: string, mutation: string): Model
	local entry = Catalog.ById[id]
	local model = Instance.new("Model")
	model.Name = entry.name
	model:SetAttribute("BrainrotId", id)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("BodyColor", entry.body.color)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 0.2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.Anchored = true
	root.CFrame = CFrame.new(0, 500, 0)
	root.Parent = model
	model.PrimaryPart = root

	local size = entry.body.size
	local hx, hy, hz
	local shape = entry.body.shape
	local orient = CFrame.identity
	local partShape = Enum.PartType.Block
	if shape == "Ball" then
		hx, hy, hz = size.X / 2, size.X / 2, size.X / 2
		partShape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		hx, hy, hz = size.Y / 2, size.X / 2, size.Z / 2
		orient = UPRIGHT
		partShape = Enum.PartType.Cylinder
	elseif shape == "Donut" then
		hx, hy, hz = size.Y / 2, size.Z / 2, size.X / 2
		orient = CFrame.Angles(0, math.rad(90), 0)
		partShape = Enum.PartType.Cylinder
	else
		hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	end
	local ctx: Ctx = { model = model, root = root, hx = hx, hy = hy, hz = hz, legH = legHeightFor(entry.extras), accent = entry.accent }
	local body = addPart(ctx, partShape, size, entry.body.color, CFrame.new(0, ctx.legH + hy, 0) * orient, { Name = "Body" })
	body.Name = "Body"

	for _, extra in entry.extras do
		local fn = Extras[extra]
		if fn then
			fn(ctx)
		end
	end
	if shape ~= "Donut" then
		addGooglyFace(ctx)
	else
		-- the donut's face sits above its hole
		ctx.hy *= 0.55
		ctx.legH += size.Z * 0.42
		addGooglyFace(ctx)
	end
	applyMutationFinish(model, mutation)
	model:ScaleTo(Catalog.rarityOf(entry).scale * 1.5)
	return model
end

-- Anchor or free every part (carried brainrots ride unanchored on a weld to the player's head).
function Builder.setAnchored(model: Model, anchored: boolean)
	local root = model.PrimaryPart :: BasePart
	root.Anchored = anchored
end

return Builder
