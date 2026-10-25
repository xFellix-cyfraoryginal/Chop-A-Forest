# Chop-A-Forest V4.7.8 — Backpack, Boss/Pumpkin, Claws MAX Tree Rush

Patch over V4.7.5 (the existing Walk Mode version). Replace ONLY listed Lua files.
Add cogs/backpack.lua, cogs/claws.lua and cogs/pumpkin.lua. Do not delete cogs/world.lua, cogs/collection.lua, cogs/survival.lua or cogs/dodge.lua.

- Auto buy: Backpack ONLY at Station_Backpack when cash >=90; server confirmation Up_GearBackpack > 0. No Axe/upgrade/endless purchases.
- Boss Jack: handled by existing MOB KILL scheduler. PumpkinHead: activated only when PumpkinChop ScreenGui.Enabled.
- Claws: recognize Tool=Claws, slot 3, use real observed equipment.
- Clawman Attack Speed max => tree-only rush. Gate: Up_ClawsSpeed >=6 OR corresponding 'Attack Speed' card price UI shows MAX/MAXED. No pickup/sell ONLY while gate true. Under max: existing pickup/sell pipeline. No guessing or buying speed levels.
- Independent FARM and MOBS buttons; Walk and Instant TP retained.
- Boss egg drops: not auto-collected until separate Egg Logger validates object and mechanism.

Load after GitHub commit:
loadstring(game:HttpGet('https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.7.8'))()

Test in Roblox; this patch was syntax-checked locally but NOT runtime verified.
