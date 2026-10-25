-- V4.7.5: track mobs by Walk/MoveTo OR by existing Instant TP hover.
-- Uses no RemoteEvent guessing and never attacks stale coordinates.
return function(C)
    local rs=game:GetService('RunService')
    C.enemyRetry={}
    C.followTarget=nil
    C.followHeight=3.8
    C.savedAutoRotate=nil
    C.lastWalkMoveAt=-100
    function C:stopHover()
        self.followTarget=nil
        local _,root,hum=self:character()
        if hum and self.savedAutoRotate~=nil then
            hum.AutoRotate=self.savedAutoRotate
            if self.cfg.move=='Walk' and root then hum:MoveTo(root.Position) end
        end
        self.savedAutoRotate=nil
    end
    function C:startHover(enemy)
        if not self:enemyValid(enemy) then return false end
        local _,_,hum=self:character()
        if not hum then return false end
        if self.savedAutoRotate==nil then self.savedAutoRotate=hum.AutoRotate end
        hum.AutoRotate=self.cfg.move=='Walk' and self.savedAutoRotate or false
        self.followTarget=enemy
        self.lastWalkMoveAt=-100
        return true
    end
    C:connect(rs.Heartbeat,function()
        local enemy=C.followTarget
        if not enemy then return end
        if not C.live or not C.running or not C.cfg.combat or C:isPaused() or not C:enemyValid(enemy) then
            C:stopHover(); return
        end
        if C.isDodging and C:isDodging() then return end
        local _,root,hum=C:character()
        local at=C:enemyPosition(enemy)
        if not root or not at then C:stopHover(); return end
        if C.cfg.move=='Walk' then
            -- Walk mode follows moving enemies on the ground, with no TP.
            hum.AutoRotate=C.savedAutoRotate~=false
            local goal=C:ground(at) or at
            local flatDistance=(Vector3.new(root.Position.X,0,root.Position.Z)
                -Vector3.new(goal.X,0,goal.Z)).Magnitude
            if os.clock()-C.lastWalkMoveAt>=.24 then
                C.lastWalkMoveAt=os.clock()
                hum:MoveTo(flatDistance>4.6 and goal or root.Position)
            end
            return
        end
        hum.AutoRotate=false
        -- Instant TP keeps the existing live-target hover and aim.
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
        if not enemy or not C.running or not C.cfg.combat or (C.isDodging and C:isDodging()) then return end
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
    -- Special event priority: Gravedigger/skeletons (known Sprout), not
    -- Pumpkinling Biters or The Jack o' Lantern. New skeleton-named enemies
    -- are picked up automatically if their shared MonsterId/HP attrs match.
    function C:isSkeleton(enemy)
        if not self:enemyValid(enemy) then return false end
        if enemy:GetAttribute('Monster')=='Guardian' then return false end
        local name=(enemy.Name..' '..tostring(enemy:GetAttribute('DisplayName') or '')):lower()
        if name:find('pumpkin',1,true) or name:find('biter',1,true)
            or name:find('jack',1,true) then return false end
        for _,marker in ipairs({'skeleton','gravedigger','sprout','undead','bone'}) do
            if name:find(marker,1,true) then return true end
        end
        return false
    end
    function C:skeletonCount()
        local count=0
        for mob in pairs(self.enemies) do
            if self:isSkeleton(mob) then count=count+1 end
        end
        return count
    end
    function C:pickSkeleton()
        local from=self:position()
        if not from then return nil end
        local best,dist=nil,math.huge
        for mob in pairs(self.enemies) do
            if self:isSkeleton(mob) and os.clock()>=(self.enemyRetry[mob] or 0) then
                local at=self:enemyPosition(mob)
                local d=at and (at-from).Magnitude or math.huge
                if d<dist then best,dist=mob,d end
            end
        end
        return best
    end
    -- Biter/Pumpkinling enemies use the same MonsterId/HP registry as
    -- Gravediggers. Never match decorative pumpkins or the Guardian boss.
    function C:isPumpkinEnemy(enemy)
        if not self:enemyValid(enemy) then return false end
        if enemy:GetAttribute('Monster')=='Guardian' then return false end
        local name=(enemy.Name..' '..tostring(enemy:GetAttribute('DisplayName') or '')):lower()
        return name:find('biter',1,true)~=nil
            or name:find('pumpkinling',1,true)~=nil
            or name:find('pumpkin',1,true)~=nil
    end
    function C:pumpkinCount()
        local count=0
        for mob in pairs(self.enemies) do
            if self:isPumpkinEnemy(mob) then count=count+1 end
        end
        return count
    end
    function C:pickPumpkin()
        local from=self:position()
        if not from then return nil end
        local best,dist=nil,math.huge
        for mob in pairs(self.enemies) do
            if self:isPumpkinEnemy(mob) and os.clock()>=(self.enemyRetry[mob] or 0) then
                local at=self:enemyPosition(mob)
                local d=at and (at-from).Magnitude or math.huge
                if d<dist then best,dist=mob,d end
            end
        end
        return best
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
        if not self.cfg.combat or not self:enemyValid(enemy) or self:isPaused() then return false end
        self.stage='COMBAT: tracking live target'
        self:cancelMove()
        if self.cfg.move=='Walk' then
            self.stage='COMBAT: walking to enemy'
            local approach=self:enemyPosition(enemy)
            if approach then self:goTo(approach,6) end
            if not self.running or not self.cfg.combat or not self:enemyValid(enemy) then
                return false
            end
        end
        if not self:startHover(enemy) then return false end
        local misses,shots=0,0
        local lastHP=enemy:GetAttribute('HP')
        local deadline=os.clock()+(self.cfg.move=='Walk' and 48 or 24)
        while self.running and self.cfg.combat and not self:isPaused() and self:enemyValid(enemy)
            and shots<40 and os.clock()<deadline do
            if self.cfg.priority=='FARM' and not self:urgentCombat() then break end
            if self.isDodging and self:isDodging() then
                task.wait(.05)
            else
            local at=self:enemyPosition(enemy)
            if not at then break end
            local current=self:position()
            local walkDistance=current and
                (Vector3.new(at.X,0,at.Z)-Vector3.new(current.X,0,current.Z)).Magnitude
                or math.huge
            if self.cfg.move=='Walk' and walkDistance>6.5 then
                self.stage='COMBAT: chasing on foot'
                task.wait(.14) -- let Heartbeat MoveTo catch the mobile mob
            else
            self.stage=self.cfg.move=='Walk' and 'COMBAT: walking + attacking'
                or 'COMBAT: hovering + attacking'
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
            while self.running and self.cfg.combat and not self:isPaused() and os.clock()<untilAt do
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
            end -- walk range gate
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
