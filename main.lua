local env = type(getgenv) == "function" and getgenv() or _G
local fallbackBase = "https://raw.githubusercontent.com/TWOJ_LOGIN/TWOJE_REPO/main/"
local base = env.CROPFOREST_BASE_URL or fallbackBase
local modules = {
    "cogs/farm/core.lua",
    "cogs/farm/world.lua",
    "cogs/farm/movement.lua",
    "cogs/farm/attack.lua",
    "cogs/farm/engine.lua",
    "cogs/farm/esp.lua",
    "cogs/farm/ui.lua",
 }

if type(base) ~= "string" or base:find("TWOJ_LOGIN", 1, true) or base:find("TWOJE_REPO", 1, true) then
    error("CropForest: ustaw URL repozytorium w main.lua / combat_main.lua lub getgenv().CROPFOREST_BASE_URL")
end

base = base:gsub("/+$", "") .. "/"
if type(loadstring) ~= "function" then
    error("CropForest: executor nie udostepnia loadstring")
end

local function loadModule(path)
    local url = base .. path
    local fetched, source = pcall(function() return game:HttpGet(url) end)
    if not fetched or type(source) ~= "string" or #source == 0 then
        error("CropForest: nie udalo sie pobrac " .. path .. ": " .. tostring(source))
    end
    local compiled, compileError = loadstring(source)
    if not compiled then
        error("CropForest: blad skladni " .. path .. ": " .. tostring(compileError))
    end
    local evaluated, module = pcall(compiled)
    if not evaluated then
        error("CropForest: blad w " .. path .. ": " .. tostring(module))
    end
    if type(module) ~= "function" then
        error("CropForest: " .. path .. " nie zwrocil funkcji modulu")
    end
    return module
end

local previous = env.CAF_ALPHA
if type(previous) == "table" and type(previous.unload) == "function" then
    pcall(previous.unload, previous)
end

local C = {}
local success, failure = pcall(function()
    for _, path in ipairs(modules) do
        local module = loadModule(path)
        module(C)
    end
end)

if not success then
    if type(C.unload) == "function" then pcall(C.unload, C) end
    error("CropForest: nie udalo sie zaladowac modułów: " .. tostring(failure))
end

env.CAF_ALPHA = C
print("[CropForest] farm zaladowany z GitHub: " .. base)
