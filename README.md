# Chop-A-Forest V4.7.4 — FARM + MOBS ONLY (PATCH)

Upgrade from V4.7.3 by uploading **main.lua** and the **six supplied cogs** (core, scheduler, trees, combat, tools, ui). Do not delete your old world/navigation/survival/collection/dodge files. This patch deliberately DOES NOT load cogs/starter.lua, cogs/upgrades.lua or cogs/endless.lua, even if they remain on GitHub.

Only three buttons: START/STOP (F6/F8), AUTO FARM ON/OFF, KILL MOBS ON/OFF. Default both on: chop -> collect -> sell, interrupted by newly spawned or initially present monsters. Skeletons first, Pumpkinlings second, Guardian boss last. Existing dodge/HP retreat still protect the character.

No Auto Buy axe/backpack, no Auto Upgrade, no shop UI click, no Endless click. Equipment is manually purchased/upgraded in the game. The script can chop with fists if no axe yet, but manually equipped Axe is recommended. When Farm OFF, it stops starting wood tasks; Kill Mobs can run independently. Finish an active sell transaction before another task to avoid bag desync.

After committing the changed files:
`loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.7.4"))()`

Local syntax and mock logic tests are not proof of in-game behavior; verify with your Roblox session.
