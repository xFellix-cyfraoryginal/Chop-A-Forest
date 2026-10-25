-- Detect any real enemy by common replicated attributes, never by species/name.
return function(C)
    C.enemies = {}
    C.badEnemies = {}
    C.monsterFolder = C.ws:FindFirstChild("Monsters")
    local function registered(model)
        if not (model and model:IsA("Model")) then return false end
        if model.Parent ~= C.monsterFolder then return false end
        local mid, group = model:GetAttribute("MonsterId"), model:GetAttribute("Monster")
        local hp, cap = model:GetAttribute("HP"), model:GetAttribute("MaxHP")
        return mid ~= nil and type(group) == "string" and type(hp) == "number"
            and type(cap) == "number" and cap > 0
    end
    function C:enemyOK(model)
        return registered(model) and model:GetAttribute("HP") > 0
            and model:GetAttribute("State") ~= "Dead"
    end
    function C:enemyPos(model)
        if not registered(model) then return nil end
        local main = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        return main and main.Position or model:GetPivot().Position
    end
    local function watch(obj)
        if obj:IsA("Model") then C.enemies[obj] = true end
    end
    local function bindMonsterFolder(folder)
        C.monsterFolder = folder
        for _, obj in ipairs(folder:GetChildren()) do watch(obj) end
        C:connect(folder.ChildAdded, watch)
        C:connect(folder.ChildRemoved, function(obj)
            C.enemies[obj] = nil
            C.badEnemies[obj] = nil
        end)
    end
    if C.monsterFolder then bindMonsterFolder(C.monsterFolder)
    else
        C:connect(C.ws.ChildAdded, function(obj)
            if obj.Name == "Monsters" and obj:IsA("Folder") then bindMonsterFolder(obj) end
        end)
    end
    function C:pickEnemy(forceDefense)
        local from = self:pos()
        if not from then return nil end
        local best, bestScore
        local range = (forceDefense or self.config.combatMode == "Defend")
            and math.max(13, self.config.combatReach + 9) or self.config.combatSearch
        for mob in pairs(self.enemies) do
            if self:enemyOK(mob) and (self.badEnemies[mob] or 0) < os.clock()
                and (self.config.allowBoss or mob:GetAttribute("Monster") ~= "Guardian") then
                local biome = mob:GetAttribute("Biome")
                if not self.config.eventMobs or biome == "Graveyard" then
                    local p = self:enemyPos(mob)
                    local dist = p and (p - from).Magnitude or math.huge
                    if dist <= range and self:nearbyThreats(p, self.config.dangerRadius)
                        < self.config.maxThreats then
                        local score = dist
                        if mob:GetAttribute("Monster") == "Guardian" then score = score - 50 end
                        if not bestScore or score < bestScore then
                            best, bestScore = mob, score
                        end
                    end
                end
            end
        end
        return best
    end
    function C:fightEnemy(mob)
        if not self.running or self.safetyAlert or not self:enemyOK(mob) then return false end
        local _, root, hum = self:character()
        if not root or not hum then return false end
        local hp, cap = self:healthStatus()
        if hp <= self:panicFloor(cap) then
            self:raiseSafety("HP za niskie na walke")
            return false
        end
        local id = tostring(mob:GetAttribute("MonsterId"))
        local name = tostring(mob:GetAttribute("DisplayName") or mob.Name)
        local position = self:enemyPos(mob)
        if not position then return false end
        self.targetEnemy = mob
        self.stage = "Fight " .. name
        local from = self:pos()
        local to = from and (from - position) or Vector3.new(1, 0, 0)
        to = Vector3.new(to.X, 0, to.Z)
        if to.Magnitude < .2 then to = Vector3.new(1, 0, 0) end
        local approach = position + to.Unit * math.max(2.6, self.config.combatReach - 1.1)
        local ready = self:move(approach, 2.2)
        if not ready then self.targetEnemy = nil return false end
        self:chooseTool(self.config.combatTool)
        local failures, hits = 0, 0
        for _ = 1, 10 do
            if not self.running or not self.alive or self.safetyAlert
                or not self:enemyOK(mob) then break end
            _, root, hum = self:character()
            hp, cap = self:healthStatus()
            if not root or hp <= self:panicFloor(cap) then
                self:raiseSafety("HP spadlo podczas walki")
                break
            end
            position = self:enemyPos(mob)
            if not position then break end
            local distance = (root.Position - position).Magnitude
            if distance > self.config.combatReach + 1.0 then
                if not self:move(position, self.config.combatReach - 0.6) then break end
            end
            if self.safetyAlert or not self:enemyOK(mob) then break end
            -- Keep moving sideways (Walk), with a safe score for either orbit side.
            -- We do not teleport in the normal combat loop.
            if self.config.kiteEnabled and self.config.mode == "Walk"
                and (hits == 0 or hits % 2 == 0)
                and distance < self.config.combatReach + 1 then
                local orbit = self:circlePoint(mob, math.max(3.8,
                    self.config.combatReach - 1))
                if orbit then self:move(orbit,2.2) end
                if self.safetyAlert then break end
            end
            if self:nearbyThreats(root.Position, self.config.dangerRadius)
                >= self.config.maxThreats then
                self:raiseSafety("Walka z wieloma przeciwnikami")
                break
            end
            self:face(position + Vector3.new(0, .6, 0))
            task.wait(0.07)
            local hpBefore = mob:GetAttribute("HP")
            if not self:click() then
                self:note("error", "Brak metody click dla Auto Combat")
                break
            end
            local deadline = os.clock() + math.max(.48, self.config.combatDelay)
            local dealt = false
            while self.running and not self.safetyAlert and os.clock() < deadline do
                local now = mob:GetAttribute("HP")
                if type(now) == "number" and now < hpBefore then dealt = true; break end
                if mob.Parent ~= self.monsterFolder then break end
                task.wait(.07)
            end
            if dealt then
                self.stats.mobHits = self.stats.mobHits + 1
                self:note("hit", name .. " HP " .. tostring(hpBefore)
                    .. " -> " .. tostring(mob:GetAttribute("HP")))
                hits = hits + 1
                failures = 0
            else
                failures = failures + 1
                if failures >= 3 then break end
            end
        end
        -- Despawn alone is not a confirmed kill: require replicated Dead or zero HP.
        local finalHp = mob:GetAttribute("HP")
        local dead = (type(finalHp) == "number" and finalHp <= 0)
            or mob:GetAttribute("State") == "Dead"
        if dead then
            self.stats.mobKills = self.stats.mobKills + 1
            self:note("combat", "Pokonano " .. name .. " id=" .. id)
        else
            self.stats.combatFailures = self.stats.combatFailures + 1
            self.badEnemies[mob] = os.clock() + 6
            self:note("warn", "Brak potwierdzonego zabicia " .. name .. "; hity=" .. hits)
        end
        self.targetEnemy = nil
        return dead
    end
    function C:combatTick(forceDefense)
        if not self.config.autoCombat or not self.running then return false end
        local mob = self:pickEnemy(forceDefense)
        if not mob then return false end
        self:fightEnemy(mob)
        return true
    end

    local hi = Instance.new("Highlight")
    hi.Name = "CropForest_Combat_Target"
    hi.FillColor = Color3.fromRGB(247, 93, 82)
    hi.OutlineColor = Color3.fromRGB(255, 164, 101)
    hi.FillTransparency = .8
    hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hi.Parent = C.ws.CurrentCamera or C.ws
    table.insert(C.cleanup, function() hi:Destroy() end)
    local acc = 0
    C:connect(game:GetService("RunService").Heartbeat, function(dt)
        acc = acc + dt
        if acc < .45 then return end
        acc = 0
        local enemy = C.targetEnemy
        hi.Enabled = C.alive and C.config.showMobs and C.running and C:enemyOK(enemy)
        hi.Adornee = hi.Enabled and enemy or nil
    end)
end
