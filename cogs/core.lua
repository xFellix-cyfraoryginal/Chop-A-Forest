return function(C)
    local P = game:GetService("Players")
    C.player = P.LocalPlayer
    C.ws = game:GetService("Workspace")
    C.rs = game:GetService("ReplicatedStorage")
    C.http = game:GetService("HttpService")
    C.uid = game:GetService("UserInputService")
    C.pathService = game:GetService("PathfindingService")
    C.config = {
        mode = "Walk", stepSpeed = 38, attackDelay = 0.68,
        attackMode = "Input", toolSlot = "2", hitDistance = 3.8,
        sellAfterTree = true, sellWhenFull = true,
        autoCollect = true, autoSell = true, goldFirst = false,
        showTree = true, showLogs = false, selectedArea = "Current",
        maxFailures = 3, maxTreeDistance = 220
    }
    C.alive = true
    C.running = false
    C.motionToken = 0
    C.logs = {}
    C.logLimit = 220
    C.stats = {felled = 0, pickups = 0, sold = 0, hits = 0, failures = 0}
    C.stage = "Idle"
    C.target = nil
    C.connections = {}
    C.cleanup = {}
    C.vis = {}
    C.failedTrees = {}
    C.remoteSeq = 0
    C.lastIssue = ""
    C.map = C.ws:FindFirstChild("Map")
    C.treeFolder = C.map and C.map:FindFirstChild("Trees")
    C.logFolder = C.ws:FindFirstChild("Logs")
    C.sell = C.map and C.map:FindFirstChild("SellSpot")
    C.remotes = C.rs:FindFirstChild("Shared")
    C.remotes = C.remotes and C.remotes:FindFirstChild("Services")
    C.remotes = C.remotes and C.remotes:FindFirstChild("ChopRemotes")
    function C:connect(signal, cb)
        local conn = signal:Connect(cb)
        table.insert(self.connections, conn)
        return conn
    end
    function C:note(level, message)
        local rec = {t = os.clock(), level = level, message = tostring(message)}
        table.insert(self.logs, rec)
        if #self.logs > self.logLimit then table.remove(self.logs, 1) end
        self.lastIssue = message
    end
    function C:character()
        local ch = self.player.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then return ch, root, hum end
        return nil
    end
    function C:pos()
        local _, root = self:character()
        return root and root.Position
    end
    function C:backpack()
        local pg = self.player:FindFirstChild("PlayerGui")
        local hud = pg and pg:FindFirstChild("ChopHud")
        local bag = hud and hud:FindFirstChild("Backpack")
        local label = bag and bag:FindFirstChild("Count")
        if label and label:IsA("TextLabel") then
            local a, b = label.Text:match("(%d+)%s*/%s*(%d+)")
            if a and b then return tonumber(a), tonumber(b) end
        end
        return nil, nil
    end
    function C:cash()
        local stats = self.player:FindFirstChild("leaderstats")
        local cash = stats and stats:FindFirstChild("Cash")
        return cash and cash.Value or nil
    end
    function C:stop()
        self.running = false
        self.motionToken = self.motionToken + 1
        self.stage = "Stopped"
        local _, _, hum = self:character()
        local pos = self:pos()
        if hum and pos then hum:MoveTo(pos) end
        self:note("info", "Zatrzymano")
    end
    function C:start()
        if self.running or not self.alive then return end
        if not self.treeFolder then self:note("error", "Brak Workspace.Map.Trees") return end
        self.running = true
        self:note("info", "Auto Farm uruchomiony")
        task.spawn(function()
            local ok, err = pcall(function() self:engine() end)
            if not ok then self:note("error", err) end
            self.running = false
            self.stage = "Idle"
        end)
    end
    function C:export()
        local data = {version = "Alpha 1", stats = self.stats, config = self.config,
            state = self.stage, problem = self.lastIssue, logs = self.logs,
            placeId = game.PlaceId, cash = self:cash()}
        local ok, payload = pcall(self.http.JSONEncode, self.http, data)
        if not ok then return false, payload end
        local name = "CropForest_AutoFarm_" .. os.date("!%Y%m%d_%H%M%S") .. ".json"
        if type(writefile) == "function" then
            local saved = pcall(writefile, name, payload)
            if saved then return true, name end
        end
        if type(setclipboard) == "function" then pcall(setclipboard, payload) return true, "Schowek" end
        return false, "Brak writefile / setclipboard"
    end
    function C:unload()
        self:stop()
        self.alive = false
        for _, conn in ipairs(self.connections) do pcall(function() conn:Disconnect() end) end
        for _, fn in ipairs(self.cleanup) do pcall(fn) end
        for _, v in pairs(self.vis) do pcall(function() v:Destroy() end) end
        if self.gui then self.gui:Destroy() end
        if self.espFolder then self.espFolder:Destroy() end
        local env = type(getgenv) == "function" and getgenv() or _G
        if env.CAF_ALPHA == self then env.CAF_ALPHA = nil end
    end
end
