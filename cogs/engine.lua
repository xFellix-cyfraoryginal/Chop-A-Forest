-- Priority scheduler: emergency > full bag > remembered wood > combat > tree.
-- Wood jobs survive danger, missed clicks, movement failure, and incomplete chops.
return function(C)
    function C:doTree(tree)
        self.target=tree
        self.workTree=tree
        self.stage='Go tree'
        if not self:moveToTree(tree) then
            self.target=nil
            return false
        end
        self:chooseTool()
        local failures,swings=0,0
        self.stage='Chop'
        while self.running and not self.safetyAlert and self:treeOK(tree) and swings<45 do
            local part,p=self:trunk(tree),self:pos()
            if not part or not p then break end
            if (part.Position-p).Magnitude>math.max(6.5,self.config.hitDistance+2) then
                if not self:moveToTree(tree) then break end
            end
            if self.safetyAlert then break end
            if self:attackTree(tree) then failures=0
            else
                failures=failures+1
                if failures>=self.config.maxFailures then break end
            end
            swings=swings+1
            task.wait(.06)
        end
        self.target=nil
        local felled=tree.Parent and (tree:GetAttribute('Felled')==true
            or (tree:GetAttribute('HP') or 1)<=0)
        if felled then
            self.workTree=nil
            self.stats.felled=self.stats.felled+1
            self.lastFellAt=os.clock()
            self:note('tree','Scieto '..tostring(tree:GetAttribute('TreeId'))
                ..'; czekam na stabilne drewno')
            return true
        end
        return false
    end

    function C:engine(session)
        local nextIdleCheck=0
        while self.running and self.alive and session==self.sessionId do
            if self.safetyAlert then
                -- Do NOT clear woodJobs: pickup is resumed after recovery.
                self:retreatNow()
            else
                local bag,cap=self:backpack()
                if bag==nil then
                    self.stage='Wait HUD'; task.wait(.65)
                elseif self.config.autoSell and cap and bag>=cap and self.config.sellWhenFull then
                    self:sellLogs()
                else
                    local wood=self.config.autoCollect and self:woodStatus(self.config.maxLogDistance)
                    if wood and wood.ready>0 then
                        self.stage='Recover wood ('..wood.total..')'
                        local picked=self:collectLogs()
                        local after=self:backpack()
                        -- Sell only when full, or finished collecting all reachable wood.
                        local remaining=self:woodStatus(self.config.maxLogDistance)
                        if self.running and not self.safetyAlert and self.config.autoSell
                            and after and after>0 and (self.config.sellWhenFull and cap and after>=cap
                                or self.config.sellAfterTree
                                    and remaining.ready==0 and remaining.settling==0) then
                            self:sellLogs()
                        end
                        if picked==0 then task.wait(.25) end
                    elseif wood and wood.settling>0 then
                        -- Waiting has priority immediately after chopping and after retreat.
                        self.stage='Wait logs animation ('..wood.settling..')'
                        task.wait(.28)
                    elseif self.config.autoCombat and self.config.combatPriority=='Combat'
                        and self:combatTick(false) then
                        -- Optional hunting when no wood is waiting.
                    elseif self.config.autoCombat and self.config.combatPriority=='Threats'
                        and self:combatTick(true) then
                        -- Close-by enemies are handled before chopping more trees.
                    else
                        if self.config.autoSell and self.config.sellAfterTree and bag>0
                            and (not wood or wood.ready==0 and wood.settling==0)
                            and (os.clock()-(self.lastFellAt or -100)>1.5) then
                            self:sellLogs()
                        else
                            if self.config.kiteEnabled and self:tryAvoidCrowd() then
                                -- Side-step when mob blocks a safe route.
                            else
                                local tree=self.workTree
                                if tree then
                                    local part=self:trunk(tree)
                                    if not self:treeOK(tree) or not part
                                        or (self.blockedTrees[tree] or 0)>os.clock()
                                        or (self.locationRisk and self:locationRisk(part.Position)) then
                                        tree=nil
                                    end
                                end
                                tree=tree or self:pickTree()
                                if tree then
                                    local success=self:doTree(tree)
                                    if success then self.failedTrees[tree]=nil
                                    elseif not self.safetyAlert then
                                        self.workTree=nil
                                        self.stats.failures=self.stats.failures+1
                                        self.failedTrees[tree]=(self.failedTrees[tree] or 0)+1
                                        if self.failedTrees[tree]>=self.config.maxFailures then
                                            self.blockedTrees[tree]=os.clock()+45
                                            self.failedTrees[tree]=0
                                        end
                                    end
                                elseif self.config.autoCombat and self.config.combatMode=='Hunt'
                                    and self:combatTick(false) then
                                else
                                    self.stage='Waiting for safe task'
                                    task.wait(1)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(.16)
        end
        self.target=nil
        self.targetEnemy=nil
    end
end
