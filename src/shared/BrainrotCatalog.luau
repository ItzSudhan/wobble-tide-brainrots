--!strict
-- BrainrotCatalog: the whole cast of Wobble Tide, its rarity ladder, mutations and game tuning.
-- Shared by server (spawning, prices, income) and client (HUD colours, number formatting).

local Catalog = {}

Catalog.Tuning = {
	StartMoney = 100,
	PedestalsPerBase = 8,
	SpawnInterval = 2.4, -- seconds between runway spawns
	WalkSpeed = 7, -- studs per second along the runway
	WaveInterval = 55, -- seconds between tidal waves
	WaveWarning = 15, -- seconds of countdown shown before a wave
	RaidInterval = 80, -- seconds between Crumb Bandit raids
	ShieldSeconds = 40,
	ShieldCooldown = 25,
	RebirthBaseCost = 25000,
	RebirthCostGrowth = 6,
	RebirthBonus = 0.5, -- +50% income per rebirth
	SpeedUpgradeBase = 500,
	MaxSpeedLevel = 6,
}

export type Rarity = { name: string, color: Color3, weight: number, scale: number }

Catalog.Rarities = {
	{ name = "Common", color = Color3.fromRGB(200, 200, 200), weight = 50, scale = 1.0 },
	{ name = "Uncommon", color = Color3.fromRGB(90, 220, 110), weight = 26, scale = 1.1 },
	{ name = "Rare", color = Color3.fromRGB(70, 160, 255), weight = 13, scale = 1.2 },
	{ name = "Epic", color = Color3.fromRGB(190, 90, 255), weight = 6, scale = 1.35 },
	{ name = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 3, scale = 1.5 },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 90), weight = 1.5, scale = 1.65 },
	{ name = "Cosmic", color = Color3.fromRGB(80, 255, 240), weight = 0.5, scale = 1.85 },
}

Catalog.Mutations = {
	{ name = "Normal", mult = 1, chance = 85 },
	{ name = "Gold", mult = 2, chance = 12, color = Color3.fromRGB(255, 200, 40) },
	{ name = "Rainbow", mult = 5, chance = 3, color = Color3.fromRGB(255, 120, 220) },
}

-- Each brainrot: a body (shape, size, colour), an accent colour, extras the builder bolts on, and a quip.
Catalog.Brainrots = {
	{ id = "toastmaster", name = "Toastmaster Flapjack", rarity = 1, cost = 25, income = 1,
		body = { shape = "Block", size = Vector3.new(3, 2.6, 2.2), color = Color3.fromRGB(190, 190, 200) },
		accent = Color3.fromRGB(210, 150, 80), extras = { "toast", "legs2" }, quip = "gives speeches nobody asked for" },
	{ id = "sockolomew", name = "Sockolomew", rarity = 1, cost = 40, income = 2,
		body = { shape = "Cylinder", size = Vector3.new(4.2, 1.8, 1.8), color = Color3.fromRGB(240, 240, 235) },
		accent = Color3.fromRGB(220, 60, 60), extras = { "stripes", "legs2" }, quip = "lost its twin in 2009" },
	{ id = "bricky", name = "Bricky Gillsworth", rarity = 1, cost = 60, income = 3,
		body = { shape = "Block", size = Vector3.new(3.6, 1.8, 2), color = Color3.fromRGB(180, 80, 60) },
		accent = Color3.fromRGB(80, 170, 220), extras = { "fishtail", "fin" }, quip = "a fish that chose construction" },
	{ id = "pickleton", name = "Pickleton Wobblesworth", rarity = 2, cost = 150, income = 6,
		body = { shape = "Cylinder", size = Vector3.new(4, 2, 2), color = Color3.fromRGB(110, 170, 60) },
		accent = Color3.fromRGB(30, 30, 35), extras = { "tophat", "arms", "legs2" }, quip = "brined, refined, unkind" },
	{ id = "mopwalker", name = "Mopwalker Supreme", rarity = 2, cost = 220, income = 9,
		body = { shape = "Cylinder", size = Vector3.new(4.5, 1, 1), color = Color3.fromRGB(150, 110, 70) },
		accent = Color3.fromRGB(235, 235, 220), extras = { "mophead", "legs2" }, quip = "cleans nothing, judges everything" },
	{ id = "bloopington", name = "Sir Bloopington", rarity = 2, cost = 300, income = 12,
		body = { shape = "Block", size = Vector3.new(2.8, 2.8, 2.8), color = Color3.fromRGB(255, 110, 170) },
		accent = Color3.fromRGB(255, 230, 90), extras = { "crown", "jelly" }, quip = "a jelly cube with a knighthood" },
	{ id = "karaokus", name = "Cactus Karaokus", rarity = 3, cost = 800, income = 28,
		body = { shape = "Cylinder", size = Vector3.new(5, 2.2, 2.2), color = Color3.fromRGB(60, 150, 70) },
		accent = Color3.fromRGB(40, 40, 40), extras = { "spikes", "arms", "mic" }, quip = "sings only in the key of ouch" },
	{ id = "fridgeasaurus", name = "Fridgeasaurus", rarity = 3, cost = 1100, income = 38,
		body = { shape = "Block", size = Vector3.new(2.6, 4.4, 2.4), color = Color3.fromRGB(235, 240, 245) },
		accent = Color3.fromRGB(90, 190, 90), extras = { "dinotail", "legs2", "handle" }, quip = "extinct since the milk expired" },
	{ id = "kettledrum", name = "Kettle Drumdrum", rarity = 3, cost = 1500, income = 50,
		body = { shape = "Ball", size = Vector3.new(3.2, 3.2, 3.2), color = Color3.fromRGB(60, 120, 200) },
		accent = Color3.fromRGB(240, 220, 150), extras = { "spout", "drumsticks", "legs2" }, quip = "boils at 140 bpm" },
	{ id = "baguettopus", name = "Baguettopus", rarity = 4, cost = 4000, income = 120,
		body = { shape = "Cylinder", size = Vector3.new(5.5, 1.6, 1.6), color = Color3.fromRGB(215, 160, 80) },
		accent = Color3.fromRGB(150, 90, 40), extras = { "legs8", "beret" }, quip = "eight arms, zero crumbs left" },
	{ id = "donutdynamo", name = "Donut Dynamo", rarity = 4, cost = 6000, income = 175,
		body = { shape = "Donut", size = Vector3.new(1.4, 4, 4), color = Color3.fromRGB(230, 170, 100) },
		accent = Color3.fromRGB(255, 120, 200), extras = { "sprinkles", "legs2", "antenna" }, quip = "powered by a hole" },
	{ id = "lampshade", name = "Lampshade Larry", rarity = 5, cost = 15000, income = 400,
		body = { shape = "Cylinder", size = Vector3.new(4.5, 1.2, 1.2), color = Color3.fromRGB(60, 50, 45) },
		accent = Color3.fromRGB(255, 230, 140), extras = { "lampshade", "glow", "legs2" }, quip = "prophet of the living room" },
	{ id = "spatulamoon", name = "Captain Spatula Moon", rarity = 5, cost = 22000, income = 600,
		body = { shape = "Block", size = Vector3.new(3, 4, 0.8), color = Color3.fromRGB(200, 205, 215) },
		accent = Color3.fromRGB(200, 40, 60), extras = { "cape", "handlestick", "halo" }, quip = "flips pancakes and destinies" },
	{ id = "duckgarage", name = "Duck-Duck Garage", rarity = 6, cost = 60000, income = 1500,
		body = { shape = "Block", size = Vector3.new(4.4, 3.4, 4), color = Color3.fromRGB(160, 160, 170) },
		accent = Color3.fromRGB(255, 210, 40), extras = { "garagedoor", "duckhead", "legs4" }, quip = "parks itself, quacks the rent" },
	{ id = "thundersock", name = "Grandma Thundersock", rarity = 6, cost = 90000, income = 2200,
		body = { shape = "Cylinder", size = Vector3.new(5.5, 2.4, 2.4), color = Color3.fromRGB(140, 90, 200) },
		accent = Color3.fromRGB(255, 240, 80), extras = { "stripes", "lightning", "glasses", "legs2" }, quip = "knits storms, darns lightning" },
	{ id = "oracle", name = "The Wobble Tide Oracle", rarity = 7, cost = 250000, income = 6000,
		body = { shape = "Ball", size = Vector3.new(4.5, 4.5, 4.5), color = Color3.fromRGB(80, 220, 230) },
		accent = Color3.fromRGB(255, 140, 240), extras = { "rings", "halo", "glow", "jelly" }, quip = "predicted this wave. and the next." },
}

