# Chop-A-Forest | Auto Farm Survival V3.1 Lite

Single-language **Luau** source, GitHub RAW loader and `cogs/` modules. **No Python and no loggers** in this repository.

### Changes from V3
- Defaults: **Performance: Eco**, tree/log/mob highlights disabled (you can enable them in CONFIG and COMBAT).
- Tree selection uses 96-stud spatial cells instead of scanning all trees every iteration.
- Area identification cached briefly while player stays near the same position.
- Successful/failed walking path objects are released with `:Destroy()`; short journeys skip pathfinding.
- UI and optional visuals update less frequently on Eco. Safety watchdog **still checks rapidly** when the farm is running.
- STOP/START race fixed using a session token; stale loops cannot turn off a newly started farm.
- Broken trees get a temporary retry cooldown, preventing wasteful retry loops.
- UNLOAD clears cached world data, visual objects and event connections.

### Installation
Upload `main.lua` and `cogs/` (preserve directory names) to your existing repository:
`https://github.com/xFellix-cyfraoryginal/Chop-A-Forest`

Then run through your executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua"))()
```

### Important memory warning
A Task Manager snapshot showing about **10 GB Roblox RAM before injecting V3** cannot be explained by V3.1. Shut down every Roblox client process, restart and measure idle memory **before** testing. Roblox asset memory / engine caching is not released by running garbage collection in a Luau script. We do not claim a reduction of the game's native memory use.

### Testing
1. Relaunch Roblox, note idle RAM, CPU and GPU in Task Manager.
2. Run Auto Farm in Eco mode; keep all highlights OFF for baseline.
3. Test 1 tree, automatic log pickup and Sell; watch real backpack changes.
4. Enable Defend only after collecting works. Bosses stay OFF. Safety stays ON.
5. Compare baseline and RAM after 5-10 minutes. For rising memory, export DEBUG JSON and report measured usage at both times.

All cog source files are under 300 lines; no bundler is needed. `main.lua` pulls cog files from your repository. Runtime behavior requires in-game validation.
