# Chop-A-Forest V4.7 — Starter / Upgrade / Endless

Patch-only upload: copy only files from the ZIP to the same paths in the GitHub repo.

**Confirmed from V9 (passive logger):** Backpack $90 triggers station ProximityPrompt and raises `Up_GearBackpack` 0→1. Axe $75 triggers station prompt, then ToolStation stage, and sets `OwnsAxe=true`. Upgrades Speed and Sharpness cost $75 for level 1 and $125 for level 2, confirmed by `Up_AxeSpeed`/`Up_AxeSharp`.

**Confirmed from V10:** post-boss pumpkin part `Workspace.JackLantern.PumpkinHead`, player `PumpkinDamage`, and `PlayerGui.RunEnd.Stage.Endless`.

Automation uses simulated interaction with existing game UI, never guessed server remote arguments. Requires executor support for `VirtualInputManager` and/or input functions (`fireproximityprompt` can help with purchases). This code was statically checked but not run in Roblox; UI positions, game authority and timing may prevent successful actions.

The starter sequence is: hands/log pickup 0/5 → sell → Backpack 90 → Axe 75 → upgrades when affordable. During missing equipment, ATTACK-first skeleton searching is deferred for the necessary funds. Buying a backpack is an in-game currency purchase, not a Robux purchase. On failure it logs and retries, never declares a successful buy until corresponding attribute changes.

The Axe upgrade chooser is deliberately limited to Speed and Sharpness. Higher levels require the game's displayed price; unknown prices are never invented. F8 stops auto-farm. UI stays MAIN/TOOLS/DEBUG.
