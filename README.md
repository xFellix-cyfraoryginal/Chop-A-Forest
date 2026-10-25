# CropForest V4.6 Skeleton Focus — PATCH ONLY

Base: V4.5 RED DODGE (with V4.4 Sell Pipeline if you used it).
Copy only main.lua and files under cogs/ to matching paths on GitHub.
Do not delete other cogs, especially cogs/dodge.lua.

## Changes
- ATTACK FIRST = unlimited-range hunt of all valid Gravedigger / Graveyard_Sprout / skeleton-like mobs, including final remaining enemy.
- Skips Graveyard_Biter (Pumpkinling) and Guardian (Jack o' Lantern). When no skeletons, switches to normal tree + log pipeline.
- FARM FIRST remains the existing behavior (self-defense on actual damage).
- Startup checks real AxeBoughtAt. If none, stops and asks for manual axe purchase (Auto Buy is not implemented without a verified purchase protocol).
- Backpack checks a small set of ownership attributes IF game exposes one; with an unknown marker cannot claim it is owned. Stops if carrying logs in hands (`CarriedLogs > 0`) so E doesn't drop carried wood.
- Use separate RAW logger to capture TAB upgrade purchases and item ownership. The logger is NOT in the GitHub patch.

Notes: model name Gravedigger is confirmed by the previous Halloween logger. New unknown skeleton types need an updated signature. Roblox testing not possible in this environment.
