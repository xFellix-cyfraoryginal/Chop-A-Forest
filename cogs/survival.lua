-- Survival V4.1: temporary health pause, no automatic retreat.
return function(C)
    C.panic, C.lastHP, C.lastDamageAt = false, nil, -100
    C.hpHoldUntil, C.retaliateUntil, C.lastHoldAt = 0, 0, -100
    C.pendingHold = false
    function C:threats(point, range)
        local count, closest, target = 0, math.huge, nil
        if not point then return count, closest, target end
        for mob in pairs(self.enemies) do
            if self:enemyValid(mob) then
                local pos = self:enemyPosition(mob)
                if pos then
                    local dist=(pos-point).Magnitude
                    if dist < closest then closest,target=dist,mob end
                    if dist <= range then count=count+1 end
                end
            end
        end
        return count,closest,target
    end
    -- Legacy safety test is deliberately disabled: wood and trees are never discarded.
    function C:isRiskPos(point) return false end
    function C:isPaused()
        return self.cfg.hpPause and os.clock() < self.hpHoldUntil
    end
    function C:urgentCombat()
        if not self.cfg.combat then return false end
        if os.clock() > self.retaliateUntil or self:isPaused() then return false end
        local count=self:threats(self:position(),18)
        return count>0
    end
    function C:watchSafety(session)
        local last = nil
        local healthScanAt=0
        while self.live and self.running and self.session == session do
            local now=os.clock()
            if (not self.healthLabel or not self.healthLabel.Parent) and now>healthScanAt then
                self:findHealthLabel(); healthScanAt=now+6
            end
            local hp,cap=self:health()
            local fraction=hp/math.max(cap,1)
            if last and hp < last - .05 then
                self.lastDamageAt=now
                self.retaliateUntil=now+self.cfg.retaliateSeconds
                local nearby=self:threats(self:position(),18)
                if nearby>0 and not self.stage:find('COMBAT',1,true)
                    and not self:isPaused() then
                    self:cancelMove()
                    self:note('Damage taken: retaliate if enemy nearby')
                end
                -- Do not freeze next to a hostile mob. Fight first, pause afterward.
                if self.cfg.hpPause and fraction<=self.cfg.pauseHP then
                    self.pendingHold=true
                end
            end
            if fraction>.65 or not self.cfg.hpPause then self.pendingHold=false end
            if self.pendingHold and not self:isPaused()
                and now-self.lastHoldAt>self.cfg.pauseSeconds+1 then
                local nearby=self:threats(self:position(),11)
                if nearby==0 then
                    self.pendingHold=false
                    self.lastHoldAt=now
                    self.hpHoldUntil=now+self.cfg.pauseSeconds
                    self:cancelMove()
                    self:note('HP PAUSE: '..self.cfg.pauseSeconds..'s ('..math.floor(hp)..' HP)')
                end
            end
            last=hp; self.lastHP=hp
            task.wait(.16)
        end
    end
end
