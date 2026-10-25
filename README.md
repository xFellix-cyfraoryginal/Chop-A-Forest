# Chop-A-Forest | Smart Farm V3.3 – Persistent Wood

**Repo:** `https://github.com/xFellix-cyfraoryginal/Chop-A-Forest`

Repo contains only Luau `main.lua` and `cogs/` — no logger and no Python.

## Installation

1. Upload and commit **all** `main.lua` and `cogs/*.lua` from this ZIP to the root of the `main` branch.
2. If replacing V3.2, delete obsolete `cogs/camera.lua` and `cogs/settle.lua` from the repo (not used anymore).
3. Close and reopen Roblox to clear old spectator/camera callbacks and stale script sessions.
4. Run in your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=SmartFarm_3_3"))()
```

Check the header says **SMART FARM V3.3** (not V3.1 / V3.2).

## Emergency key

**F8** — cancel current walk, attack, collection and farm loop immediately. It does not unload the UI. Start again via START. Key disabled while typing into a Roblox textbox.

## New wood scheduler

- Spawned logs are tracked as object instances in a persistent in-session wood-job table; old log jobs are removed only when corresponding game objects vanish.
- One sampler (~0.23s when running) tests each log's movement and rotation. Only logs older than `logMinAge` and still for `logSettleTime` are eligible for pickup.
- Wood is prioritized **before** the next tree; on safety retreat the jobs are kept and retried on recovery.
- Failed pickups get individual exponential retry intervals (1.2–12 seconds), not permanent omission.
- `maxLogDistance=360` studs by default. Adjust in MOVE if your map is larger.
- Success requires actual backpack count increase. Dangerous logs are deferred, not forgotten. The bot will only sell after collecting reachable stable logs, or when bag is full.
- Live panel displays `WOOD <pending> [<ready> ready]`.

## Original functionality

Walk, Step TP, Instant TP; tree chopping, combat by monster attributes, sale, event options and safety watchdog remain. Experimental spectator/free-look were removed. The standard input-camera alignment remains, as the game may use camera direction for swings and pickup clicks.

**Important limitations**

- Roblox server authority can still reject clicks, movement or combat; the developer cannot verify this client runtime.
- If logs always stay in a dangerous spot, the bot safely defers those logs and may work elsewhere; it does not blindly run into mobs.
- F8 emergency STOP does not remove UI or unload the code; UNLOAD cleans up the session.
- Switching versions: restart Roblox before the new version if you previously used Spectator.
