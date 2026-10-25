return function(C)
    function C:collectOne(log)
        local job=self.wood[log]
        if not job or job.done or not self:woodReady(log,job) then return false end
        if self.panic then return false end
        local have,cap=self:backpack()
        if not have or not cap or have>=cap then return false end
        local at=self:woodPosition(log)
        if not at then return false end
        self.stage='WOOD: approaching'
        if not self:goTo(at,self.cfg.pickupRange) then
            job.nextTry=os.clock()+2.5
            return false
        end
        if self.panic or log.Parent~=self.logsFolder then return false end
        self.stage='WOOD: collecting'
        local success=false
        for attempt=1,2 do
            if not self.running or self.panic or job.done then break end
            local before=self:backpack()
            if not before or before>=cap then break end
            local updatedAt=self:woodPosition(log)
            if updatedAt then at=updatedAt end
            local sent,reason=self:useItem(at,'Pickup')
            if not sent then
                self:note(reason or 'Could not trigger pickup')
                break
            end
            local deadline=os.clock()+.75
            while self.running and not self.panic and os.clock()<deadline do
                local after=self:backpack()
                if after and after>before then success=true; break end
                if log.Parent~=self.logsFolder then break end
                task.wait(.055)
            end
            if success or log.Parent~=self.logsFolder then break end
            if attempt==1 then
                local _,root=self:character()
                if root then
                    local direction=at-root.Position
                    if direction.Magnitude>2.4 then self:goTo(at,2.4) end
                end
            end
        end
        if success then
            job.done=true
            self.stats.collected=self.stats.collected+1
            self:note('Pickup confirmed by backpack')
            return true
        end
        -- Do NOT delete job on failed pickup or danger; retry later.
        job.failures=job.failures+1
        job.nextTry=os.clock()+math.min(22,2.5+job.failures*2)
        return false
    end
    function C:sellBag()
        local before,cap=self:backpack()
        if not before or before<1 then return false end
        if not self.sellSpot then
            self:note('SellSpot missing'); return false
        end
        self.stage='SELL: walking'
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
        while self.running and not self.panic and os.clock()<deadline do
            local after=self:backpack()
            if after and after<before then
                self.stats.sold=self.stats.sold+(before-after)
                self:note('Sold '..(before-after)..' logs')
                return true
            end
            task.wait(.09)
        end
        local ok=self:useItem(point,'Pickup')
        if ok then
            local endAt=os.clock()+1.2
            while self.running and not self.panic and os.clock()<endAt do
                local after=self:backpack()
                if after and after<before then
                    self.stats.sold=self.stats.sold+(before-after)
                    return true
                end
                task.wait(.08)
            end
        end
        self:note('Sell not confirmed (will retry)')
        return false
    end
end
