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
    -- V4.8.3: Stand ON DepositPad for three full seconds, then return to work.
    -- HUD 0/30 alone is NOT a server-confirmed sale. Never pick up new logs
    -- until a credit + empty bag is observed (avoids server-side Bag Full).
    local function readCash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local cash=stats and stats:FindFirstChild('Cash')
        return cash and tonumber(cash.Value) or nil,cash
    end
    local function earned(self)
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
    -- Listen for cash credits even if Auto Claws Speed immediately spends them.
    -- Install this listener ONCE; avoid one connection per sale.
    function C:watchSaleCredit()
        local _,cash=readCash(self)
        if not cash or self.saleCashObject==cash then return end
        self.saleCashObject=cash
        self:connect(cash:GetPropertyChangedSignal('Value'),function()
            if self.saleCashObject~=cash then return end
            local sale=self.salePending
            if not sale then return end
            local amount=tonumber(cash.Value)
            if amount and sale.lastCash and amount>sale.lastCash then
                sale.credited=true
            end
            sale.lastCash=amount
        end)
    end
    function C:reconcileSale()
        local sale=self.salePending
        if not sale then return false end
        local bag=self:backpack()
        local carrying=tonumber(self.player:GetAttribute('CarriedLogs')) or 0
        local cash=readCash(self)
        local totalEarned=earned(self)
        if cash and sale.cash and cash>sale.cash then sale.credited=true end
        if totalEarned and sale.earned and totalEarned>sale.earned then
            sale.credited=true
        end
        -- A zero counter without server credit is NOT confirmation.
        if sale.credited and bag==0 and carrying==0 then
            self.stats.sold=self.stats.sold+sale.before
            self.sellAudit=self.sellAudit or {}
            local audit=self.sellAudit
            audit[#audit+1]={status='paid_and_empty',bagBefore=sale.before,
                bagAfter=bag,cashBefore=sale.cash,cashAfter=cash,
                seconds=math.floor((os.clock()-sale.at)*10)/10,
                visits=sale.visits}
            if #audit>20 then table.remove(audit,1) end
            self.salePending=nil
            self.pickupUnblockAt=os.clock()+.25
            self:note('SELL server confirmed: '..sale.before..' logs')
            return true
        end
        return false
    end
    function C:sellBag()
        self:reconcileSale()
        local now=os.clock()
        local sale=self.salePending
        if sale and now<(sale.retryAt or 0) then return false end
        if not sale and now<(self.nextSellTry or 0) then return false end
        if not sale then
            local before=self:backpack()
            if not before or before<1 then return false end
            local cash=readCash(self)
            sale={at=now,before=before,cash=cash,lastCash=cash,
                earned=earned(self),credited=false,visits=0,retryAt=0}
            self.salePending=sale
        end
        self:watchSaleCredit()
        local pad=self:findSellPad()
        if not pad then
            self:note('SELL: DepositPad missing')
            sale.retryAt=os.clock()+2
            return false
        end
        -- V4.8.3 center-of-pad dwell is three seconds for server bag sync.
        -- On Instant TP clear air hold so the avatar physically stays on pad.
        self.stage='SELL: teleport to DepositPad'
        if self.clearWorkHover then self:clearWorkHover() end
        if self.disableAirHold then self:disableAirHold() end
        local point=pad.Position
        if not self:goTo(point,1.2) then
            sale.retryAt=os.clock()+.7
            return false
        end
        sale.visits=sale.visits+1
        local position=self:ground(point) or (point+Vector3.new(0,3.15,0))
        local endAt=os.clock()+3.0
        self.stage='SELL: standing on pad (3.0s)'
        while self.running and self.live and not self:isPaused()
            and pad.Parent and os.clock()<endAt do
            local _,root,hum=self:character()
            if not root then break end
            if self.cfg.move=='Instant TP' then
                -- Remain at pad center for full three seconds, not edge.
                if (root.Position-position).Magnitude>0.6 then
                    root.CFrame=CFrame.new(position)*root.CFrame.Rotation
                end
                root.AssemblyLinearVelocity=Vector3.zero
            elseif hum then
                hum:MoveTo(position)
            end
            self:reconcileSale()
            task.wait(.05)
        end
        self:reconcileSale()
        if self.salePending then
            sale.retryAt=os.clock()+.85
            if sale.visits==1 or sale.visits%3==0 then
                self:note('SELL awaiting server credit; will revisit pad ('
                    ..sale.visits..' visits)')
            end
        end
        return self.salePending==nil
    end
end
