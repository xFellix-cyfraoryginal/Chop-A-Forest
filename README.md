# Chop-A-Forest V4.8.1 — Hands, Instant Sell, Boss Focus, Dodge, Speed

PATCH ONLY over V4.8.0. Upload only listed files, keep others untouched.

- `scheduler.lua`: with no Backpack, chop trees until at least HUD capacity logs are on the ground. Only then collect. If any logs are held, NEVER chop again until hands are emptied. For owned backpacks preserve ordinary collection. During active Guardian fight, prioritize Guardian over any other mob.
- `collection.lua`: V7 confirmed a mouse click on `DepositPad` triggers sale. Navigate beside nearest pad, aim and verify crosshair raycast, LMB once, then leave. Cash/bag confirms asynchronously (no 9-second pad dwell, no spamming). With hands occupied, cannot chop until sale is confirmed.
- `trees.lua`, `tools.lua`: duplicate hand-carry guard; quicker tree-to-tree transition and HP feedback.
- `combat.lua`: when Jack enters Fighting state, interrupt minion attack and engage Guardian exclusively; longer boss combat sessions, faster HP confirmation.
- `dodge.lua`: active MonsterFx red-zone dodging during HP sky shelter, updates sky-hold target instead of being snapped back.
- `navigation.lua`: Instant TP updates without 0.1 second of route dwell.
- `backpack.lua`: does not approach shop while carrying loose logs.
- `main.lua`: cache-busting version 4.8.1.

**Important**: Sale crosshair raycast is used to prevent a missed LMB dumping carried logs. If DepositPad is occluded, bot retries from adjusted position rather than clicking blind. Does not invent server remote methods. Server may reject clicks or enforce rate limits.

Run: `loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.1"))()`

Static Lua parse audit performed; **game runtime not tested**.
