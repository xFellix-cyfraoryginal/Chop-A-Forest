-- CropForest Auto Farm Alpha | GitHub loader | Luau only
-- Zmien TWOJ_LOGIN/CropForest-CS na swoj adres repozytorium.
local env = type(getgenv) == "function" and getgenv() or _G
local base = env.CROPFOREST_BASE_URL or "https://raw.githubusercontent.com/TWOJ_LOGIN/CropForest-CS/main/"
local modules = {
    "cogs/core.lua",
    "cogs/world.lua",
    "cogs/movement.lua",
    "cogs/attack.lua",
    "cogs/engine.lua",
    "cogs/esp.lua",
    "cogs/ui.lua",
}

assert(type(base) == "string", "CropForest: nieprawidlowy adres bazowy")
if base:find("TWOJ_LOGIN", 1, true) then
    error("CropForest: wpisz swoj login GitHub w main.lua lub ustaw getgenv().CROPFOREST_BASE_URL")
end
base = base:gsub("/+$", "") .. "/"
assert(type(loadstring) == "function", "CropForest: executor wymaga loadstring")

local function loadCog(path)
    local ok, result = pcall(function() return game:HttpGet(base .. path) end)
    if not ok or type(result) ~= "string" or result == "" then
        error("CropForest: blad pobierania " .. path .. ": " .. tostring(result))
    end
    local factory, compileError = loadstring(result)
    if not factory then
        error("CropForest: blad skladni " .. path .. ": " .. tostring(compileError))
    end
    local executed, module = pcall(factory)
    if not executed then
        error("CropForest: blad wykonania " .. path .. ": " .. tostring(module))
    end
    assert(type(module) == "function", "CropForest: cog nie zwrocil funkcji: " .. path)
    return module
end

local previous = env.CAF_ALPHA
if type(previous) == "table" and type(previous.unload) == "function" then
    pcall(previous.unload, previous)
end

local C = {}
local ok, errorText = pcall(function()
    for _, path in ipairs(modules) do
        loadCog(path)(C)
    end
end)
if not ok then
    if type(C.unload) == "function" then pcall(C.unload, C) end
    error("CropForest: nie udalo sie zaladowac Auto Farm: " .. tostring(errorText))
end

env.CAF_ALPHA = C
print("[CropForest] Auto Farm zaladowany: " .. base)
