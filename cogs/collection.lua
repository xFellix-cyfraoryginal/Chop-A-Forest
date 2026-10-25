-- V4.3: E first, mouse click fallback; confirmation is backpack delta.
return function(C)
    function C:collectOne(log)
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
    -- Sell is not complete just because the HUD briefly displays 0/5.
    -- Stay on the actual pad long enough for delayed server settlement.
    local function readCash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local cash=stats and stats:FindFirstChild('Cash')
        return cash and type(cash.Value)=='number' and cash.Value or nil
    end
    function C:sellBag()
        local before=self:backpack()
        if not before or before<1 then return false end
        if not self.sellSpot then self:note('SellSpot missing'); return false end
        local pad=self.sellSpot:FindFirstChild('DepositPad',true)
        local point=pad and pad:IsA('BasePart') and pad.Position
        if not point then
            local ok,p=pcall(function() return self.sellSpot:GetPivot().Position end)
            if ok then point=p end
        end
        if not point then return false end
        self.stage='SELL: center of pad'
        if not self:goTo(point,.65) then return false end
        local started=os.clock()
        local deadline=started+13.5
        local firstZero,lowest=nil,before
        local clickTried=false
        local cashStart=readCash(self)
        local lastCash,lastCashAt=cashStart,started
        local lastRecenter=started
        -- Keep a small audit to diagnose apparent log duplication / HUD rollbacks.
        local function audit(status,endingBag,endingCash)
            self.sellAudit=self.sellAudit or {}
            local entries=self.sellAudit
            entries[#entries+1]={status=status,bagBefore=before,bagAfter=endingBag,
                cashBefore=cashStart,cashAfter=endingCash,
                seconds=math.floor((os.clock()-started)*10+.5)/10}
            if #entries>20 then table.remove(entries,1) end
        end
        self.stage='SELL: waiting for server'
        while self.running and not self:isPaused() and not self:urgentCombat()
            and os.clock()<deadline do
            local now=os.clock()
            local after=self:backpack()
            if after then
                lowest=math.min(lowest,after)
                if after==0 then
                    firstZero=firstZero or now
                else
                    -- A transient 0 is NOT a completed sale.
                    firstZero=nil
                end
            end
            local cash=readCash(self)
            if cash and lastCash and cash~=lastCash then
                lastCashAt=now
                lastCash=cash
            end
            -- Some servers require a click on the pad; try it once only
            -- if standing there did not change the inventory at all.
            if not clickTried and now-started>=2.1 and lowest>=before then
                clickTried=true
                self.stage='SELL: activating pad'
                self:useItem(point,'Deposit')
                self.stage='SELL: waiting for server'
            end
            -- On physics corrections, return to the center. Do not walk out
            -- of the deposit region while the bag is being settled.
            if now-lastRecenter>=.35 then
                lastRecenter=now
                local _,root=self:character()
                if root then
                    local horizontal=(Vector3.new(root.Position.X,0,root.Position.Z)
                        -Vector3.new(point.X,0,point.Z)).Magnitude
                    if horizontal>2.0 then
                        self.stage='SELL: holding deposit pad'
                        self:goTo(point,.65)
                        self.stage='SELL: waiting for server'
                    end
                end
            end
            if after==0 and firstZero and now-started>=9.0
                and now-firstZero>=3.5 and now-lastCashAt>=1.2 then
                audit('bag_stable',after,cash)
                self.stats.sold=self.stats.sold+before
                if cashStart and cash and cash<=cashStart then
                    self:note('Bag stable 0; cash payout not yet verified')
                else
                    self:note('Sell stabilized: '..before..' logs')
                end
                return true
            end
            task.wait(.12)
        end
        local after=self:backpack()
        if after==0 and firstZero and os.clock()-firstZero>=3.5 then
            audit('bag_stable_timeout',after,readCash(self))
            self.stats.sold=self.stats.sold+before
            self:note('Bag still 0 after sell dwell; cash may settle later')
            return true
        end
        audit(self.running and 'not_settled' or 'interrupted',after,readCash(self))
        self:note('Sell NOT settled: '..tostring(after)..'/'..tostring(before)
            ..' (will retry; no forced inventory reset)')
        return false
    end
end
