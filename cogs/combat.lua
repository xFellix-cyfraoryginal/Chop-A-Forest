-- MonsterId-based targeting. No crowd-size bailouts or automatic kite dance.
return function(C)
    C.enemyRetry={}
    function C:pickEnemy(radius)
        if not self.cfg.combat then return nil end
        local point=self:position()
        if not point then return nil end
        local chosen,best=nil,math.huge
        radius=radius or self.cfg.combatRadius
        for mob in pairs(self.enemies) do
            if self:enemyValid(mob) and mob:GetAttribute('Monster')~='Guardian'
                and os.clock()>=(self.enemyRetry[mob] or 0) then
                local at=self:enemyPosition(mob)
                if at then
                    local d=(at-point).Magnitude
                    if d<radius and d<best then chosen,best=mob,d end
                end
            end
        end
        return chosen
    end
    function C:fight(enemy)
        if not self:enemyValid(enemy) or self:isPaused() then return false end
        self.stage='COMBAT: target'
        local misses,shots=0,0
        local deadline=os.clock()+20
        while self.running and not self:isPaused() and self:enemyValid(enemy)
            and shots<35 and os.clock()<deadline do
            -- FARM only defends against nearby enemies for a brief time after damage.
            if self.cfg.priority=='FARM' and not self:urgentCombat() then break end
            local at=self:enemyPosition(enemy)
            local p=self:position()
            if not at or not p then break end
            local profile=self:activeProfile()
            local reach=profile=='Pistol' and 13 or 4.1
            if (at-p).Magnitude>reach then
                self.stage='COMBAT: approaching'
                if not self:goTo(at,reach-0.6) then break end
            end
            self.stage='COMBAT: attacking'
            local before=enemy:GetAttribute('HP')
            local ok,why=self:useItem(at+Vector3.new(0,1.2,0),'Combat')
            if not ok then self:note(why or 'Combat input failed'); break end
            shots=shots+1
            local confirmed=false
            local untilAt=os.clock()+.9
            while self.running and not self:isPaused() and os.clock()<untilAt do
                local after=enemy:GetAttribute('HP')
                if not self:enemyValid(enemy) or
                    (type(before)=='number' and type(after)=='number' and after<before-.01) then
                    confirmed=true; break
                end
                task.wait(.06)
            end
            misses=confirmed and 0 or misses+1
            if misses>=3 then
                self:note('Combat no damage: temporary target cooldown'); break
            end
        end
        if not self:enemyValid(enemy) then
            self.stats.kills=self.stats.kills+1
            self:note('Monster defeated')
            return true
        end
        self.enemyRetry[enemy]=os.clock()+9
        return false
    end
end
