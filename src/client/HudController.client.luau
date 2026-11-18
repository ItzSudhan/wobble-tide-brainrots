--!strict
-- HudController: everything the player sees on screen and every client-side effect. Reads only the
-- attributes the server publishes and asks the server (Action remote) to rebirth, lock or upgrade.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(110, 255, 120)
local PANEL = Color3.fromRGB(20, 22, 45)

-- our threat panel lives where Roblox's player list would sit
pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "WobbleHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- Every top-level panel gets a UIScale so the HUD shrinks to fit narrow viewports without overlapping.
local scalers: { UIScale } = {}
local function addScaler(parent: Instance)
	local s = Instance.new("UIScale")
	s.Parent = parent
	table.insert(scalers, s)
end

local function panel(name: string, size: UDim2, pos: UDim2, anchor: Vector2): Frame
	local f = Instance.new("Frame")
	addScaler(f)
	f.Name = name
	f.Size = size
	f.Position = pos
	f.AnchorPoint = anchor
	f.BackgroundColor3 = PANEL
	f.BackgroundTransparency = 0.2
	corner(f, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.6
	stroke.Thickness = 2
	stroke.Parent = f
	f.Parent = gui
	return f
end

local function text(parent: Instance, value: string, size: UDim2, pos: UDim2, color: Color3, font: Enum.Font?): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = size
	t.Position = pos
	t.Text = value
	t.TextColor3 = color
	t.TextScaled = true
	t.Font = font or Enum.Font.FredokaOne
	t.TextStrokeTransparency = 0.3
	t.Parent = parent
	return t
end

local function withCommas(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return "$" .. formatted
end

-- Money panel (top centre, clear of Roblox's top-left buttons)
local moneyPanel = panel("Money", UDim2.new(0, 400, 0, 118), UDim2.new(0.5, -90, 0, 10), Vector2.new(0.5, 0))
local moneyText = text(moneyPanel, "$0", UDim2.new(1, -20, 0, 66), UDim2.new(0, 10, 0, 4), Color3.fromRGB(255, 225, 70))
local incomeText = text(moneyPanel, "+$0/s", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 70), GREEN)

-- Threat panel (top right): wave countdown and the next gull raid
local threatPanel = panel("Threats", UDim2.new(0, 310, 0, 132), UDim2.new(1, -12, 0, 10), Vector2.new(1, 0))
local waveText = text(threatPanel, "TIDAL WAVE IN 55s", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 6), WHITE)
local waveBarBack = Instance.new("Frame")
waveBarBack.Size = UDim2.new(1, -24, 0, 16)
waveBarBack.Position = UDim2.new(0, 12, 0, 50)
waveBarBack.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
corner(waveBarBack, 8)
waveBarBack.Parent = threatPanel
local waveBar = Instance.new("Frame")
waveBar.Size = UDim2.fromScale(1, 1)
waveBar.BackgroundColor3 = Color3.fromRGB(60, 180, 255)
corner(waveBar, 8)
waveBar.Parent = waveBarBack
local raidText = text(threatPanel, "GULL RAID IN 80s", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 72), Color3.fromRGB(255, 160, 160))
local shieldText = text(threatPanel, "BASE UNLOCKED", UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 102), Color3.fromRGB(255, 120, 120), Enum.Font.GothamBold)

-- Carry banner (bottom centre)
local carryPanel = panel("Carry", UDim2.new(0, 560, 0, 64), UDim2.new(0.5, 0, 0.6, 0), Vector2.new(0.5, 1))
local carryText = text(carryPanel, "", UDim2.new(1, -20, 1, -10), UDim2.new(0, 10, 0, 5), Color3.fromRGB(255, 230, 90))
carryPanel.Visible = false

-- How to play (left middle)
local helpPanel = panel("Help", UDim2.new(0, 250, 0, 204), UDim2.new(0, 12, 0.45, 0), Vector2.new(0, 0.5))
text(helpPanel, "HOW TO PLAY", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 6), Color3.fromRGB(120, 255, 220))
local helpLines = { "1. Buy a brainrot on the runway", "2. Carry it home to your base", "3. It earns money every second", "4. Hide from the TIDAL WAVE", "5. Lock base vs the gull" }
for i, line in helpLines do
	text(helpPanel, line, UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 14 + i * 26), WHITE, Enum.Font.GothamBold).TextXAlignment = Enum.TextXAlignment.Left
end
local baseText = text(helpPanel, "BASE 1/8", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, 168), Color3.fromRGB(255, 230, 90))

