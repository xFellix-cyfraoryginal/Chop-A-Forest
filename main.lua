-- Chop A Forest | SMART FARM V3.2 - release loader
-- Repo: https://github.com/xFellix-cyfraoryginal/Chop-A-Forest
-- Wgraj na GitHub main.lua ORAZ WSZYSTKIE PLIKI cogs/ z paczki V3.2.
local VERSION = "3.2"
local BASE = "https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/"
local CACHE_BUST = "?v=SmartFarm_3_2_20261025"
local COGS = {
    "cogs/core.lua",
    "cogs/world.lua",
    "cogs/movement.lua",
    "cogs/attack.lua",
    "cogs/settle.lua",
    "cogs/collect.lua",
    "cogs/combat.lua",
    "cogs/event.lua",
    "cogs/safety.lua",
    "cogs/tactics.lua",
    "cogs/camera.lua",
    "cogs/engine.lua",
    "cogs/esp.lua",
    "cogs/ui.lua",
}
assert(type(loadstring) == "function", "CropForest: executor wymaga loadstring")
local env = type(getgenv) == "function" and getgenv() or _G

print("[CropForest] Ladowanie Smart Farm V" .. VERSION .. " | 14 cogow")

-- Pobieramy wszystko najpierw: nie wylaczamy starej wersji, gdy repo jest niepelne.
local chunks = {}
for _, path in ipairs(COGS) do
    local ok, source = pcall(function()
        return game:HttpGet(BASE .. path .. CACHE_BUST)
    end)
    if not ok or type(source) ~= "string" or source == "" then
        error("CropForest V3.2: nie pobrano " .. path .. ". Wgraj caly folder cogs/ na GitHub. " .. tostring(source))
    end
    if path == "cogs/ui.lua" and not source:find("SMART FARM V3.2", 1, true) then
        error("CropForest V3.2: na GitHub nadal jest starsze cogs/ui.lua! Podmien CALY folder cogs/ i zrob Commit.")
    end
    local fn, reason = loadstring(source)
    if not fn then
        error("CropForest V3.2: blad skladni " .. path .. ": " .. tostring(reason))
    end
    chunks[#chunks + 1] = {path=path, fn=fn}
end

local old = env.CAF_ALPHA
if type(old) == "table" and type(old.unload) == "function" then
    pcall(old.unload, old)
end

local C = {}
local ok, err = pcall(function()
    for _, entry in ipairs(chunks) do
        local cog = entry.fn()
        assert(type(cog) == "function", "Cog nie zwrocil funkcji: " .. entry.path)
        cog(C)
    end
end)
if not ok then
    if type(C.unload) == "function" then pcall(C.unload, C) end
    error("CropForest V3.2: blad startu: " .. tostring(err))
end
C.version = VERSION
env.CAF_ALPHA = C
print("[CropForest] SMART FARM V3.2 uruchomiony")
