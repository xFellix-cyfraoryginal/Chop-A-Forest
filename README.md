# Chop-A-Forest V4.7.9 — Automatic Claws Attack Speed after selling

PATCH ONLY over V4.7.8. Replace exactly: main.lua, cogs/core.lua,
cogs/claws.lua, cogs/scheduler.lua, cogs/ui.lua. Keep every other cog.

- One and only automatic upgrade: Clawman Attack Speed, enabled by default.
- Cost is read dynamically from Upgrades.Panel.Page2.Claws → Attack Speed → Price.Amount.
- When Clawman Attack Speed is selected in TAB, can also read Detail.Info.Buy.Row.Right.
- If UI price hasn't rendered, use V11 observed *level 0 only* cost 225;
  levels 1+ require UI price; never assume later prices.
- Following a cash payout from selling logs, check affordability immediately.
- Purchase using V11 confirmed outgoing remote name/argument:
  ReplicatedStorage.Shared.Services.ChopRemotes.BuyUpgrade:FireServer('ClawsSpeed').
- Verify server attribute Up_ClawsSpeed increases; continue to next level if funds allow.
- If server refuses, exponentially back off; no spam. V11 had 384 cash and
  repeated requests at cost 225, yet level stayed 0, so acceptance is unproven.
- Auto backpack still gets priority; NO Axe buying or other upgrades.
- Claws MAX continues Tree Rush mode, skipping log pickup and sale.
- Switch on panel: CLAW SPEED AUTO BUY ON/OFF; FARM, MOBS, WALK/TP unchanged.

Upload changed files to GitHub, commit, execute:
loadstring(game:HttpGet('https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.7.9'))()

Static parse checked, Roblox game execution not tested.
