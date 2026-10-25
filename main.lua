-- Chop A Forest | Auto Farm Alpha
-- GitHub loader: nie wymaga ustawiania loginu ani getgenv().CROPFOREST_BASE_URL
-- Repozytorium: https://github.com/xFellix-cyfraoryginal/Chop-A-Forest
local BASE = "https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/"
local COGS = {
    "cogs/core.lua",
    "cogs/world.lua",
    "cogs/movement.lua",
    "cogs/attack.lua",
    "cogs/engine.lua",
    "cogs/esp.lua",
    "cogs/ui.lua",
}

assert(type(loadstring) == "function", "CropForest: executor musi obslugiwac loadstring")
local env = type(getgenv) == "function" and getgenv() or _G

local function loadCog(path)
    local url = BASE .. path
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(source) ~= "string" or source == "" then
        error("CropForest: nie mozna pobrac " .. path .. ". Sprawdz, czy repo jest publiczne i czy plik istnieje. " .. tostring(source))
    end
    local chunk, syntaxError = loadstring(source)
    if not chunk then
        error("CropForest: blad skladni " .. path .. ": " .. tostring(syntaxError))
    end
    local ran, cog = pcall(chunk)
    if not ran then
        error("CropForest: blad uruchomienia " .. path .. ": " .. tostring(cog))
    end
    assert(type(cog) == "function", "CropForest: cog nie zwrocil funkcji: " .. path)
    return cog
end

local previous = env.CAF_ALPHA
if type(previous) == "table" and type(previous.unload) == "function" then
    pcall(previous.unload, previous)
end

local C = {}
local success, message = pcall(function()
    for _, path in ipairs(COGS) do
        loadCog(path)(C)
    end
end)
if not success then
    if type(C.unload) == "function" then
        pcall(C.unload, C)
    end
    error("CropForest: blad uruchamiania Auto Farm: " .. tostring(message))
end

env.CAF_ALPHA = C
print("[CropForest] Auto Farm uruchomiony: " .. BASE)
