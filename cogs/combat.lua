-- V4.2 whole-map combat. A moving enemy is followed every Heartbeat.
-- Uses no RemoteEvent guessing and never attacks stale coordinates.
return function(C)
    local rs=game:GetService('RunService')
    C.enemyRetry={}
    C.followTarget=nil
    C.followHeight=3.8
    C.savedAutoRotate=nil
    function C:stopHover()
        self.followTarget=nil
        local _,_,hum=self:character()
        if hum and self.savedAutoRotate~=nil then
            hum.AutoRotate=self.savedAutoRotate
        end
        self.savedAutoRotate=nil
    end
    function C:startHover(enemy)
        if not self:enemyValid(enemy) then return false end
        local _,_,hum=self:character()
        if not hum then return false end
        if self.savedAutoRotate==nil then self.savedAutoRotate=hum.AutoRotate end
        hum.AutoRotate=false
        self.followTarget=enemy
        return true
    end
    C:connect(rs.Heartbeat,function()
        local enemy=C.followTarget
        if not enemy then return end
        if not C.live or not C.running or C:isPaused() or not C:enemyValid(enemy) then
            C:stopHover(); return
        end
        if C.isDodging and C:isDodging() then return end
        local _,root,hum=C:character()
        local at=C:enemyPosition(enemy)
        if not root or not at then C:stopHover(); return end
        -- Slight horizontal offset avoids standing inside the target's hitbox.
        -- Constant Y + zero velocity prevent gravity from dropping the client
        -- character between target updates while the fight is active.
        local goal=at+Vector3.new(.6,C.followHeight,.6)
        local flat=Vector3.new(at.X,goal.Y,at.Z)
        root.CFrame=CFrame.lookAt(goal,flat)
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end)
    -- Keep the camera crosshair on the MOVING target every rendered frame.
    -- Tool useItem also resolves the point again immediately before a click.
    C:connect(rs.RenderStepped,function()
        local enemy=C.followTarget
        if not enemy or not C.running or (C.isDodging and C:isDodging()) then return end
        local at=C:enemyPosition(enemy)
        if at then C:aimAt(at+Vector3.new(0,.55,0)) end
    end)
    function C:pickEnemy(radius,ignoreBoss)
        if not self.cfg.combat then return nil end
        local from=self:position()
        if not from then return nil end
        local chosen,dist=nil,math.huge
        -- ATTACK has unlimited search by default. FARM retaliation is local.
        radius=radius or math.huge
        for mob in pairs(self.enemies) do
            if self:enemyValid(mob)
                and (not ignoreBoss or mob:GetAttribute('Monster')~='Guardian')
                and os.clock()>=(self.enemyRetry[mob] or 0) then
                local at=self:enemyPosition(mob)
                if at then
                    local d=(at-from).Magnitude
                    if d<=radius and d<dist then chosen,dist=mob,d end
                end
            end
        end
        return chosen
    end
    function C:pickBoss()
        local best,dist=nil,math.huge
        local from=self:position()
        if not from then return nil end
        for mob in pairs(self.enemies) do
            if self:enemyValid(mob) and mob:GetAttribute('Monster')=='Guardian'
                and os.clock()>=(self.enemyRetry[mob] or 0) then
                local at=self:enemyPosition(mob)
                local d=at and (at-from).Magnitude or math.huge
                if d<dist then best,dist=mob,d end
            end
        end
        return best
    end
    function C:fight(enemy)
        if not self:enemyValid(enemy) or self:isPaused() then return false end
        self.stage='COMBAT: tracking live target'
        self:cancelMove()
        if not self:startHover(enemy) then return false end
        local misses,shots=0,0
        local lastHP=enemy:GetAttribute('HP')
        local deadline=os.clock()+24
        while self.running and not self:isPaused() and self:enemyValid(enemy)
            and shots<40 and os.clock()<deadline do
            if self.cfg.priority=='FARM' and not self:urgentCombat() then break end
            if self.isDodging and self:isDodging() then
                task.wait(.05)
            else
            local at=self:enemyPosition(enemy)
            if not at then break end
            self.stage='COMBAT: hovering + attacking'
            -- Read live enemy position AFTER tool cooldown and immediately
            -- BEFORE input. Heartbeat independently follows its movement.
            local before=enemy:GetAttribute('HP')
            local ok,why=self:useItem(function()
                local p=self:enemyPosition(enemy)
                return p and p+Vector3.new(0,.55,0)
            end,'Combat')
            if not ok then self:note(why or 'Combat input failed'); break end
            shots=shots+1
            local confirmed=false
            local untilAt=os.clock()+.65
            while self.running and not self:isPaused() and os.clock()<untilAt do
                local after=enemy:GetAttribute('HP')
                if type(before)=='number' and type(after)=='number' and after<before-.01 then
                    confirmed=true; lastHP=after; break
                end
                if not self:enemyValid(enemy) then break end
                task.wait(.045)
            end
            if confirmed then
                misses=0
                self.followHeight=3.8
            else
                misses=misses+1
                -- Try a closer vertical offset after misses; target keeps moving.
                self.followHeight=misses%2==0 and 2.8 or 3.3
                if misses>=5 then
                    self:note('No confirmed damage; retry target later')
                    break
                end
            end
            end -- dodge gate
        end
        self:stopHover()
        self.followHeight=3.8
        local finalHP=enemy:GetAttribute('HP')
        local dead=(type(finalHP)=='number' and finalHP<=0)
            or enemy:GetAttribute('State')=='Dead'
        if dead then
            self.stats.kills=self.stats.kills+1
            self:note('Monster defeated (HP confirmed)')
            return true
        end
        self.enemyRetry[enemy]=os.clock()+math.min(7,2+misses)
        return false
    end
end
