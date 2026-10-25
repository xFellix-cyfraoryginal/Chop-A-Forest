# Chop-A-Forest V4.7.5 — WALK MODE ONLY PATCH

Apply over **V4.7.4** by replacing only `main.lua`, `cogs/ui.lua` and `cogs/combat.lua`. Do not remove `cogs/navigation.lua` — its existing pathfinding/MoveTo implementation enables Walk mode.

The compact panel now has a **MOVEMENT: Instant TP / Walk** button (default Instant TP). Click it to switch at runtime. Walk uses Humanoid MoveTo and pathfinding for trees, wood, sell and mobs; combat chases moving enemies on foot rather than teleporting above them. The existing red-warning dodge and HP emergency retreat are still allowed to reposition instantly for survival. Walking is slower, especially against moving bosses.

Everything else is unchanged: AUTO FARM ON/OFF, KILL MOBS ON/OFF, F6 start/stop, F8 emergency stop. No auto-buy Axe/Backpack, upgrades or auto-Endless.

Loader:
`loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.7.5"))()`

Syntax validated locally. Real in-game movement not tested.
