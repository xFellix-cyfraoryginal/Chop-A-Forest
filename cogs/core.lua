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
        showTree = false, showLogs = false, selectedArea = "Current",
        maxFailures = 3, maxTreeDistance = 220,
        pickupDistance = 4.6, pickupDelay = 0.32, pickupRetries = 3,
        autoCombat = false, combatMode = "Defend", combatPriority = "Threats",
        combatSearch = 75, combatReach = 5, combatDelay = 0.57,
        combatTool = "2", combatHealth = 65, showMobs = false,
        allowBoss = false, safetyOn = true, avoidMobs = true,
        panicPercent = 65, resumePercent = 90, maxThreats = 2,
        dangerRadius = 17, avoidDistance = 9, safeDistance = 26,
        escapeMode = "Instant TP", healTimeout = 30,
        eventOnly = false, eventMobs = false, perfMode = "Eco"
    }
    C.alive = true
    C.running = false
    C.workerAlive = false
    C.motionToken = 0
    C.logs = {}
    C.logLimit = 140
    C.sessionId = 0
    C.stats = {felled = 0, pickups = 0, sold = 0, hits = 0, failures = 0,
        mobHits = 0, mobKills = 0, combatFailures = 0, retreats = 0, damageTaken = 0}
    C.stage = "Idle"
    C.target = nil
    C.targetEnemy = nil
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
        self.sessionId = self.sessionId + 1
        self.running = false
        self.safetyAlert = false
        self.motionToken = self.motionToken + 1
        self.stage = "Stopped"
        self.targetEnemy = nil
        local _, _, hum = self:character()
        local pos = self:pos()
        if hum and pos then hum:MoveTo(pos) end
        self:note("info", "Zatrzymano")
    end
    function C:start()
        if self.running or not self.alive then return end
        if self.workerAlive then
            self:note("warn", "Poprzednia petla jeszcze sie zatrzymuje; sproboj ponownie")
            return
        end
        if not self.treeFolder then self:note("error", "Brak Workspace.Map.Trees") return end
        local hp, cap = self:healthStatus()
        if self.config.safetyOn and hp <= self:panicFloor(cap) then
            self:note("danger", "Nie uruchamiam farmy z tak niskim HP: " .. math.floor(hp))
            return
        end
        self.safetyAlert = false
        self.sessionId = self.sessionId + 1
        local session = self.sessionId
        self.running = true
        self.workerAlive = true
        self:note("info", "Auto Farm uruchomiony")
        task.spawn(function()
            local ok, err = pcall(function() self:engine(session) end)
            self.workerAlive = false
            if session ~= self.sessionId then return end
            if not ok then self:note("error", err) end
            self.running = false
            self.targetEnemy = nil
            self.stage = "Idle"
        end)
    end
    function C:export()
        local data = {version = "Survival V3.1 - Lite", stats = self.stats, config = self.config,
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
        -- Release our own strong references to world Instances and callback objects.
        for _, name in ipairs({"trees", "treeIndex", "treeCells", "treePositions",
            "drops", "enemies", "badEnemies", "vis", "failedTrees", "blockedTrees",
            "connections", "cleanup", "logs"}) do
            if type(self[name]) == "table" then table.clear(self[name]) end
        end
        local env = type(getgenv) == "function" and getgenv() or _G
        if env.CAF_ALPHA == self then env.CAF_ALPHA = nil end
    end
end
