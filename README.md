# Crop Forest V4.8.0 — Egg Pickup + Continuous Air Hover

PATCH ONLY over V4.7.9. Upload exactly these changed files and commit.

- `main.lua`: registers `hover.lua` and `egg.lua`, cache version 4.8.0.
- `cogs/hover.lua` NEW: continuous air-hold during tree work and Instant TP,
  no extra hover on sale or pumpkin. Dynamic trunk position per Heartbeat.
- `cogs/combat.lua`: Guardian air orbit, live moving-target hover for minions;
  Walk mode still moves normally. Dodge still interrupts hover until warning ends.
- `cogs/trees.lua`, `cogs/collection.lua`: maintain hover on live trees and loose logs (short time-to-live for pickups); rebind after reposition.
- `cogs/navigation.lua`, `cogs/core.lua`: clear air-hold on navigation,
  Stop, unload, death and movement-mode changes.
- `cogs/egg.lua` NEW: owner-only Workspace.EggDrops, free PickPrompt,
  confirmed EggNotice and removal, never paid EggPrompt (25 gems).
- `cogs/pumpkin.lua`: handle Model PumpkinHead (V12 confirmed Monster=Head)
  by pivot / part; stay grounded for pumpkin smashing.
- `cogs/scheduler.lua`: egg pickup ahead of pumpkin head and other farm work.

Keeps existing Auto Backpack, Claws Speed Auto Buy, Claws MAX Tree Rush,
Kill Mobs ON/OFF, Auto Farm ON/OFF, F6/F8, Walk mode, dodge.

Run after commit:
loadstring(game:HttpGet('https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.0'))()

Static parse checked; requires in-game test. Executor may reject prompt simulation.
