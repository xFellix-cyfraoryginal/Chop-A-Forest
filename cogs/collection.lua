-- V4.3: E first, mouse click fallback; confirmation is backpack delta.
return function(C)
    function C:collectOne(log)
        local job=self.wood[log]
        if not job or job.done or not self:woodReady(log,job) then return false end
        if self:isPaused() or self:urgentCombat() then return false end
        local have,cap=self:backpack()
        if not have or not cap or have>=cap then return false end
        local at=self:woodPosition(log)
        if not at then return false end
        self.stage='WOOD: approaching'
        if not self:goTo(at,self.cfg.pickupRange) then
            job.nextTry=os.clock()+2.5; return false
        end
        if self:isPaused() or self:urgentCombat() or log.Parent~=self.logsFolder then
            return false
        end
        self.stage='WOOD: E pickup'
        local success=false
        for attempt=1,2 do
            if not self.running or self:isPaused() or self:urgentCombat() or job.done then break end
            local before=self:backpack()
            if not before or before>=cap then break end
            local p=self:woodPosition(log)
            if p then at=p end
            -- Try the interact key first. It doesn't trigger an axe animation.
            local sent=self:useItem(at,'Pickup')
            if sent then
                local deadline=os.clock()+.30
                while self.running and not self:isPaused() and os.clock()<deadline do
                    local after=self:backpack()
                    if after and after>before then success=true; break end
                    if log.Parent~=self.logsFolder then break end
                    task.wait(.035)
                end
            end
            if success or log.Parent~=self.logsFolder then break end
            -- If E wasn't handled by this game/executor, fall back to a click.
            self.stage='WOOD: click fallback'
            local ok=self:useItem(at,'PickupClick')
            if ok then
                local deadline=os.clock()+.48
                while self.running and not self:isPaused() and os.clock()<deadline do
                    local after=self:backpack()
                    if after and after>before then success=true; break end
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
    function C:sellBag()
        local before,cap=self:backpack()
        if not before or before<1 then return false end
        if not self.sellSpot then
            self:note('SellSpot missing'); return false
        end
        self.stage='SELL: approaching'
        local pad=self.sellSpot:FindFirstChild('DepositPad',true)
        local point=pad and pad:IsA('BasePart') and pad.Position
        if not point then
            local ok,p=pcall(function() return self.sellSpot:GetPivot().Position end)
            if ok then point=p end
        end
        if not point then return false end
        if not self:goTo(point,3.3) then return false end
        self.stage='SELL: depositing'
        local deadline=os.clock()+2.5
        while self.running and not self:isPaused() and not self:urgentCombat()
            and os.clock()<deadline do
            local after=self:backpack()
            if after and after<before then
                self.stats.sold=self.stats.sold+(before-after)
                self:note('Sold '..(before-after)..' logs')
                return true
            end
            task.wait(.09)
        end
        -- A regular click is the last fallback; E is reserved for LOG pickup.
        local ok=self:useItem(point,'Deposit')
        if ok then
            local untilAt=os.clock()+1.1
            while self.running and not self:isPaused() and os.clock()<untilAt do
                local after=self:backpack()
                if after and after<before then
                    self.stats.sold=self.stats.sold+(before-after)
                    return true
                end
                task.wait(.08)
            end
        end
        self:note('Sell not confirmed (retry later)')
        return false
    end
end
