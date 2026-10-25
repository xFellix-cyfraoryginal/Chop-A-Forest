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
    -- V4.8.1: V7 confirmed center-screen LMB targeting DepositPad
    -- resets held logs immediately. Never camp on the pad for 9 seconds.
    local function readCash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local cash=stats and stats:FindFirstChild('Cash')
        return cash and tonumber(cash.Value) or nil
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
    function C:reconcileSale()
        local sale=self.salePending
        if not sale then return false end
        local bag=self:backpack()
        local carrying=tonumber(self.player:GetAttribute('CarriedLogs')) or 0
        local cash=readCash(self)
        local cleared=(bag~=nil and bag<sale.before and
            (carrying==0 or (tonumber(self.player:GetAttribute('Up_GearBackpack')) or 0)>0))
        local paid=cash and sale.cash and cash>sale.cash
        if cleared or paid then
            local amount=math.max(0,sale.before-(bag or 0))
            self.stats.sold=self.stats.sold+amount
            self.sellAudit=self.sellAudit or {}
            local audit=self.sellAudit
            audit[#audit+1]={status=paid and 'paid' or 'bag_decreased',
                bagBefore=sale.before,bagAfter=bag,cashBefore=sale.cash,
                cashAfter=cash,seconds=math.floor((os.clock()-sale.at)*10)/10}
            if #audit>20 then table.remove(audit,1) end
            self.salePending=nil
            self:note('SELL confirmed: '..amount..' logs')
            return true
        end
        if os.clock()-sale.at>=1.3 then
            self.salePending=nil
            self.nextSellTry=os.clock()+1.2
            self:note('SELL not confirmed; will aim/click again')
        end
        return false
    end
    function C:sellBag()
        self:reconcileSale()
        if self.salePending or os.clock()<(self.nextSellTry or 0) then return false end
        local before=self:backpack()
        if not before or before<1 then return false end
        local pad=self:findSellPad()
        if not pad then self:note('DepositPad missing'); return false end
        local point=pad.Position
        local here=self:position()
        if not here then return false end
        local direction=Vector3.new(here.X-point.X,0,here.Z-point.Z)
        if direction.Magnitude<.1 then direction=Vector3.new(1,0,0) end
        -- V7: manual sale was confirmed from ~8 studs with rayHit DepositPad.
        -- Approach the PAD EDGE, do not stand on its center.
        -- If an obstacle blocked an earlier attempt, circle the edge.
        local angle=math.rad((self.sellApproachIndex or 0)*80)
        local unit=direction.Unit
        local edge=Vector3.new(unit.X*math.cos(angle)-unit.Z*math.sin(angle),0,
            unit.X*math.sin(angle)+unit.Z*math.cos(angle))
        local stand=point+edge*7.1
        self.stage='SELL: aim at deposit pad'
        if not self:goTo(stand,2) then return false end
        if not self.running or self:isPaused() or self:mobInterrupt() then return false end
        -- Without a backpack, a miss may throw the held logs. Verify the
        -- camera ray really sees the pad before sending a left-click.
        local cam=self.ws.CurrentCamera
        if not cam then return false end
        self:aimAt(point)
        local ray=cam.CFrame.LookVector
        local exclude={self.player.Character}
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=exclude
        local hit=self.ws:Raycast(cam.CFrame.Position,ray*28,params)
        if not (hit and (hit.Instance==pad or hit.Instance:IsDescendantOf(pad))) then
            self.sellApproachIndex=((self.sellApproachIndex or 0)+1)%4
            self.nextSellTry=os.clock()+.45
            self:note('SELL: pad not in crosshair; changing approach')
            return false
        end
        -- Direct input: useItem('Deposit') previously switched to Axe, which
        -- could invalidate the hand-carried state. This never switches tool.
        local sent=self:tap()
        if not sent then self:note('SELL: executor click failed'); return false end
        self.sellApproachIndex=0
        self.salePending={at=os.clock(),before=before,cash=readCash(self)}
        self.stage='SELL: clicked; returning to farm'
        -- No blocking server wait. Work loop checks payout in background.
        return true
    end
end
