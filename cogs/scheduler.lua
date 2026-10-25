-- FARM + MOBS ONLY V4.7.4. Never opens purchase/upgrade/endless UI.
return function(C)
    C.eventSeen, C.eventPending = {}, {}
    function C:pendingEventMob()
        local chosenSkeleton,chosenPumpkin,chosenBoss=nil,nil,nil
        local skDist,pumpDist,bossDist=math.huge,math.huge,math.huge
        local pos=self:position()
        if not pos then return nil end
        for mob in pairs(self.enemies) do
            if not self.eventSeen[mob] and self:enemyValid(mob) then
                if self:isSkeleton(mob) or self:isPumpkinEnemy(mob)
                    or mob:GetAttribute('Monster')=='Guardian' then
                    self.eventSeen[mob]=true
                    self.eventPending[mob]=true
                end
            end
            if self.eventPending[mob] then
                if not self:enemyValid(mob) then
                    self.eventPending[mob]=nil
                elseif os.clock()>=(self.enemyRetry[mob] or 0) then
                    local p=self:enemyPosition(mob)
                    local d=p and (p-pos).Magnitude or math.huge
                    if self:isSkeleton(mob) and d<skDist then
                        chosenSkeleton,skDist=mob,d
                    elseif self:isPumpkinEnemy(mob) and d<pumpDist then
                        chosenPumpkin,pumpDist=mob,d
                    elseif mob:GetAttribute('Monster')=='Guardian' and d<bossDist then
                        chosenBoss,bossDist=mob,d
                    end
                end
            end
        end
        for mob in pairs(self.eventPending) do
            if not mob.Parent or not self:enemyValid(mob) then
                self.eventPending[mob]=nil
            end
        end
        return chosenSkeleton or chosenPumpkin or chosenBoss
    end
    function C:mobInterrupt()
        if not self.running or not self.cfg.combat
            or tostring(self.stage):find('COMBAT',1,true) then return false end
        return self:pendingEventMob()~=nil
    end
    function C:workStep()
        if self:isPaused() then
            self.stage='HP PAUSE: '..math.max(0,math.ceil(self.hpHoldUntil-os.clock()))..'s'
            task.wait(.18); return
        end
        if self.isDodging and self:isDodging() then
            self.stage='DODGE: warning active'
            task.wait(.06); return
        end
        -- No shop, upgrades, starter buying or round/endless automation.
        -- Kill a newly spawned/initial mob, then resume the wood pipeline.
        if self.cfg.combat then
            local mob=self:pendingEventMob()
            if mob then
                if self:isSkeleton(mob) then
                    self.stage='MOBS: skeleton first'
                elseif self:isPumpkinEnemy(mob) then
                    self.stage='MOBS: pumpkinling next'
                else
                    self.stage='MOBS: boss'
                end
                self:fight(mob)
                return
            end
        end
        if not self.cfg.farm then
            self.stage=self.cfg.combat and 'MOBS: waiting for spawn' or 'IDLE: both OFF'
            task.wait(.20)
            return
        end
        local bag,cap=self:backpack()
        if bag==nil then
            self.stage='WAIT: backpack HUD'; task.wait(.3); return
        end
        if self.cfg.sell and cap and bag>=cap then
            if not self:sellBag() then task.wait(.25) end
            return
        end
        local wood,ready=self:woodCounts()
        if self.cfg.collect and wood>0 then
            local log=self:chooseWood()
            if log then self:collectOne(log); return end
            -- All pending logs are either falling or on per-log retry.
            -- Harvest the next tree instead of idling for animations.
            -- Cap pending wood so we do not pile up dozens of logs.
            local backlogLimit=math.max(9, (cap or 5)*2)
            if bag<(cap or 5) and wood<backlogLimit then
                local nextTree=self:chooseTree()
                if nextTree then
                    self.stage='TREE: logs settling in background ('..wood..')'
                    self:chopTree(nextTree)
                    return
                end
            end
            -- If backlog is full or trees are absent, cash out carried wood.
            if self.cfg.sell and bag>0 then
                self:sellBag(); return
            end
            self.stage='WOOD: waiting/retry ('..wood..', ready '..ready..')'
            task.wait(.13); return
        end
        if self.cfg.sell and bag>0 then
            self:sellBag(); return
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
            task.wait(math.min(self.cfg.idlePause or .15, .045))
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
        self.lastHoldAt=-100; self.skyHoldPosition=nil; self.skyLanding=nil
        self.safeTree=nil; self.safeTreeUntil=0
        self.eventSeen,self.eventPending={},{}
        local session=self.session
        self.stage='STARTING'
        self:note('V4.7.4 FARM/MOBS: farm='..tostring(self.cfg.farm)
            ..', kill='..tostring(self.cfg.combat))
        task.spawn(function() self:watchSafety(session) end)
        task.spawn(function() self:workLoop(session) end)
    end
end
