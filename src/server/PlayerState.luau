--!strict
-- PlayerState: the one place each player's progress lives (money, base slots, carried brainrot,
-- rebirths, speed upgrades, shield). Everything the HUD needs is mirrored onto Player attributes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))

export type Owned = { id: string, mutation: string }
export type State = {
	money: number,
	slots: { [number]: Owned? },
	carrying: Owned?,
	rebirths: number,
	speedLevel: number,
	plot: number,
	shieldUntil: number,
	shieldReadyAt: number,
	caught: number,
}

local PlayerState = {}
local states: { [Player]: State } = {}

function PlayerState.create(player: Player, plot: number): State
	local state: State = {
		money = Catalog.Tuning.StartMoney,
		slots = {},
		carrying = nil,
		rebirths = 0,
		speedLevel = 0,
		plot = plot,
		shieldUntil = 0,
		shieldReadyAt = 0,
		caught = 0,
	}
	-- a free starter so the base is never empty
	state.slots[1] = { id = "toastmaster", mutation = "Normal" }
	states[player] = state
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local reb = Instance.new("IntValue")
	reb.Name = "Rebirths"
	reb.Parent = stats
	stats.Parent = player
	PlayerState.publish(player)
	return state
end

function PlayerState.get(player: Player): State?
	return states[player]
end

function PlayerState.remove(player: Player)
	states[player] = nil
end

function PlayerState.all(): { [Player]: State }
	return states
end

function PlayerState.multiplier(state: State): number
	return 1 + state.rebirths * Catalog.Tuning.RebirthBonus
end

-- Money per second from every brainrot on the base, with the rebirth multiplier applied.
function PlayerState.incomePerSecond(state: State): number
	local total = 0
	for _, owned in state.slots do
		total += Catalog.incomeOf(owned.id, owned.mutation)
	end
	return total * PlayerState.multiplier(state)
end

function PlayerState.freeSlot(state: State): number?
	for i = 1, Catalog.Tuning.PedestalsPerBase do
		if state.slots[i] == nil then
			return i
		end
	end
	return nil
end

-- Mirror state to attributes; the client HUD reads only these.
function PlayerState.publish(player: Player)
	local state = states[player]
	if not state then
		return
	end
	player:SetAttribute("Money", state.money)
	player:SetAttribute("Income", PlayerState.incomePerSecond(state))
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("Multiplier", PlayerState.multiplier(state))
	player:SetAttribute("RebirthCost", Catalog.rebirthCost(state.rebirths))
	player:SetAttribute("SpeedLevel", state.speedLevel)
	player:SetAttribute("SpeedCost", Catalog.speedUpgradeCost(state.speedLevel))
	player:SetAttribute("ShieldUntil", state.shieldUntil)
	player:SetAttribute("ShieldReadyAt", state.shieldReadyAt)
	player:SetAttribute("Plot", state.plot)
	local used = 0
	for _ in state.slots do
		used += 1
	end
	player:SetAttribute("SlotsUsed", used)
	if state.carrying then
		local entry = Catalog.ById[state.carrying.id]
		local prefix = state.carrying.mutation == "Normal" and "" or (state.carrying.mutation .. " ")
		player:SetAttribute("Carrying", prefix .. entry.name)
	else
		player:SetAttribute("Carrying", "")
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		(stats:FindFirstChild("Cash") :: StringValue).Value = Catalog.formatMoney(state.money);
		(stats:FindFirstChild("Rebirths") :: IntValue).Value = state.rebirths
	end
end

function PlayerState.addMoney(player: Player, amount: number)
	local state = states[player]
	if state then
		state.money += amount
		PlayerState.publish(player)
	end
end

function PlayerState.trySpend(player: Player, amount: number): boolean
	local state = states[player]
	if not state or state.money < amount then
		return false
	end
	state.money -= amount
	PlayerState.publish(player)
	return true
end

-- Rebirth: pay the cost, wipe money and base, keep a permanent income multiplier and better spawn luck.
function PlayerState.rebirthPlayer(player: Player): boolean
	local state = states[player]
	if not state then
		return false
	end
	local cost = Catalog.rebirthCost(state.rebirths)
	if state.money < cost then
		return false
	end
	state.rebirths += 1
	state.money = Catalog.Tuning.StartMoney * (1 + state.rebirths)
	state.slots = { [1] = { id = "toastmaster", mutation = "Gold" } }
	state.carrying = nil
	PlayerState.publish(player)
	return true
end

-- Speed upgrade: each level adds 3 walk speed so the dash home beats the wave.
function PlayerState.buySpeedUpgrade(player: Player): boolean
	local state = states[player]
	if not state or state.speedLevel >= Catalog.Tuning.MaxSpeedLevel then
		return false
	end
	if not PlayerState.trySpend(player, Catalog.speedUpgradeCost(state.speedLevel)) then
		return false
	end
	state.speedLevel += 1
	PlayerState.applyWalkSpeed(player)
	PlayerState.publish(player)
	return true
end

function PlayerState.applyWalkSpeed(player: Player)
	local state = states[player]
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if state and humanoid then
		humanoid.WalkSpeed = 18 + state.speedLevel * 3
	end
end

return PlayerState
