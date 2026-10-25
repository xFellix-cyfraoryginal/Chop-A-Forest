-- V4.2: ATTACK sweeps all replicated monsters; FARM sweeps all trees.
return function(C)
    function C:workStep()
        if self:isPaused() then
            self.stage='HP PAUSE: '..math.max(0,math.ceil(self.hpHoldUntil-os.clock()))..'s'
            task.wait(.18); return
        end
        local bag,cap=self:backpack()
        if bag==nil then
            self.stage='WAIT: backpack HUD'; task.wait(.45); return
        end
        if self.cfg.priority=='ATTACK' and self.cfg.combat then
            local count=self:threats(self:position(),math.huge)
            if count>self.cfg.clearUntil then
                local enemy=self:pickEnemy(math.huge)
                if enemy then self:fight(enemy); return end
            end
        end
        -- Either mode retaliates when hit by a nearby remaining mob.
        if self:urgentCombat() then
            local enemy=self:pickEnemy(18)
            if enemy then self:fight(enemy); return end
        end
        if self.cfg.sell and cap and bag>=cap then
            if not self:sellBag() then task.wait(.25) end
            return
        end
        local wood,ready=self:woodCounts()
        if self.cfg.collect and wood>0 then
            local log=self:chooseWood()
            if log then self:collectOne(log); return end
            if ready==0 then
                local young=false
                for log,job in pairs(self.wood) do
                    if log.Parent==self.logsFolder and not job.done
                        and os.clock()-job.born<8 then young=true; break end
                end
                if young then
                    self.stage='WOOD: waiting for fall ('..wood..')'
                    task.wait(.30); return
                end
            end
        end
        -- Depositing a partial backpack does not require every log to be reachable.
        if self.cfg.sell and bag>0 then
            if not self:sellBag() then task.wait(.25) end
            return
        end
        local tree=self:chooseTree()
        if tree then self:chopTree(tree); return end
        local info=self.treeScan or {}
        if wood>0 then
            self.stage='WAIT: wood retry ('..wood..')'
        else
            self.stage=string.format('NO TREES: valid %d / tracked %d / blocked %d',
                info.valid or 0,info.cached or 0,info.blocked or 0)
            if (info.cached or 0)==0 then self:scanTrees(true) end
        end
        task.wait(.40)
    end
    function C:workLoop(session)
        while self.running and self.live and self.session==session do
            local ok,err=pcall(function() self:workStep() end)
            if not ok then
                self:note('ERROR: '..tostring(err))
                self:stop(); break
            end
            task.wait(self.cfg.idlePause)
        end
    end
    function C:start()
        if self.running or not self.live then return end
        if not self.treesFolder or not self.logsFolder then
            self:note('Missing Workspace.Map.Trees or Workspace.Logs'); return
        end
        self.running=true; self.session=self.session+1
        self.panic=false; self.lastHP=nil
        self.hpHoldUntil=0; self.retaliateUntil=0; self.pendingHold=false
        local session=self.session
        self.stage='STARTING'
        self:note('V4.2 GLOBAL '..self.cfg.priority..' FIRST / '..self.cfg.move)
        task.spawn(function() self:watchSafety(session) end)
        task.spawn(function() self:workLoop(session) end)
    end
end
