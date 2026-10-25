# Chop-A-Forest | Core Rewrite V4.0

**Luau-only repository, no Python, no logger in the repository.**

## Files

- `main.lua` loads and compiles all modules from this public GitHub repository.
- `cogs/core.lua` lifecycle, hotkey F8, settings, debug state.
- `cogs/world.lua` tree model detection; permanent (per session) queue of physical logs; monster detection by attributes.
- `cogs/navigation.lua` Walk, Step TP, Instant TP and interrupted movement.
- `cogs/tools.lua` input, item-specific cooldown, limited experimental generic input.
- `cogs/survival.lua` health/danger watchdog and recovery.
- `cogs/trees.lua` chop and confirmation by server-replicated HP.
- `cogs/collection.lua` animation settle, pickup verification by backpack, selling.
- `cogs/combat.lua` avoids shop NPCs; verifies monster damage; sidesteps.
- `cogs/scheduler.lua` **one decision-maker**, queue survives recovery and STOP within session.
- `cogs/ui.lua` small 3-tab draggable UI, debugging.

## Installation

Upload `main.lua` and the **entire** `cogs/` folder to
`https://github.com/xFellix-cyfraoryginal/Chop-A-Forest` branch `main`.

Then execute:

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.0.0'))()
```

### Quick start

Default: **Walk**, **Balanced**, **Auto** tool (Axe/fists fallback), combat ON, survival ON, pickup ON, sell ON.
Press **F8** for emergency stop, or click STOP. Press START to resume during the current loaded session.
To avoid risking a character, first test on a peaceful/low-risk run.

### Important equipment restrictions

Axe and Fists have evidence of successful input actions in V7 capture. The script's `Auto` tool detection inspects an equipped Roblox `Tool`, when available, otherwise defaults to slot 2 (Axe).

Chainsaw, Pistol and Vacuum are marked **experimental**. The game may implement them without Roblox Tool objects (or via custom input protocols), so V4 cannot reliably auto-equip them or guarantee correct actions. These features need individual validation; they are OFF by default. The `Unverified tools` switch enables generic mouse input only if a matching Tool is detected, and V4 still verifies observed HP/backpack changes.

### What V4 changes

1. No memory loss of logs on retreat: a log job is removed only when its model disappears, and failed pickups are delayed individually. No arbitrary max-distance deletion.
2. Newly spawned logs are not clicked until ~2.2s after spawn and after ~0.75s without movement (with 8s max wait).
3. Pickup success means a **real backpack increment**; otherwise retry later.
4. Combat targets must carry `MonsterId`, `Monster`, `HP`, `MaxHP` and live inside `Workspace.Monsters`. Bosses (Guardian) are never hunted by default.
5. Panic reacts to critical HP / immediate pressure, instead of nearby monsters automatically causing endless retreat.
6. Old camera/spectator/ESP/Eco settings have been intentionally removed.
7. Every cog is under 300 lines; no build scripts needed.

### Known limitations

- **Unverified in live Roblox.** Static Lua syntax checking cannot prove it works with executor APIs or server checks.
- F8 is emergency **STOP** (not UNLOAD). Logs remain queued while this script exists; restarting Roblox clears runtime state.
- Movement, aiming, and input can affect the camera normally. There is no freecam or silent aim module.
- Server may reject teleportation or tool actions. Danger avoidance and retreat cannot guarantee zero deaths.
- Models spawned into the World after startup that are not under the expected folders require a future adjustment.
- A dropped log blocked by mobs remains remembered and may be retried later; this does not guarantee every unreachable log will be picked up.
