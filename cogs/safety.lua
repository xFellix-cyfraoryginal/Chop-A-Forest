-- CropForest Survival V3: independent risk watchdog + cautious escape/hold logic.
return function(C)
    C.safetyAlert = false
    C.safetyBusy = false
    C.lastDamageAt = -100
    C.lastDamageValue = 0
    C.safetyReason = nil

    function C:healthStatus()
        local _, _, hum = self:character()
        if not hum then return 0, 100 end
        local hp, cap = hum.Health, math.max(1, hum.MaxHealth)
        -- Prefer the smaller of replicated humanoid HP and a matching player HUD HP.
        local ui = self.healthText
        if ui and ui.Parent and ui:IsA("TextLabel") then
            local a, b = ui.Text:match("(%d+)%s*/%s*(%d+)")
            a, b = tonumber(a), tonumber(b)
            if a and b and b >= 20 and b <= 10000 and a <= b then
                if a / b < hp / cap then return a, b end
            end
        end
        return hp, cap
    end

    local function findHealthLabel()
        if not C.alive then return end
        local pg = C.player:FindFirstChild("PlayerGui")
        if not pg then return end
        local best, bestScore = nil, -1
        for _, child in ipairs(pg:GetDescendants()) do
            if child:IsA("TextLabel") then
                local a, b = child.Text:match("^%s*(%d+)%s*/%s*(%d+)%s*$")
                if a and b and tonumber(b) >= 20 then
                    local path = child:GetFullName():lower()
                    local score = (path:find("health") and 4 or 0)
                        + (path:find("hpbar") and 4 or 0)
                        + (path:find("hearthud") and 3 or 0)
                    if score > bestScore and score > 0 then
                        best, bestScore = child, score
                    end
                end
            end
        end
        C.healthText = best
    end
    task.defer(findHealthLabel)
    C:connect(C.player.CharacterRemoving, function()
        if C.running then C:stop() end
    end)
    C:connect(C.player.CharacterAdded, function()
        C.safetyAlert = false
        C.safetyBusy = false
        task.delay(1, findHealthLabel)
    end)

    function C:nearbyThreats(position, range)
        local count, nearest = 0, math.huge
        if not position then return count, nearest end
        for mob in pairs(self.enemies or {}) do
            if self:enemyOK(mob) then
                local p = self:enemyPos(mob)
                if p then
                    local d = (p - position).Magnitude
                    if d <= range then count = count + 1 end
                    if d < nearest then nearest = d end
                end
            end
        end
        return count, nearest
    end

    function C:locationRisk(position)
        if not self.config.avoidMobs then return false end
        return self:nearbyThreats(position, self.config.avoidDistance) > 0
    end

    function C:panicFloor(maxHP)
        return math.max(math.min(self.config.combatHealth, maxHP * 0.84),
            maxHP * self.config.panicPercent / 100)
    end

    function C:dangerReason()
        if not self.config.safetyOn or not self.running then return nil end
        local hp, maxHP = self:healthStatus()
        if hp <= 0 then return "Postac nie zyje" end
        local low = self:panicFloor(maxHP)
        if hp <= low then
            return string.format("HP %.0f/%.0f <= prog %.0f", hp, maxHP, low)
        end
        local pos = self:pos()
        if not pos then return nil end
        local count, closest = self:nearbyThreats(pos, self.config.dangerRadius)
        for mob in pairs(self.enemies or {}) do
            if self:enemyOK(mob) and mob:GetAttribute("Monster") == "Guardian"
                and not self.config.allowBoss then
                local mp = self:enemyPos(mob)
                if mp and (mp - pos).Magnitude < self.config.dangerRadius + 9 then
                    return "Boss za blisko - unikam"
                end
            end
        end
        if not self.config.autoCombat and closest < self.config.dangerRadius - 4 then
            return "Mob za blisko, Auto Combat wylaczony"
        end
        if count >= self.config.maxThreats then
            return "Otoczenie: " .. count .. " mobow w poblizu"
        end
        if os.clock() - self.lastDamageAt < 2.5 and closest < self.config.dangerRadius
            and hp < maxHP - 0.2 then
            return "Otrzymywanie obrazen przy mobie"
        end
        return nil
    end

    function C:raiseSafety(reason)
        if not self.running or self.safetyBusy or self.safetyAlert then return end
        self.safetyReason = reason
        self.safetyAlert = true
        self.motionToken = self.motionToken + 1
        self.targetEnemy = nil
        self.stage = "DANGER - retreat"
        self.stats.retreats = self.stats.retreats + 1
        self:note("danger", "ALARM: " .. reason)
        local _, root, hum = self:character()
        if root and hum then hum:MoveTo(root.Position) end
    end

    -- Prefer a known safe deposit zone; otherwise sample outward points and
    -- score their distance from every currently replicated living monster.
    function C:escapePoint()
        local origin = self:pos()
        if not origin then return nil end
        local sell = self:sellPos()
        if sell then
            local nearby, nearest = self:nearbyThreats(sell, self.config.dangerRadius + 8)
            if nearby == 0 and nearest >= self.config.safeDistance then
                return sell
            end
        end
        local center = Vector3.zero
        for mob in pairs(self.enemies or {}) do
            if self:enemyOK(mob) then
                local p = self:enemyPos(mob)
                if p and (p - origin).Magnitude < 55 then
                    local diff = origin - p
                    if diff.Magnitude > 0.2 then
                        center = center + diff.Unit / math.max(diff.Magnitude, 3)
                    end
                end
            end
        end
        if center.Magnitude < 0.001 then center = Vector3.new(1, 0, 0) end
        local angle = math.atan2(center.Z, center.X)
        local best, bestScore
        for i = 0, 11 do
            local theta = angle + i * (math.pi * 2 / 12)
            local offset = Vector3.new(math.cos(theta), 0, math.sin(theta))
            for _, radius in ipairs({32, 54}) do
                local candidate = origin + offset * radius
                local _, nearest = self:nearbyThreats(candidate, 100000)
                local score = math.min(nearest, 100) + offset:Dot(center.Unit) * 9
                    - radius * 0.09
                if not bestScore or score > bestScore then
                    best, bestScore = candidate, score
                end
            end
        end
        return best
    end

    function C:retreatNow()
        if not self.running or self.safetyBusy then return end
        self.safetyBusy = true
        local initialHP = self:healthStatus()
        if initialHP <= 0 then
            self.safetyBusy = false
            self:stop()
            self.stage = "STOP - dead"
            return
        end
        self.target = nil
        self.targetEnemy = nil
        local moved = false
        for attempt = 1, 3 do
            if not self.running then break end
            self.stage = "RETREAT " .. attempt .. "/3"
            local goal = self:escapePoint()
            if not goal then break end
            local oldMode = self.config.mode
            if self.config.escapeMode ~= "Match farm" then
                self.config.mode = self.config.escapeMode
            end
            local ok, reached = pcall(function() return self:move(goal, 4, true) end)
            self.config.mode = oldMode
            moved = ok and reached or moved
            local n = self:nearbyThreats(self:pos(), self.config.dangerRadius)
            if n == 0 then break end
            task.wait(.2)
        end
        if not moved then
            self:note("warn", "Ucieczka niepotwierdzona - serwer mogl cofnac TP")
            self.safetyBusy = false
            self:stop()
            self.stage = "STOP - escape failed"
            return
        end
        self.stage = "SAFE HOLD - healing"
        local deadline = os.clock() + self.config.healTimeout
        while self.running and os.clock() < deadline do
            local hp, maxHP = self:healthStatus()
            local n = self:nearbyThreats(self:pos(), self.config.dangerRadius)
            if hp >= maxHP * self.config.resumePercent / 100
                and hp >= math.min(self.config.combatHealth + 8, maxHP * 0.89)
                and n < self.config.maxThreats then
                self.safetyAlert = false
                self.safetyBusy = false
                self.stage = "Recovered - farm"
                self:note("safety", string.format("Wznowienie przy HP %.0f/%.0f", hp, maxHP))
                return
            end
            if n >= self.config.maxThreats then
                self:note("danger", "Moby dogonily retreat; STOP")
                break
            end
            task.wait(.3)
        end
        self.safetyBusy = false
        if self.running then
            self:note("danger", "Brak bezpiecznej regeneracji: AUTO FARM STOP. Uruchom recznie po wyleczeniu")
            self:stop()
            self.stage = "STOP - low HP / danger"
        end
    end

    local prevHealth
    task.spawn(function()
        while C.alive do
            task.wait(C.running and .14 or .7)
            if not C.alive then break end
            local hp = C:healthStatus()
            if type(hp) == "number" then
                if prevHealth and hp < prevHealth - 0.25 then
                    C.lastDamageAt = os.clock()
                    C.lastDamageValue = prevHealth - hp
                    C.stats.damageTaken = C.stats.damageTaken + (prevHealth - hp)
                end
                prevHealth = hp
            end
            if C.running and not C.safetyBusy and not C.safetyAlert then
                local reason = C:dangerReason()
                if reason then C:raiseSafety(reason) end
            end
        end
    end)
end
