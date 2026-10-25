-- V4.3: E first, mouse click fallback; confirmation is backpack delta.
return function(C)
    function C:collectOne(log)
        -- A HUD 0/30 is not proof the server cleared its bag.
        if self.salePending or os.clock()<(self.pickupUnblockAt or 0) then return false end
        local job=self.wood[log]
        if not job or job.done or not self:woodReady(log,job) then return false end
        if self:isPaused() or self:urgentCombat()
            or self:mobInterrupt() then return false end
        local _,bagOwned,carried=self:equipmentStatus()
        -- V9: without backpack, HUD is 0/5 and CarriedLogs counts 0..5.
        -- Continue collecting by hand; do not mistake 0/5 for owned backpack.
        local handMode=not bagOwned
        local have,cap=self:backpack()
        if not have or not cap or have>=cap then return false end
        local at=self:woodPosition(log)
        if not at then return false end
        self.stage='WOOD: approaching'
        if not self:goTo(at,self.cfg.pickupRange) then
            job.nextTry=os.clock()+2.5; return false
        end
        if self.setWorkHover then self:setWorkHover(log,true) end
        if self:isPaused() or self:urgentCombat() or log.Parent~=self.logsFolder then
            return false
        end
        self.stage='WOOD: E pickup'
        local success=false
        for attempt=1,2 do
            if not self.running or self:isPaused() or self:urgentCombat() or job.done
                or self:mobInterrupt() then break end
            local before=self:backpack()
            local oldCarry=self.player:GetAttribute('CarriedLogs') or 0
            if before==nil or before>=cap then break end
            local p=self:woodPosition(log)
            if p then at=p end
            -- With loose logs in hands, use a directed click first.
            -- Blind E can THROW already held logs when the target isn't found.
            local sent=self:useItem(at,handMode and 'PickupClick' or 'Pickup')
            if sent then
                local deadline=os.clock()+.30
                while self.running and not self:isPaused() and os.clock()<deadline do
                    local after=self:backpack()
                    local held=self.player:GetAttribute('CarriedLogs') or 0
                    if (after and after>before) or held>oldCarry then
                        success=true; break
                    end
                    if log.Parent~=self.logsFolder then break end
                    task.wait(.035)
                end
            end
            if success or log.Parent~=self.logsFolder then break end
            -- Avoid E while already carrying logs: it can throw them.
            self.stage='WOOD: click fallback'
            local ok=(not handMode) and self:useItem(at,'PickupClick') or false
            if ok then
                local deadline=os.clock()+.48
                while self.running and not self:isPaused() and os.clock()<deadline do
                    local after=self:backpack()
                    local held=self.player:GetAttribute('CarriedLogs') or 0
                    if (after and after>before) or held>oldCarry then
                        success=true; break
                    end
                    if log.Parent~=self.logsFolder then break end
                    task.wait(.045)
                end
            end
            if success or log.Parent~=self.logsFolder then break end
            if attempt==1 then self:goTo(at,2.5) end
        end
        if success then
            self.stats.collected=self.stats.collected+1
            -- E sometimes takes the NEAREST log, not necessarily our chosen
            -- log. Never discard the chosen one while it's still in Workspace.
            if log.Parent==self.logsFolder then
                job.nextTry=os.clock()+.5
                self:note('Pickup +1, target log still present; retry queued')
            else
                job.done=true
                self:note('E pickup confirmed')
            end
            return true
        end
        if log.Parent~=self.logsFolder then
            return true -- Model was removed, probably collected by somebody.
        end
        job.failures=job.failures+1
        job.nextTry=os.clock()+math.min(18,1.5+job.failures*1.5)
        self:note('Pickup failed; wood remains in queue')
        return false
    end
    -- V4.8.4: Restore the original V4.8.0 long-dwell DepositPad routine.
    -- Full 9 seconds minimum, up to 13.5 seconds for delayed settlement.
    -- If the bag does not start draining after 2.1 seconds, click the pad ONCE.
    -- Leave pickup locked on failed/uncertain sales, never trust a transient 0/30.
    local function readCash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local cash=stats and stats:FindFirstChild('Cash')
        return cash and tonumber(cash.Value) or nil
    end
    local function readEarned(self)
        return tonumber(self.player:GetAttribute('Stat_CashEarned'))
    end
    function C:findSellPad()
        local pads={}
        local function scan(where)
            if not where then return end
            for _,obj in ipairs(where:GetDescendants()) do
                if obj.Name=='DepositPad' and obj:IsA('BasePart') then
                    pads[#pads+1]=obj
                end
            end
        end
        scan(self.sellSpot)
        scan(self.map and self.map:FindFirstChild('SellIntakes'))
        local here=self:position()
        local best,distance=nil,math.huge
        for _,pad in ipairs(pads) do
            local d=here and (pad.Position-here).Magnitude or math.huge
            if d<distance then best,distance=pad,d end
        end
        return best
    end
    -- Scheduler from 4.8.2 calls this at the beginning of each workStep.
    -- Do NOT release the lock there: the full pad dwell owns settlement.
    function C:reconcileSale()
        return false
    end
    function C:sellBag()
        if not self.running or self:isPaused() then return false end
        local now=os.clock()
        local sale=self.salePending
        if sale and now<(sale.retryAt or 0) then return false end
        if not sale and now<(self.nextSellTry or 0) then return false end
        if not sale then
            local before=self:backpack()
            if not before or before<1 then return false end
            sale={before=before,at=now,visits=0,retryAt=0,
                cash=readCash(self),earned=readEarned(self)}
            self.salePending=sale
        end
        local pad=self:findSellPad()
        if not pad then
            sale.retryAt=os.clock()+2
            self:note('SELL: DepositPad missing (retry)')
            return false
        end
        if self.clearWorkHover then self:clearWorkHover() end
        if self.disableAirHold then self:disableAirHold() end
        if self.releaseMouse then self:releaseMouse() end
        self.stage='SELL: center of DepositPad'
        local point=pad.Position
        if not self:goTo(point,.65) then
            sale.retryAt=os.clock()+.7
            return false
        end
        sale.visits=sale.visits+1
        local started=os.clock()
        local deadline=started+13.5
        local firstZero=nil
        local lowest=sale.before
        local clicked=false
        local cashStart=readCash(self)
        local lastCash,lastCashAt=cashStart,started
        local lastCenter=started
        local standPos=self:ground(point) or (point+Vector3.new(0,3.15,0))
        local function finish(status,after,cash)
            self.sellAudit=self.sellAudit or {}
            local audit=self.sellAudit
            audit[#audit+1]={status=status,bagBefore=sale.before,
                bagAfter=after,cashBefore=sale.cash,cashAfter=cash,
                earnedBefore=sale.earned,earnedAfter=readEarned(self),
                seconds=math.floor((os.clock()-started)*10+.5)/10,
                visits=sale.visits,clicked=clicked}
            if #audit>20 then table.remove(audit,1) end
            self.stats.sold=self.stats.sold+sale.before
            self.salePending=nil
            self.pickupUnblockAt=os.clock()+.5
            self:note('SELL: 9s collector settled '..tostring(sale.before)
                ..' logs ('..status..')')
            return true
        end
        self.stage='SELL: original 9s dwell (max 13.5s)'
        while self.running and self.live and not self:isPaused()
            and not self:urgentCombat() and pad.Parent and os.clock()<deadline do
            local tick=os.clock()
            -- Stay physically on the pad; the tree air-hover MUST remain off.
            local _,root,hum=self:character()
            if not root then break end
            if self.cfg.move=='Instant TP' then
                if (root.Position-standPos).Magnitude>.8 then
                    root.CFrame=CFrame.new(standPos)*root.CFrame.Rotation
                end
                root.AssemblyLinearVelocity=Vector3.zero
            elseif hum and tick-lastCenter>=.35 then
                hum:MoveTo(standPos)
            end
            if tick-lastCenter>=.35 then lastCenter=tick end
            local after=self:backpack()
            if after then
                lowest=math.min(lowest,after)
                if after==0 then
                    firstZero=firstZero or tick
                else
                    firstZero=nil -- HUD zero flickered: not settled
                end
            end
            local cash=readCash(self)
            if cash and lastCash and cash~=lastCash then
                lastCashAt=tick
                lastCash=cash
            end
            -- Restored V4.8.0 fallback, also fixes 0->full HUD flicker.
            -- Recheck CURRENT count, not the lowest historical count.
            -- No click while carrying logs IN HANDS: LMB could throw them.
            if not clicked and tick-started>=2.1
                and after and after>=sale.before then
                clicked=true
                local _,ownsBag,carrying=self:equipmentStatus()
                if ownsBag or (carrying or 0)==0 then
                    self.stage='SELL: old Deposit click fallback'
                    self:useItem(point,'Deposit')
                else
                    self:note('SELL: keeping held wood safe; pad touch only')
                end
                self.stage='SELL: original 9s dwell (max 13.5s)'
            end
            if after==0 and firstZero and tick-started>=9.0
                and tick-firstZero>=3.5 and tick-lastCashAt>=1.2 then
                return finish('stable_9s',after,cash)
            end
            task.wait(.12)
        end
        local after=self:backpack()
        if after==0 and firstZero and os.clock()-firstZero>=3.5
            and os.clock()-started>=9.0 then
            return finish('stable_timeout',after,readCash(self))
        end
        -- If a transient HUD zero is not a real sale, do not allow pickup.
        -- The scheduler will retry the platform after a short backoff.
        sale.retryAt=os.clock()+.75
        self:note('SELL not settled ('..tostring(after)..'/'
            ..tostring(sale.before)..'); retrying old 9s pad')
        return false
    end
end
