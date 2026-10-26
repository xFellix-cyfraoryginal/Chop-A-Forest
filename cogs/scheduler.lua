-- V4.7.8: MOB interrupts + backpack only + pumpkin; Claws MAX tree rush.
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
        -- Fast run: clear skeletons and pumpkinlings BEFORE engaging Jack.
        -- If the Guardian actually resets, restore legacy boss-first focus.
        if self.cfg.bossOnly then return chosenBoss end
        if self.combatFallback and chosenBoss and
            (chosenBoss:GetAttribute('State')=='Fighting' or self.bossLock==chosenBoss) then
            self.bossLock=chosenBoss
            return chosenBoss
        end
        if self.bossLock and not self:enemyValid(self.bossLock) then
            self.bossLock=nil
        end
        return chosenSkeleton or chosenPumpkin or chosenBoss
    end
    function C:mobInterrupt()
        if not self.running or not self.cfg.combat
            or tostring(self.stage):find('COMBAT',1,true) then return false end
        return self:pendingEventMob()~=nil
    end
    function C:workStep()
        -- End-of-run UI is authoritative. After PumpkinHead, click Endless.
        if self.endlessStep and self:endlessStep() then return end
        if self.reconcileSale then self:reconcileSale() end
        if self:isPaused() then
            -- Heartbeat dodge remains active while the scheduler rests.
            self.stage='HP PAUSE: '..math.max(0,math.ceil(self.hpHoldUntil-os.clock()))..'s'
            task.wait(.18); return
        end
        if self.isDodging and self:isDodging() then
            self.stage='DODGE: warning active'
            task.wait(.06); return
        end
        -- Egg drops appear before the pumpkin bursts; use free PickPrompt.
        if self.cfg.combat and self.eggStep and self:eggStep() then return end
        -- Finish boss pumpkin before resuming normal combat/tree work.
        if self.cfg.combat and self.postBossStep and self:postBossStep() then return end
        -- Mob priority remains skeleton -> pumpkinling -> guardian.
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
            if self.cfg.bossOnly and self:pickBoss() then
                -- Boss exists but is temporarily on enemyRetry cooldown.
                -- Stay locked on him instead of switching to trees.
                self.stage='BOSS ONLY: waiting for next boss hit'
                task.wait(.075)
                return
            end
        end
        if not self.cfg.farm then
            self.stage=self.cfg.combat and 'MOBS: waiting for spawn' or 'IDLE: both OFF'
            task.wait(.20)
            return
        end
        -- Prevent pickup on a fake HUD 0/30 while server still says FULL.
        -- Between short pad visits, owned-backpack users may chop more trees
        -- but nobody may collect logs until cash credit confirms the sale.
        if self.salePending then
            local sale=self.salePending
            if os.clock()>=(sale.retryAt or 0) then
                self:sellBag()
            else
                local _,bagOwned=self:equipmentStatus()
                if bagOwned then
                    self.stage='SELL: server sync; chopping meanwhile'
                    local tree=self:chooseTree()
                    if tree then self:chopTree(tree) else task.wait(.1) end
                else
                    self.stage='SELL: hand carry awaiting server'
                    task.wait(.12)
                end
            end
            return
        end
        -- Only explicit MAX in the Clawman Attack Speed card (or lv 6)
        -- switches to TREE RUSH. Never collect/sell in this mode.
        if self.clawSpeedMax and self:clawSpeedMax() then
            local _,ownsBag,carry=self:equipmentStatus()
            local bag=self:backpack()
            if not ownsBag and math.max(carry or 0,bag or 0)>0 then
                self.stage='RUSH: emptying hands before trees-only mode'
                if self.cfg.sell then self:sellBag() else task.wait(.15) end
                return
            end
            local tree=self:chooseTree()
            if tree then
                self.stage='TREE RUSH: claws MAX (no pickup/sell)'
                self:chopTree(tree)
            else
                self.stage='TREE RUSH: waiting for trees'
                task.wait(.2)
            end
            return
        end
        -- Backpack is the only equipment auto-buy. Never visit the station
        -- while holding loose logs (E could throw them).
        if self.buyBackpackStep and self:buyBackpackStep() then return end
        local bag,cap=self:backpack()
        if bag==nil or not cap then
            self.stage='WAIT: bag HUD';task.wait(.12);return
        end
        local _,bagOwned,carried=self:equipmentStatus()
        local held=math.max(bag,carried or 0)
        local wood,ready=self:woodCounts()
        if not bagOwned then
            -- No real backpack: HUD 0/5 (or 0/10) is HAND CARRY.
            -- Prepare one full load on the ground before clicking any log.
            -- Once holding even one log, NEVER left-click a tree, because
            -- LMB then throws the entire carried pile.
            if held==0 and self.cfg.collect and wood<cap then
                local tree=self:chooseTree()
                if tree then
                    self.stage='HANDS: preparing logs ('..wood..'/'..cap..')'
                    self:chopTree(tree);return
                end
            end
            if held>0 and held>=cap and self.cfg.sell then
                self:sellBag();return
            end
            if self.cfg.collect and wood>0 then
                local log=self:chooseWood()
                if log then self:collectOne(log);return end
                if held>0 and self.cfg.sell and ready==0 then
                    self.handLogWaitSince=self.handLogWaitSince or os.clock()
                    -- Logs can take 2+ seconds to land. Do not sell 8/10
                    -- just because the last two are briefly falling.
                    if os.clock()-self.handLogWaitSince>3.0 then
                        self.handLogWaitSince=nil
                        self:sellBag();return
                    end
                else
                    self.handLogWaitSince=nil
                end
                self.stage='HANDS: waiting for remaining logs'
                task.wait(.09);return
            end
            if held>0 then
                if self.cfg.sell then self:sellBag() else
                    self.stage='HANDS: carrying; enable Sell to continue'
                    task.wait(.12)
                end
                return
            end
            if wood<cap then
                local tree=self:chooseTree()
                if tree then self:chopTree(tree);return end
            end
            self.stage='HANDS: waiting for full wood load'
            task.wait(.09);return
        end
        -- Owned backpack: normal collect/sell loop; sale visits pad for one second.
        if self.cfg.sell and bag>=cap then
            self:sellBag();return
        end
        if self.cfg.collect and wood>0 then
            local log=self:chooseWood()
            if log then self:collectOne(log);return end
            if bag<cap and wood<math.max(9,cap*2) then
                local nextTree=self:chooseTree()
                if nextTree then self:chopTree(nextTree);return end
            end
            if self.cfg.sell and bag>0 then self:sellBag();return end
            self.stage='WOOD: retry ('..wood..', ready '..ready..')'
            task.wait(.09);return
        end
        if self.cfg.sell and bag>0 then self:sellBag();return end
        local tree=self:chooseTree()
        if tree then self:chopTree(tree);return end
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
        self.bossLock=nil
        self.combatFallback=false
        self.bossResetWatch=nil
        self.cfg.dodge=true -- default warning dodge, except when Boss Rush is ON
        self:clearBossRushInterrupts()
        self.salePending=nil
        self.nextSellTry=0
        self.pickupUnblockAt=0
        self.handLogWaitSince=nil
        local session=self.session
        self.stage='STARTING'
        self:note('V4.8.7 BOSS RUSH + ENDLESS: farm='..tostring(self.cfg.farm)
            ..', kill='..tostring(self.cfg.combat))
        task.spawn(function() self:watchSafety(session) end)
        task.spawn(function() self:tryBuyClawsSpeed('start balance') end)
        task.spawn(function() self:workLoop(session) end)
    end
end
