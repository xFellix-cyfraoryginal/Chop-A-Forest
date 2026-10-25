# Chop-A-Forest — Smart Farm V3.2

Repo: `xFellix-cyfraoryginal/Chop-A-Forest`. Pure Lua/Luau. `main.lua` fetches the cogs via raw GitHub, in order.

## Deploy
Upload `main.lua`, every file in `cogs/` and `README.md` **preserving relative paths**. Commit them to branch `main`. Then start the existing loadstring:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua"))()
```

All cogs have fewer than 300 lines. There is no Python or separate logger in the repository.

## Changes in V3.2

- `attack.lua`: Shared item cooldown limiter across attacks and pickup. Adjustable `itemCooldown` (default 0.62 s). If an equipped Roblox Tool exposes `AttackCooldown`, `SwingCooldown`, `Cooldown` or `AttackDelay`, honor it if longer (not a guarantee of game-specific slot cooldown). Cooldown gets refreshed on successful input; server's own cooldown always applies.
- `settle.lua`: After tree is confirmed felled, wait until nearby logs exist, no new logs arrive, and their positions remain stable during falling animation. Max wait 6.5 s by default.
- `world.lua`: Newly spawned logs cannot be picked immediately (min age 2.4 s). Attempts still require HUD bag increase to count as pickups. Per-tree collection prefers newly created logs, not existing drops from older trees.
- `safety.lua` / `tactics.lua`: Crowd within 17 studs alone is not an emergency; steer around mobs during Walk. Retreat if critical HP, recent damage, boss or actual close crowd. Walk is default, and escape mode defaults to 'Match farm'.
- `combat.lua`: Orbit target between attacks instead of only backing away, still requires real HP reduction for confirmed hits.
- `movement.lua`: `face` may rotate body without forcing the camera if Free Look is on.
- `camera.lua`: Optional independent camera, all rendering remains enabled, with character position marker. **Camera-dependent clicks can fail in spectator mode.** This is not verified silent aim.
- No Eco switch; moderate UI/ESP cadence remains automatic.

## Test order
1. Fresh Roblox session. Test Walk, free look OFF, spectator OFF. Tree -> falling animation -> logs -> Sell.
2. Enable Free Look. Check whether tree hits/pickup still increase server HP/bag. If not, switch it OFF.
3. Enable Spectator only after working with Free Look. The scene remains fully rendered; use RMB to rotate, arrows to move camera, PageUp/Down to raise/lower camera. Because game input may rely on camera aim, **this mode may break attacks/collection**. Turn it OFF if so.
4. Enable Defend combat, Kite ON. Observe retreat behavior and HP. This is a prototype and not guaranteed to prevent deaths.
5. Export DEBUG JSON for misses/timeouts. No logger required.

No attempt to bypass game server hit validation. Do not assume client-side visuals equal server-confirmed successful actions.
