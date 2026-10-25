# Chop-A-Forest V4.5 — Telegraph Dodge (PATCH ONLY)

**Base:** V4.3 **or** V4.4. This ZIP has just the updated files, not the whole repository. Existing `cogs/world.lua` and `cogs/survival.lua` remain untouched. Upload the included `main.lua` plus the included `cogs/*.lua` into their respective paths and Commit to GitHub.

**New cog:** `cogs/dodge.lua` — required by V4.5 `main.lua`. Upload it before executing the loader.

## New features

- **Automatic red-floor telegraph dodge:** observes the verified inbound `ReplicatedStorage.Shared.Services.ChopRemotes.MonsterFx` RemoteEvent. Its `Warn` event provides exact circle (`At`, `Radius`) or line (`From`, `Dir`, `Width`, `Length`) geometry plus the advance-warning duration (`Time`). No method hooks, fake remote calls, or screen image recognition.
- Chooses the nearest position outside all currently visible dangerous shapes, with an extra spatial margin. Uses emergency repositioning (independent of Walk/Instant TP). Checks while chopping/collecting/fighting and prevents the live mob hover controller from immediately undoing the dodge.
- Tracks `FireTrail` lines separately for their reported duration. Existing wood queue and combat targeting remain intact; F8 immediately stops.
- **Jack o' Lantern boss:** recognized from `Monster='Guardian'` and `MonsterId`, `HP`, `MaxHP`, `State`. ATTACK FIRST does not stop at one remaining Guardian. It prefers to finish minions before the boss. Fights are still dependent on game-confirmed damage.
- **Chainsaw (beta, still opt-in):** Auto profile can read the game's actual `Player:GetAttribute('Tool')`; includes the observed `Revving`/`SawHeat` conditions and longer mouse hold while equipped. No guessed reload key; V8.1 does not confirm a reload mechanic. Use TOOLS > `Unverified tools: ON` to try it, and watch HP changes.
- Keeps V4.4 Sell Sync + Pipeline improvements even if you were previously on V4.3. DEBUG shows the Dodge count and exports it.

## Captured telemetry behind this change

The supplied BossScout V8.1 JSON captured **32** warning packets: `Bite` 14, `Pumpkin` 6, `Slam` 5, `Roll` 4, `Snare` 2, `Summon` 1. Bite circle was radius 4.5 and 0.45-second warning; Slam around radius 20.4, 1–1.1 seconds; Pumpkin radius 10.5 and 1.5 seconds; Roll line around width 20.16 and 1.4 seconds; Snare line width 12 and 1.2 seconds. The logs also contain `Revving`, `SawHeat`, `SawHeatRate` for the Chainsaw, but no proven reload sequence.

## Load after uploading + GitHub commit

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.5.0'))()
```

Expected UI banner: `CHOP A FOREST / DODGE V4.5`.

**Testing limitation:** all Lua sources compiled successfully in a local Lua interpreter and warning packet schemas were validated against the provided logs. We cannot run Roblox server physics or know whether every emergency movement will be accepted; teleport anti-cheat/server correction may cause a dodge to fail. The data does not establish that all red areas harm players at every height, so this intentionally uses conservative XZ footprints.
