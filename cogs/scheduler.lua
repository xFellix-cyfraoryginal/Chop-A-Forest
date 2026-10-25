-- V4.4: pending wood is harvested in a pipeline; sale dwell is synchronized.
return function(C)
    function C:workStep()
        if self:isPaused() then
            self.stage='HP PAUSE: '..math.max(0,math.ceil(self.hpHoldUntil-os.clock()))..'s'
            task.wait(.18); return
        end
        if self.isDodging and self:isDodging() then
            self.stage='DODGE: warning active'
            task.wait(.06); return
        end
        if self:postBossStep() then return end
        local bag,cap=self:backpack()
        local axe,boughtBag=self:equipmentStatus()
        local setup=not axe or not boughtBag
        self.starterFarming=setup
        if setup and self.cfg.autoBuy then
            if self:starterStep() then return end
        end
        if bag==nil then
            self.stage='WAIT: backpack HUD'; task.wait(.45); return
        end
        if not setup and self.cfg.priority=='ATTACK' and self.cfg.combat then
            -- ALWAYS chase a live Gravedigger/Skeleton, including the last
            -- one. When none are present, farm trees to progress the event.
            -- Do not divert to Biters/Pumpkinlings or the Guardian boss.
            local skeleton=self:pickSkeleton()
            if skeleton then
                self.stage='EVENT: hunting skeleton'
                self:fight(skeleton)
                return
            end
            self.stage='EVENT: no skeletons; clearing trees'
        end
        -- FARM FIRST still defends itself if hurt. ATTACK FIRST strictly
        -- skips pumpkin enemies, even when they are close to the character.
        if self.cfg.priority~='ATTACK' and self:urgentCombat() then
            local enemy=self:pickEnemy(18)
            if enemy then self:fight(enemy); return end
        end
        if self.cfg.sell and cap and bag>=cap then
            if not self:sellBag() then task.wait(.25) end
            return
        end
        -- Right after an HP retreat, briefly prioritize a safe tree over
        -- dangerous old pickup locations. The wood registry stays intact.
        local hp,maxHP=self:health()
        if self.cfg.priority=='FARM' and hp/math.max(maxHP,1)<.66
            and self.safeTree and os.clock()<(self.safeTreeUntil or 0)
            and self:treeValid(self.safeTree) then
            self.stage='TREE: quiet-area recovery'
            self:chopTree(self.safeTree)
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
        if not setup and self.cfg.autoUpgrade and self:upgradeStep() then return end
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
        local axe,boughtBag=self:equipmentStatus()
        if not axe or not boughtBag then
            self:note('Starter mode: farm hands -> Backpack $90 -> Axe $75')
        end
        self.running=true; self.session=self.session+1
        self.panic=false; self.lastHP=nil
        self.hpHoldUntil=0; self.retaliateUntil=0; self.pendingHold=false
        self.lastHoldAt=-100; self.skyHoldPosition=nil; self.skyLanding=nil
        self.safeTree=nil; self.safeTreeUntil=0
        local session=self.session
        self.stage='STARTING'
        self:note('V4.7 STARTER AUTO BUY '..self.cfg.priority..' / '..self.cfg.move)
        task.spawn(function() self:watchSafety(session) end)
        task.spawn(function() self:workLoop(session) end)
    end
end
