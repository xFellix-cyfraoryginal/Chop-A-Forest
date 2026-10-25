-- Chop-A-Forest | FARM + MOBS V4.7.8 | github.com/xFellix-cyfraoryginal/Chop-A-Forest
-- All Lua/Luau, no build step. Upload main.lua and cogs/ together.
local BASE = 'https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/'
local VERSION = '4.7.8'
local FILES = {
    'core', 'world', 'navigation', 'tools', 'claws', 'survival',
    'trees', 'collection', 'combat', 'dodge',
    'backpack', 'pumpkin', 'scheduler', 'ui'
}
local env = (type(getgenv) == 'function' and getgenv()) or _G
assert(type(loadstring) == 'function', '[CAF V4] Executor requires loadstring')
local sources = {}
for _, name in ipairs(FILES) do
    local url = BASE .. 'cogs/' .. name .. '.lua?caf=' .. VERSION
    local ok, source = pcall(function() return game:HttpGet(url) end)
    assert(ok and type(source) == 'string' and #source > 30,
        '[CAF V4] Could not fetch cogs/' .. name .. '.lua: ' .. tostring(source))
    local chunk, err = loadstring(source, '@cogs/' .. name .. '.lua')
    assert(chunk, '[CAF V4] Syntax error in ' .. name .. ': ' .. tostring(err))
    sources[#sources + 1] = {name = name, chunk = chunk}
end
-- Download and compile every cog BEFORE retiring the old script.
local old = env.CAF_V4 or env.CAF_ALPHA
if type(old) == 'table' and type(old.unload) == 'function' then
    pcall(function() old:unload() end)
end
local C = {version = VERSION}
local ok, err = pcall(function()
    for _, item in ipairs(sources) do
        local attach = item.chunk()
        assert(type(attach) == 'function', '[CAF V4] Broken cog: ' .. item.name)
        attach(C)
    end
end)
if not ok then
    if type(C.unload) == 'function' then pcall(function() C:unload() end) end
    error('[CAF V4] Start failed: ' .. tostring(err))
end
env.CAF_V4, env.CAF_ALPHA = C, C
print('[CAF V4] FARM + MOBS + BOSS ' .. VERSION .. ' ready (F8 = STOP)')