Catalog.ById = {}
for _, entry in Catalog.Brainrots do
	Catalog.ById[entry.id] = entry
end

function Catalog.rarityOf(entry): Rarity
	return Catalog.Rarities[entry.rarity]
end

function Catalog.mutationByName(name: string)
	for _, m in Catalog.Mutations do
		if m.name == name then
			return m
		end
	end
	return Catalog.Mutations[1]
end

-- Income per second of one brainrot, before the owner's rebirth multiplier.
function Catalog.incomeOf(id: string, mutation: string): number
	local entry = Catalog.ById[id]
	return entry.income * Catalog.mutationByName(mutation).mult
end

-- Pick a rarity tier; luck (from rebirths) fattens the rare end of the table.
function Catalog.rollRarity(rng: Random, luck: number): number
	local total = 0
	local weights = {}
	for i, r in Catalog.Rarities do
		weights[i] = r.weight * (1 + luck * (i - 1) * 0.35)
		total += weights[i]
	end
	local roll = rng:NextNumber() * total
	for i, w in weights do
		roll -= w
		if roll <= 0 then
			return i
		end
	end
	return 1
end

function Catalog.rollBrainrot(rng: Random, luck: number)
	local tier = Catalog.rollRarity(rng, luck)
	local pool = {}
	for _, entry in Catalog.Brainrots do
		if entry.rarity == tier then
			table.insert(pool, entry)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

function Catalog.rollMutation(rng: Random): string
	local roll = rng:NextNumber() * 100
	for _, m in Catalog.Mutations do
		roll -= m.chance
		if roll <= 0 then
			return m.name
		end
	end
	return "Normal"
end

function Catalog.priceOf(id: string, mutation: string): number
	local entry = Catalog.ById[id]
	return math.floor(entry.cost * (mutation == "Normal" and 1 or Catalog.mutationByName(mutation).mult * 0.8))
end

function Catalog.rebirthCost(rebirths: number): number
	return Catalog.Tuning.RebirthBaseCost * Catalog.Tuning.RebirthCostGrowth ^ rebirths
end

function Catalog.speedUpgradeCost(level: number): number
	return Catalog.Tuning.SpeedUpgradeBase * 4 ^ level
end

function Catalog.formatMoney(n: number): string
	local units = { "", "K", "M", "B", "T" }
	local i = 1
	while math.abs(n) >= 1000 and i < #units do
		n /= 1000
		i += 1
	end
	if i == 1 then
		return "$" .. tostring(math.floor(n))
	end
	return string.format("$%.1f%s", n, units[i])
end

return Catalog
