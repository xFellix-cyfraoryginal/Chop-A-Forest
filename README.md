# Chop-A-Forest V4.1 — Action First

**Luau only** — `main.lua` + `cogs/`, each cog under 300 lines. No Python, no logger.

Repository target: `https://github.com/xFellix-cyfraoryginal/Chop-A-Forest` (`main`).

## Install

Replace **both** `main.lua` and all files in `cogs/` with this archive; commit to GitHub.
Run from the game executor:

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.1.0'))()
```

The UI heading is `ACTION FIRST V4.1`; if it still says `V4.0`, replace GitHub files.

## Core behavior

- **Priority FARM FIRST** (default): chop trees, wait for settled logs, pick them up, sell. Nearby monsters do not block target selection. **Taking actual damage** enables temporary retaliation against a nearby mob, after which work resumes. The same response works for the last remaining mob in ATTACK mode.
- **Priority ATTACK FIRST**: kill nearby detected `MonsterId` enemies until **at most one** is within 65 studs, then farm. Bosses (`Monster=Guardian`) are excluded. Attack attempts are verified against actual mob HP and temporarily cooled down after repeated misses.
- **Movement Instant TP** (default) teleports once to the desired target. **Walk** remains optional. Both are available in MAIN; Step TP was removed.
- **HP Pause** (TOOLS): defaults to six seconds when damage drops health to **40% or below**. The HP pause is deferred if an enemy is within 11 studs, preventing a frozen character from standing still while under attack. No automatic running to a safe zone, no `safe tree` or `safe wood` restrictions. The pause is retriggered only by subsequent damage after its cooldown.
- **F8** instantly stops the farm. Press START to resume; queued logs survive STOP during the same session.
- Item input and pickup must produce visible server-side state changes (tree/mob HP or backpack count). Log queue is not cleared by a failed pickup.

## Caveats

- This is **unverified inside live Roblox**. Syntax and loader checks do not establish effective damage/pickup, server-accepted teleportation or safety.
- A server can reject or revert instant teleportation.
- FARM FIRST intentionally prioritizes harvesting over avoiding monsters; it can get the character killed. F8 is available for immediate STOP.
- The short HP Pause has no guaranteed healing: if the game does not regenerate health, it resumes after the chosen duration rather than staying stuck forever.
- `Axe`/`Fists` have observed interactions in recorded logs; `Chainsaw`, `Vacuum` and `Pistol` still have experimental controls only.
- ATTACK FIRST is not endless combat: once the nearby monster count reaches one, harvesting resumes. New spawns may trigger another clear cycle.
