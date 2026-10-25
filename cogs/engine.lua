return function(C)
    function C:collectLogs()
        if not self.config.autoCollect then return end
        self.stage = "Collect"
        local stalled = {}
        for _ = 1, 14 do
            if not self.running then break end
            local count, max = self:backpack()
            if count and max and count >= max then break end
            local log = self:nearestLog(64)
            if not log then break end
            local part = self:logPart(log)
            if not part then break end
            if stalled[log] then
                local found
                for obj in pairs(self.drops) do
                    if not stalled[obj] and self:logPart(obj) then found = obj break end
                end
                if not found then break end
                log, part = found, self:logPart(found)
            end
            local before = count
            local reached = self:move(part.Position, 3.1)
            if not reached then stalled[log] = true end
            local deadline = os.clock() + 1.55
            local success = false
            while self.running and os.clock() < deadline do
                local now = self:backpack()
                if before and now and now > before then
                    self.stats.pickups = self.stats.pickups + (now - before)
                    success = true
                    break
                end
                if not log.Parent then
                    success = true
                    break
                end
                task.wait(0.1)
            end
            if not success then stalled[log] = true end
        end
    end
    function C:sellLogs()
        if not self.config.autoSell then return end
        local count = self:backpack()
        if not count or count <= 0 then return end
        local sellPos = self:sellPos()
        if not sellPos then
            self:note("error", "Nie znaleziono SellSpot")
            return
        end
        self.stage = "Sell"
        local reached = self:move(sellPos, 4)
        if not reached then
            self:note("warn", "Nie udalo sie dojsc do Sell")
            return
        end
        local deadline = os.clock() + 3
        while self.running and os.clock() < deadline do
            local countNow = self:backpack()
            if countNow == 0 then
                self.stats.sold = self.stats.sold + 1
                return
            end
            task.wait(0.15)
        end
        self:note("warn", "Sell nie potwierdzil depozytu")
    end
    function C:doTree(tree)
        self.stage = "Move to tree"
        self.target = tree
        if not self:moveToTree(tree) then
            self:note("warn", "Nie moge dojsc do drzewa")
            return false
        end
        self.stage = "Chop"
        self:chooseTool()
        local failures = 0
        local hits = 0
        while self.running and self:treeOK(tree) and hits < 42 do
            local p = self:trunk(tree)
            local root = self:pos()
            if not p or not root then return false end
            if (p.Position - root).Magnitude > math.max(6.5, self.config.hitDistance + 2) then
                if not self:moveToTree(tree) then return false end
            end
            if self:attackTree(tree) then
                failures = 0
            else
                failures = failures + 1
                if failures >= self.config.maxFailures then
                    self:note("warn", "Brak obrazen: drzewo pomijane")
                    return false
                end
            end
            hits = hits + 1
            task.wait(0.05)
        end
        if tree.Parent and (tree:GetAttribute("Felled") == true or (tree:GetAttribute("HP") or 1) <= 0) then
            self.stats.felled = self.stats.felled + 1
            return true
        end
        return false
    end
    function C:engine()
        while self.running and self.alive do
            local count, capacity = self:backpack()
            if self.config.autoSell and count and capacity and count >= capacity and self.config.sellWhenFull then
                self:sellLogs()
            else
                local tree = self:pickTree()
                if not tree then
                    self.stage = "No eligible trees"
                    self:note("warn", "Brak dostepnych drzew - sprawdz Area/Distance")
                    task.wait(2.5)
                    self.failedTrees = {}
                else
                    local good = self:doTree(tree)
                    if not good then
                        self.stats.failures = self.stats.failures + 1
                        self.failedTrees[tree] = (self.failedTrees[tree] or 0) + 1
                    else
                        self.failedTrees[tree] = nil
                        if self.config.autoCollect then
                            task.wait(0.32)
                            self:collectLogs()
                        end
                        if self.config.sellAfterTree then self:sellLogs() end
                    end
                end
            end
            task.wait(0.18)
        end
        self.target = nil
    end
end
