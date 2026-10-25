# Chop-A-Forest V4.4 — Sell Sync & Pipeline (PATCH ONLY)

Base: **V4.3** (includes V4.2 and V4.1). Replace just the six files included in this ZIP; keep all other cogs.

Files: `main.lua`, `cogs/collection.lua`, `cogs/scheduler.lua`, `cogs/navigation.lua`, `cogs/trees.lua`, `cogs/ui.lua`.

## Changes

- **Sell Sync:** move to deposit pad CENTER, wait at least ~9 seconds, confirm `0/5` has stayed stable >=3.5 seconds; watch for delayed Cash changes. Retry one click ONLY if standing on pad did not change the inventory. Detect an inventory rebound and do not claim success from a transient zero. Hard deadline ~13.5s to avoid infinite stalls. No client-side inventory edits. DEBUG export includes the last 20 sale audits (bag and Cash before/after, duration).
- **Pipeline:** once a tree falls, its log models enter the existing persistent registry. When logs are still animating/not ready (or waiting retry), chop another tree instead of waiting, as long as pending logs are below max(9, 2*backpack capacity). Pick up ready wood before selecting new trees. If backlog is at limit, stop producing wood and wait or sell.
- **Instant TP:** reduces a fixed 230ms artificial delay to ~45ms, with one corrective retry if Roblox does not keep the expected position. No Step TP.
- **F8 STOP**, ATTACK/FARM priorities and HP safety remain from V4.3.

## How to install

Replace the six files in your GitHub repo with the files from this archive (respect `cogs/` paths); Commit changes. No need to delete any other cogs.

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.4.0'))()
```

The UI header should say `PIPELINE V4.4`.

**Limitation:** we cannot prove a server-side sell just from a client HUD. The wait and cash check reduce the race condition but do not guarantee a server transaction; if the game/server itself duplicates inventory, the client script cannot reliably fix it. Test with a small bag and inspect the cash value. The game may reject/correct fast teleportation.
