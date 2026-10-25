-- V4.3: move to a monster-free tree before HP pause; sky shelter as fallback.
-- No mandatory "safe tree" blacklist: safety preference lasts only after retreat.
return function(C)
    local runService = game:GetService('RunService')
    C.lastHP, C.lastDamageAt = nil, -100
    C.hpHoldUntil, C.retaliateUntil, C.lastHoldAt = 0, 0, -100
    C.skyHoldPosition, C.skyLanding = nil, nil
    C.safeTree, C.safeTreeUntil = nil, 0

    function C:threats(point, range)
        local count, closest, target = 0, math.huge, nil
        if not point then return 0, closest, nil end
        for mob in pairs(self.enemies) do
            if self:enemyValid(mob) then
                local at = self:enemyPosition(mob)
                if at then
                    local d = (at-point).Magnitude
                    if d < closest then closest, target = d, mob end
                    if d <= (range or math.huge) then count = count + 1 end
                end
            end
        end
        return count, closest, target
    end

    -- Retain compatibility without rejecting valuable trees or logs.
    function C:isRiskPos(_) return false end
    function C:isPaused()
        return self.cfg.hpPause and os.clock() < self.hpHoldUntil
    end
    function C:urgentCombat()
        if not self.cfg.combat or self:isPaused() or self.cfg.priority=='ATTACK' then
            return false -- ATTACK FIRST ignores Pumpkinling retaliation; HP safety stays active.
        end
        if os.clock() > self.retaliateUntil then return false end
        local count = self:threats(self:position(), 18)
        return count > 0
    end

    function C:findSafeRetreat()
        local here = self:position()
        if not here then return nil, nil end
        self:scanTrees(true)
        local winner, bestPosition, bestScore = nil, nil, math.huge
        -- Every replicated tree is considered, not just a small local radius.
        for tree in pairs(self.trees) do
            if self:treeValid(tree) then
                local trunk = self:treePart(tree)
                if trunk then
                    local near, _, closestMob = self:threats(trunk.Position, 36)
                    if near == 0 then
                        local direction = here - trunk.Position
                        if closestMob then
                            local enemyPos = self:enemyPosition(closestMob)
                            if enemyPos then direction = trunk.Position-enemyPos end
                        end
                        direction = Vector3.new(direction.X,0,direction.Z)
                        if direction.Magnitude < .1 then direction=Vector3.new(1,0,0) end
                        local point = trunk.Position+direction.Unit*6
                        local danger, distance = self:threats(point, 24)
                        if danger == 0 then
                            local score=(point-here).Magnitude - math.min(distance,80)*.12
                            if score < bestScore then
                                winner, bestPosition, bestScore=tree,point,score
                            end
                        end
                    end
                end
            end
        end
        return bestPosition, winner
    end

    function C:enterSkyShelter()
        local _,root=self:character()
        if not root then return false end
        local old=root.Position
        self.skyLanding=self:ground(old) or old
        self.skyHoldPosition=Vector3.new(old.X,old.Y+65,old.Z)
        self.safeTree,self.safeTreeUntil=nil,0
        root.CFrame=CFrame.new(self.skyHoldPosition)*root.CFrame.Rotation
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        self.stage='HP HOLD: sky shelter'
        return true
    end

    function C:beginHPHold(hp)
        if not self.running or not self.cfg.hpPause then return end
        local now = os.clock()
        if self:isPaused() or now-self.lastHoldAt < self.cfg.pauseSeconds+3 then return end
        self:cancelMove() -- Cancels previous chase/tree/navigation immediately.
        self.hpHoldUntil=now+self.cfg.pauseSeconds
        self.lastHoldAt=now
        self.retaliateUntil=0
        self.safeTree, self.safeTreeUntil=nil,0
        self.skyHoldPosition, self.skyLanding=nil,nil
        local spot,tree=self:findSafeRetreat()
        local _,root=self:character()
        if not root then return end
        if spot then
            local ground=self:ground(spot) or spot
            root.CFrame=CFrame.new(ground)*root.CFrame.Rotation
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            self.safeTree,self.safeTreeUntil=tree,now+36
            self.stage='HP HOLD: quiet forest'
            self:note('Retreat to quiet tree, '..math.floor(hp)..' HP')
        else
            self:enterSkyShelter()
            self:note('No quiet trees found: sky shelter ('..math.floor(hp)..' HP)')
        end
        self.stats.retreats=self.stats.retreats+1
    end

    C:connect(runService.Heartbeat,function()
        local target=C.skyHoldPosition
        if not target then return end
        if not C.live or not C.running then
            C.skyHoldPosition=nil
            return
        end
        if not C:isPaused() then
            -- Bring the character back onto terrain; avoid a 65-stud fall.
            local _,root=C:character()
            if root and C.skyLanding then
                root.CFrame=CFrame.new(C.skyLanding)*root.CFrame.Rotation
                root.AssemblyLinearVelocity=Vector3.zero
            end
            C.skyHoldPosition,C.skyLanding=nil,nil
            return
        end
        local _,root=C:character()
        if root then
            root.CFrame=CFrame.new(target)*root.CFrame.Rotation
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        end
    end)

    function C:watchSafety(session)
        local last, scanAt = nil, 0
        while self.live and self.running and self.session==session do
            local now=os.clock()
            if (not self.healthLabel or not self.healthLabel.Parent) and now>=scanAt then
                self:findHealthLabel(); scanAt=now+6
            end
            local hp,cap=self:health()
            local fraction=hp/math.max(cap,1)
            if last and hp < last-.05 then
                self.lastDamageAt=now
                self.retaliateUntil=now+self.cfg.retaliateSeconds
                local mobCount=self:threats(self:position(),18)
                if mobCount>0 and self.cfg.priority~='ATTACK' and not self:isPaused()
                    and not self.stage:find('COMBAT',1,true) then
                    self:cancelMove()
                end
            end
            -- If monsters followed us to a supposedly quiet tree, escape
            -- again without restarting the HP timer or abandoning the farm.
            if self:isPaused() and self.safeTree and not self.skyHoldPosition then
                local near=self:threats(self:position(),14)
                if near>0 and self:enterSkyShelter() then
                    self:note('Monster entered shelter; moved to sky')
                end
            end
            -- Never wait for monsters to leave before retreating.
            if self.cfg.hpPause and hp>0 and fraction<=self.cfg.pauseHP then
                self:beginHPHold(hp)
            end
            last=hp; self.lastHP=hp
            task.wait(.12)
        end
    end
end
