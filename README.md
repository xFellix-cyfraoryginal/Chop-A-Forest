# Chop-A-Forest V4.8.4 — Restore ORIGINAL 9-second selling

PATCH ONLY over V4.8.3. Replace only `main.lua` and `cogs/collection.lua`. Keep all other cog files unchanged.

- Restores the older V4.8.0 DepositPad sale behavior: travel to real pad, stand there at least 9 seconds, allow 13.5 seconds for delayed server settlement.
- Restores one DepositPad click fallback after 2.1 seconds if the bag stays full (or returns to full after a HUD flicker). No repeated click spam; no fallback LMB while hand-carrying wood.
- Hold center position on the pad; disable tree/boss air hover for the entire sale.
- Confirm HUD 0 stays stable for at least 3.5 seconds after reaching zero and the 9-second minimum completes.
- Keep pickup locked while sale is unsettled; retry the pad, never treat a transient 0/30 as an instant empty bag.
- Retains the 4.8.3 close PumpkinHead, real-time trunk aim, boss air fight, free egg pickup, backpack and Claws upgrades.

Run after uploading/committing:
`loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.4"))()`

Only syntax + static checks; not tested in live Roblox.