-- Action buttons (right middle)
local function button(label: string, color: Color3, y: number, action: string): TextButton
	local b = Instance.new("TextButton")
	addScaler(b)
	b.Size = UDim2.new(0, 240, 0, 66)
	b.Position = UDim2.new(1, -12, 0.45, y)
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.BackgroundColor3 = color
	b.Text = label
	b.TextColor3 = WHITE
	b.TextScaled = true
	b.Font = Enum.Font.FredokaOne
	b.TextStrokeTransparency = 0.2
	b.AutoButtonColor = true
	corner(b, 14)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = b
	b.Parent = gui
	b.Activated:Connect(function()
		Remotes.Action:FireServer(action)
	end)
	return b
end

local rebirthButton = button("REBIRTH", Color3.fromRGB(200, 70, 220), -80, "Rebirth")
local lockButton = button("LOCK BASE", Color3.fromRGB(40, 150, 230), 0, "Lock")
local speedButton = button("SPEED UP", Color3.fromRGB(60, 190, 90), 80, "Speed")

-- Toast notifications under the money panel
local toastHolder = Instance.new("Frame")
toastHolder.BackgroundTransparency = 1
toastHolder.Size = UDim2.new(0, 640, 0, 160)
toastHolder.Position = UDim2.new(0.5, 0, 0, 136)
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Parent = gui
addScaler(toastHolder)
local toastLayout = Instance.new("UIListLayout")
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 4)
toastLayout.Parent = toastHolder

local function showToast(message: string, color: Color3)
	local t = text(toastHolder, message, UDim2.new(1, 0, 0, 34), UDim2.new(), color)
	t.TextStrokeTransparency = 0
	task.delay(3.2, function()
		TweenService:Create(t, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		Debris:AddItem(t, 0.6)
	end)
	local items = toastHolder:GetChildren()
	if #items > 5 then
		for _, child in items do
			if child:IsA("TextLabel") then
				child:Destroy()
				break
			end
		end
	end
end

-- Full-screen flash used for wave hits, warnings and rebirths
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundTransparency = 1
flash.ZIndex = 0
flash.Parent = gui

local function flashScreen(color: Color3, strength: number, seconds: number)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - strength
	TweenService:Create(flash, TweenInfo.new(seconds), { BackgroundTransparency = 1 }):Play()
end

local shakeUntil = 0
local function shakeCamera(seconds: number)
	shakeUntil = os.clock() + seconds
end
RunService.RenderStepped:Connect(function()
	if os.clock() < shakeUntil then
		local cam = workspace.CurrentCamera
		local m = (shakeUntil - os.clock()) * 0.6
		cam.CFrame = cam.CFrame * CFrame.new(math.random() * m - m / 2, math.random() * m - m / 2, 0)
	end
end)

-- Rebuild every label from the server-published attributes, ten times a second.
local function refreshHud()
	local money = player:GetAttribute("Money") or 0
	local income = player:GetAttribute("Income") or 0
	local mult = player:GetAttribute("Multiplier") or 1
	moneyText.Text = money >= 1e6 and Catalog.formatMoney(money) or withCommas(money)
	incomeText.Text = string.format("+%s/s  x%.1f", Catalog.formatMoney(income), mult)
	baseText.Text = string.format("BASE %d/%d  REBIRTHS %d", player:GetAttribute("SlotsUsed") or 0, Catalog.Tuning.PedestalsPerBase, player:GetAttribute("Rebirths") or 0)
	local viewport = workspace.CurrentCamera.ViewportSize
	local s = math.clamp(viewport.X / 1000, 0.55, 1)
	for _, scaler in scalers do
		scaler.Scale = s
	end
	toastHolder.Position = UDim2.new(0.5, -90 * s, 0, 136 * s)

	local now = workspace:GetServerTimeNow()
	if ReplicatedStorage:GetAttribute("WaveActive") then
		waveText.Text = "WAVE! GET TO SAFETY!"
		waveText.TextColor3 = Color3.fromRGB(120, 200, 255)
		waveBar.Size = UDim2.fromScale(1, 1)
	else
		local left = math.max(0, (ReplicatedStorage:GetAttribute("WaveAt") or now) - now)
		waveText.Text = string.format("TIDAL WAVE IN %ds", math.ceil(left))
		local urgent = left <= Catalog.Tuning.WaveWarning
		waveText.TextColor3 = urgent and (math.floor(now * 3) % 2 == 0 and Color3.fromRGB(255, 80, 80) or WHITE) or WHITE
		waveBar.Size = UDim2.fromScale(math.clamp(left / Catalog.Tuning.WaveInterval, 0, 1), 1)
		waveBar.BackgroundColor3 = urgent and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(60, 180, 255)
	end
	local raidLeft = math.max(0, (ReplicatedStorage:GetAttribute("RaidAt") or now) - now)
	raidText.Text = raidLeft > 0 and string.format("GULL RAID IN %ds", math.ceil(raidLeft)) or "THE GULL IS HERE!"

	local shieldLeft = (player:GetAttribute("ShieldUntil") or 0) - now
	local readyIn = (player:GetAttribute("ShieldReadyAt") or 0) - now
	if shieldLeft > 0 then
		shieldText.Text = string.format("BASE LOCKED %ds", math.ceil(shieldLeft))
		shieldText.TextColor3 = Color3.fromRGB(110, 210, 255)
		lockButton.Text = string.format("LOCKED %ds", math.ceil(shieldLeft))
	else
		shieldText.Text = "BASE UNLOCKED"
		shieldText.TextColor3 = Color3.fromRGB(255, 120, 120)
		lockButton.Text = readyIn > 0 and string.format("RECHARGE %ds", math.ceil(readyIn)) or "LOCK BASE"
	end
	rebirthButton.Text = string.format("REBIRTH %s\n(x%.1f income)", Catalog.formatMoney(player:GetAttribute("RebirthCost") or 0), mult + Catalog.Tuning.RebirthBonus)
	local level = player:GetAttribute("SpeedLevel") or 0
	speedButton.Text = level >= Catalog.Tuning.MaxSpeedLevel and "SPEED MAXED" or string.format("SPEED UP %s\n(level %d)", Catalog.formatMoney(player:GetAttribute("SpeedCost") or 0), level + 1)

	local carrying = player:GetAttribute("Carrying") or ""
	carryPanel.Visible = carrying ~= ""
	carryText.Text = "CARRYING " .. string.upper(carrying) .. " - RUN HOME!"
end

-- One-shot particle burst at a world position.
local function burstAt(position: Vector3, color: Color3, count: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, WHITE)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.6, 1.1)
	emitter.Speed = NumberRange.new(12, 24)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(count)
	Debris:AddItem(anchor, 1.5)
