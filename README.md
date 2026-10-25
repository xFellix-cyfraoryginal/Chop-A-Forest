# Chop-A-Forest V4.8.3 — Close Pumpkin / SellPad 3s / Live Trunk Aim

PATCH ONLY over V4.8.2. Replace exactly these FIVE files:
`main.lua`, `cogs/collection.lua`, `cogs/hover.lua`, `cogs/trees.lua`, `cogs/pumpkin.lua`.

- PumpkinHead: center of real hitbox/model + ~1 stud side offset, almost the **same Y**, continuously repositions in Instant TP; adjusts angle on misses. Does NOT hover above head. Walk mode approaches normally.
- Tree: both character facing and camera look at live trunk. The facing check is evaluated before a swing, and the final attack position is read AFTER weapon cooldown. No more stale aim during tree hops.
- SellPad: 3 continuous seconds physically on the DepositPad instead of 1 second. Keep V4.8.2 cash+bag confirmation gate.
- No change to Boss air orbit (Guardian), free Egg PickPrompt pickup, Auto Backpack, Claws Speed, Walk mode, or F6/F8.

Launcher:
`loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.3"))()`

This patch is statically syntax-checked only; not executed in live Roblox. Export pistol observations using separate `CropForest_Pistol_Weapon_Logger_V13_RAW.lua`, not part of GitHub repo.
