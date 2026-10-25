# Chop-A-Forest V4.8.2 — DepositPad one-second server-sync fix

PATCH ONLY over V4.8.1: replace **main.lua**, **cogs/collection.lua**, **cogs/scheduler.lua**. Keep all other files/cogs unchanged.

- Returned to the center of `DepositPad`, as in older versions; **stays there for one second** (both Instant TP and Walk).
- Instant TP holds actual avatar in place on the pad; disables work hover/air velocity while selling.
- No edge-only click that could make the HUD show 0/30 before the server clears inventory.
- **HUD 0/30 is not enough** to reopen collection. Confirm by server-side money/`Stat_CashEarned` growth and empty HUD/hand count. A cash-change event watcher catches payment even when an auto-upgrade spends it immediately.
- After one second the bot can go back to tree chopping. Pickup remains locked until sale is confirmed. If no credit arrives, it revisits the pad for another one-second attempt rather than spamming log pickup against server-side Bag Full.
- Boss, Claws upgrades, Walk, egg, backpack, movement and combat behavior unchanged.

Loader:
`loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.2"))()`

**Caution:** If money changes are never replicated, bot deliberately refuses pickups while an unconfirmed sale is pending. Check debug `SELL awaiting server credit` to diagnose, rather than treating a local 0/30 as proof.

Static Lua syntax checked; not run in live Roblox.
