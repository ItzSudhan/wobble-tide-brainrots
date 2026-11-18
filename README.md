# wobble-tide-brainrots

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ItzSudhan/wobble-tide-brainrots/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ItzSudhan/wobble-tide-brainrots/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Wobble Tide Brainrots** is a 3D Roblox brainrot game set on a beach island. Absurd brainrots waddle down the Brainrot Runway. Buy one, carry it home on your head and set it on a pedestal, where it earns money every second. Then save up for rarer ones.

- **16 original brainrots** built from parts, each with googly eyes and a floating name / rarity / $-per-second label. The ladder runs Common → Uncommon → Rare → Epic → Legendary → Mythic → Cosmic, from Toastmaster Flapjack and Sockolomew up to Fridgeasaurus, Baguettopus, Duck-Duck Garage, Grandma Thundersock and The Wobble Tide Oracle.
- **Mutations**: Gold (x2 income) and Rainbow (x5), with sparkles.
- **Tidal wave**: every 55 s a wave sweeps the island. If it catches you outside a safe zone (your base or a lifeguard tower), you're wiped out and the brainrot on your head is lost.
- **The Crumb Bandit**: a masked gull raids a base every 80 s and steals a brainrot unless you lock the base's shield dome first.
- **Rebirths** (+50% income each, and luckier spawns) and **speed upgrades** to outrun the tide.
- The server owns money, inventory, spawning and both threats (`PlayerState`, `BrainrotMarket`, `BaseService`, `ThreatDirector`, `WorldBuilder`). The client (`HudController`) only draws the HUD and effects and asks the server to act.

## Run it

```sh
rojo build default.project.json --output game.rbxl   # then open game.rbxl in Roblox Studio and press Play
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=1pww8frk&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