end

-- "+$12" rising off a brainrot each time it pays.
local function floatMoneyPopup(model: Model, amount: number)
	if not model or not model.Parent or not model.PrimaryPart then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 110, 0, 30)
	bb.Adornee = model.PrimaryPart
	bb.StudsOffsetWorldSpace = Vector3.new(math.random() * 2 - 1, 2, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 90
	local label = text(bb, "+" .. Catalog.formatMoney(amount), UDim2.fromScale(1, 1), UDim2.new(), GREEN)
	label.TextStrokeTransparency = 0
	bb.Parent = model
	TweenService:Create(bb, TweenInfo.new(1.1), { StudsOffsetWorldSpace = bb.StudsOffsetWorldSpace + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(bb, 1.2)
end

-- Freshly placed brainrots pop in from small to full size with sparkles.
local function popPlacedBrainrot(model: Model, color: Color3)
	if not model or not model.Parent then
		return
	end
	burstAt(model:GetPivot().Position + Vector3.new(0, 3, 0), color, 60)
	local full = model:GetScale()
	local value = Instance.new("NumberValue")
	value.Value = full * 0.3
	value.Changed:Connect(function(v)
		if model.Parent then
			model:ScaleTo(v)
		end
	end)
	TweenService:Create(value, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Value = full }):Play()
	Debris:AddItem(value, 0.7)
end

-- Thrown off your feet by the tide.
local function wipeOutLocalPlayer()
	flashScreen(Color3.fromRGB(60, 160, 255), 0.7, 1.2)
	shakeCamera(0.8)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
		root.AssemblyLinearVelocity = Vector3.new(0, 45, -70)
	end
end

Remotes.Notify.OnClientEvent:Connect(function(message: string, color: Color3)
	showToast(message, color)
end)

Remotes.Fx.OnClientEvent:Connect(function(kind: string, a: any, b: any)
	if kind == "burst" then
		burstAt(a, b, 40)
	elseif kind == "place" then
		popPlacedBrainrot(a, b)
	elseif kind == "income" then
		for _, pair in a do
			floatMoneyPopup(pair[1], pair[2])
		end
	elseif kind == "waveWarning" then
		showToast("A TIDAL WAVE IS COMING! Get to a SAFE ZONE!", Color3.fromRGB(255, 90, 90))
		flashScreen(Color3.fromRGB(255, 60, 60), 0.25, 0.8)
	elseif kind == "wave" then
		shakeCamera(1.5)
	elseif kind == "wipeout" then
		wipeOutLocalPlayer()
	elseif kind == "raid" then
		showToast("THE CRUMB BANDIT swoops at " .. tostring(a) .. "'s base!", Color3.fromRGB(255, 140, 90))
	elseif kind == "bonk" then
		burstAt(a, Color3.fromRGB(110, 210, 255), 80)
	elseif kind == "rebirth" then
		flashScreen(Color3.fromRGB(255, 120, 255), 0.6, 1.5)
		shakeCamera(0.4)
	end
end)

task.spawn(function()
	while true do
		refreshHud()
		task.wait(0.1)
	end
end)
