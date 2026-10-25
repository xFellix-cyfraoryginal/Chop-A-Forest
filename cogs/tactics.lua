-- Active Walk movement around mobs instead of retreating at first sight.
return function(C)
    local lastStep = -100
    function C:circlePoint(mob, radius)
        local here, enemy = self:pos(), self:enemyPos(mob)
        if not here or not enemy then return nil end
        local diff = Vector3.new(here.X-enemy.X,0,here.Z-enemy.Z)
        if diff.Magnitude < .1 then diff=Vector3.new(1,0,0) end
        local tangent=Vector3.new(-diff.Z,0,diff.X).Unit
        local best, score
        for _, side in ipairs({1,-1}) do
            local direction = (diff.Unit*radius + tangent*side*self.config.kiteStep).Unit
            local candidate = enemy + direction*radius
            local near, nearest = self:nearbyThreats(candidate,20)
            local value = nearest - near*10
            if not score or value > score then best,score=candidate,value end
        end
        return best
    end
    function C:tryAvoidCrowd()
        if not self.running or self.safetyAlert or not self.config.kiteEnabled
            or self.config.mode ~= "Walk" or self.targetEnemy then return false end
        if os.clock()-lastStep < 2.2 then return false end
        local p=self:pos()
        if not p then return false end
        local nearest, nearD
        for mob in pairs(self.enemies or {}) do
            if self:enemyOK(mob) then
                local pt=self:enemyPos(mob)
                local d=pt and (pt-p).Magnitude or math.huge
                if d < self.config.kiteRadius and (not nearD or d<nearD) then
                    nearest,nearD=mob,d
                end
            end
        end
        if not nearest then return false end
        lastStep=os.clock()
        local goal=self:circlePoint(nearest, math.max(self.config.kiteRadius+2,
            self.config.orbitDistance+3))
        if goal then
            self.stage="Kiting around mobs"
            self:note("tactic","Obchodze moba w Walk ("..math.floor(nearD).." studs)")
            self:move(goal,2.1)
        end
        return true
    end
end
