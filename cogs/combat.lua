return function(C)
    C.enemyRetry={}
    function C:pickEnemy()
        if not self.cfg.combat or self.cfg.style=='Safe' then return nil end
        local playerPos=self:position()
        if not playerPos then return nil end
        local selected, nearest=nil,math.huge
        local maxRange=self.cfg.style=='Aggressive' and 45 or 10
        for enemy in pairs(self.enemies) do
            if self:enemyValid(enemy) and os.clock() >= (self.enemyRetry[enemy] or 0)
                and enemy:GetAttribute('Monster')~='Guardian' then
                local point=self:enemyPosition(enemy)
                if point then
                    local d=(point-playerPos).Magnitude
                    if d<maxRange and d<nearest then
                        selected,nearest=enemy,d
                    end
                end
            end
        end
        return selected
    end
    function C:fight(enemy)
        if not self:enemyValid(enemy) then return false end
        local hp,maxHP=self:health()
        if hp/math.max(maxHP,1)<.78 then return false end
        self.stage='COMBAT: engage'
        local failed,attempts=0,0
        while self.running and not self.panic and self:enemyValid(enemy) and attempts<30 do
            local at=self:enemyPosition(enemy)
            local p=self:position()
            if not at or not p then break end
            local crowd=self:threats(p,7)
            if crowd>1 then break end -- no multi-mob suicide
            local hpCurrent,hpMax=self:health()
            if hpCurrent/math.max(hpMax,1)<.73 then break end
            local profile=self:activeProfile()
            local reach=profile=='Pistol' and 14 or 4.3
            if (at-p).Magnitude>reach then
                self.stage='COMBAT: approach'
                if not self:goTo(at,reach-1) then break end
            end
            local previous=enemy:GetAttribute('HP')
            local ok,reason=self:useItem(at+Vector3.new(0,1.25,0),'Combat')
            if not ok then self:note(reason or 'Combat input failed'); break end
            attempts=attempts+1
            local changed=false
            local deadline=os.clock()+.85
            while self.running and not self.panic and os.clock()<deadline do
                local now=enemy:GetAttribute('HP')
                if type(now)=='number' and now<previous-.01 then
                    changed=true; break
                end
                if not self:enemyValid(enemy) then changed=true; break end
                task.wait(.07)
            end
            if changed then failed=0 else failed=failed+1 end
            if failed>=3 then
                self:note('Enemy damage not confirmed; skipping target')
                break
            end
            -- Light sidestep helps against melee without risky large circles.
            if self.running and not self.panic and self:enemyValid(enemy)
                and self.cfg.move=='Walk' then
                local me=self:position()
                local target=self:enemyPosition(enemy)
                if me and target and (me-target).Magnitude<6 then
                    local offset=me-target
                    local side=Vector3.new(-offset.Z,0,offset.X)
                    if side.Magnitude>0.1 then
                        self:goTo(me+side.Unit*3,2.3)
                    end
                end
            end
        end
        if not self:enemyValid(enemy) then
            self.stats.kills=self.stats.kills+1
            self:note('Monster defeated')
            return true
        end
        self.enemyRetry[enemy]=os.clock()+12
        return false
    end
end
