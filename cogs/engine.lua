-- Main state-machine: tree -> confirmed pickup -> deposit, optionally fighting real monsters.
return function(C)
    function C:doTree(tree)
        self.stage = "Move to tree"
        self.target = tree
        if not self:moveToTree(tree) then
            self:note("warn", "Nie moge dojsc do drzewa")
            self.target = nil
            return false
        end
        self.stage = "Chop"
        self:chooseTool()
        local failures, swings = 0, 0
        while self.running and not self.safetyAlert and self:treeOK(tree) and swings < 45 do
            local part, root = self:trunk(tree), self:pos()
            if not part or not root then self.target = nil return false end
            if (part.Position - root).Magnitude > math.max(6.5, self.config.hitDistance + 2) then
                if not self:moveToTree(tree) then self.target = nil return false end
            end
            if self.safetyAlert then break end
            if self:attackTree(tree) then
                failures = 0
            else
                failures = failures + 1
                if failures >= self.config.maxFailures then
                    self:note("warn", "Drzewo bez obrazen; pomijam #" .. tostring(tree:GetAttribute("TreeId")))
                    self.target = nil
                    return false
                end
            end
            swings = swings + 1
            if not self.running or self.safetyAlert then break end
            task.wait(.06)
        end
        self.target = nil
        if tree.Parent and (tree:GetAttribute("Felled") == true or (tree:GetAttribute("HP") or 1) <= 0) then
            self.stats.felled = self.stats.felled + 1
            self:note("tree", "Scieto #" .. tostring(tree:GetAttribute("TreeId")))
            return true
        end
        return false
    end

    function C:engine(session)
        local lastRescue = 0
        while self.running and self.alive and session == self.sessionId do
            local bag, cap = self:backpack()
            if self.safetyAlert then
                self:retreatNow()
            elseif bag == nil then
                self.stage = "Waiting HUD"
                self:note("warn", "Czekam na ChopHud.Backpack.Count")
                task.wait(1)
            elseif self.config.autoSell and cap and bag >= cap and self.config.sellWhenFull then
                self:sellLogs()
            elseif self.config.autoCombat and self.config.combatPriority == "Combat"
                and self:combatTick(false) then
                -- Active combat/hunt mode gives the monster system priority.
            elseif self.config.autoCombat and self.config.combatPriority == "Threats"
                and self:combatTick(true) then
                -- Only nearby threats interrupt the normal wood loop.
            else
                local leftovers = self.config.autoCollect and self:nearestLog(40)
                if leftovers and os.clock() - lastRescue > 5 then
                    local before = bag
                    self:collectLogs()
                    lastRescue = os.clock()
                    local after = self:backpack()
                    if not self.safetyAlert and self.config.autoSell
                        and self.config.sellAfterTree and after and after > before then
                        self:sellLogs()
                    end
                else
                    local tree = self:pickTree()
                    if not tree then
                        if self.config.autoCombat and self.config.combatMode == "Hunt" then
                            if not self:combatTick(false) then
                                self.stage = "Waiting trees / enemies"
                                task.wait(1.5)
                            end
                        else
                            self.stage = "No eligible trees"
                            task.wait(1.7)
                        end
                        -- Keep failure history; do not retry one broken tree endlessly.
                    else
                        local success = self:doTree(tree)
                        if success then
                            self.failedTrees[tree] = nil
                            if self.config.autoCollect and not self.safetyAlert then
                                task.wait(.17)
                                if not self.safetyAlert then self:collectLogs() end
                            end
                            if self.config.autoSell and not self.safetyAlert then
                                local count, capacity = self:backpack()
                                if (self.config.sellAfterTree and count and count > 0)
                                    or (self.config.sellWhenFull and count and capacity and count >= capacity) then
                                    self:sellLogs()
                                end
                            end
                        else
                            if not self.safetyAlert then
                                self.stats.failures = self.stats.failures + 1
                                self.failedTrees[tree] = (self.failedTrees[tree] or 0) + 1
                                if self.failedTrees[tree] >= self.config.maxFailures then
                                    self.blockedTrees[tree] = os.clock() + 45
                                    self.failedTrees[tree] = 0
                                end
                            end
                        end
                    end
                end
            end
            task.wait(self.config.perfMode == "Eco" and .32 or .17)
        end
        self.target = nil
        self.targetEnemy = nil
    end
end
