return function(C)
    C.panic, C.lastHP, C.lastDamageAt = false, nil, -100
    function C:threats(point, range)
        local count, closest = 0, math.huge
        local danger = nil
        if not point then return count, closest, danger end
        for enemy in pairs(self.enemies) do
            if self:enemyValid(enemy) then
                local at=self:enemyPosition(enemy)
                if at then
                    local d=(at-point).Magnitude
                    if d<closest then closest,danger=d,enemy end
                    if d<range then count=count+1 end
                end
            end
        end
        return count, closest, danger
    end
    function C:isRiskPos(point)
        if self.cfg.style=='Aggressive' then return false end
        local radius=self.cfg.style=='Safe' and 12 or 7.5
        local n=self:threats(point,radius)
        return n>0
    end
    function C:watchSafety(session)
        local last=self.lastHP
        local nextHealthSearch=0
        while self.live and self.running and self.session==session do
            if (not self.healthLabel or not self.healthLabel.Parent)
                and os.clock()>nextHealthSearch then
                self:findHealthLabel(); nextHealthSearch=os.clock()+5
            end
            local hp,maxHP=self:health()
            local current=hp/math.max(maxHP,1)
            local point=self:position()
            local count, distance=self:threats(point,6)
            if last and hp < last-1 then self.lastDamageAt=os.clock() end
            last=hp; self.lastHP=hp
            -- Proximity alone should not cause endless retreats.
            local dangerous=current<self.cfg.minHP or hp<=0
                or (count>=2 and distance<4.5)
                or (current < .76 and os.clock()-self.lastDamageAt<1.5 and distance<8)
            if dangerous and not self.panic then
                self.panic=true
                self:cancelMove()
                self:note('DANGER: retreating (HP '..math.floor(hp)..')')
            end
            task.wait(.20)
        end
    end
    function C:retreatPoint()
        local point=self:position()
        if not point then return nil end
        local away=Vector3.new(0,0,0)
        for enemy in pairs(self.enemies) do
            if self:enemyValid(enemy) then
                local pos=self:enemyPosition(enemy)
                if pos then
                    local offset=point-pos
                    local dist=offset.Magnitude
                    if dist<45 and dist>.1 then
                        away=away+offset.Unit*(45-dist)/math.max(dist,2)
                    end
                end
            end
        end
        if away.Magnitude<.1 then away=Vector3.new(0,0,-1) end
        return point+away.Unit*35
    end
    function C:recover()
        self.stage='RETREAT'
        self.stats.retreats=self.stats.retreats+1
        local _,_,hum=self:character()
        if not hum then self:stop(); return end
        local point=self:retreatPoint()
        if point then
            if self.cfg.emergencyTP then
                local _,root=self:character()
                if root then
                    root.CFrame=CFrame.new(self:ground(point)) * root.CFrame.Rotation
                    task.wait(.25)
                end
            else
                self:goTo(point,5,true)
            end
        end
        self.stage='RECOVER'
        local deadline=os.clock()+34
        while self.running and self.live and os.clock()<deadline do
            local hp,maxHP=self:health()
            if hp<=0 then self:stop(); return end
            local count,near=self:threats(self:position(),9)
            if hp/math.max(maxHP,1) >= self.cfg.resumeHP and count==0 then
                self.panic=false
                self:note('Recovered: resuming interrupted jobs')
                return
            end
            -- If still surrounded, relocate, but not on every tick.
            if near<5 and point and os.clock()%7<.25 then
                local further=self:retreatPoint()
                if further then self:goTo(further,5,true) end
            end
            task.wait(.25)
        end
        self:note('No safe recovery: stopped; wood jobs preserved')
        self:stop()
    end
end
