-- V4.7.5: track mobs by Walk/MoveTo OR by existing Instant TP hover.
-- Uses no RemoteEvent guessing and never attacks stale coordinates.
return function(C)
    local rs=game:GetService('RunService')
    C.enemyRetry={}
    C.followTarget=nil
    C.followHeight=1.55
    C.savedAutoRotate=nil
    C.lastWalkMoveAt=-100
    function C:stopHover()
        self.followTarget=nil
        if self.disableAirHold and not self.workHover then self:disableAirHold() end
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
        if self.clearWorkHover then self:clearWorkHover() end
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
        if C.isDodging and C:isDodging() then
            if C.disableAirHold then C:disableAirHold() end
            return
        end
        local _,root,hum=C:character()
        local at=C:enemyPosition(enemy)
        if not root or not at then C:stopHover(); return end
        if C.cfg.move=='Walk' then
            -- Walk mode follows moving enemies on the ground, with no TP.
            if C.disableAirHold then C:disableAirHold() end
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
        -- One continuous air orbit for Jack; live target hover for minions.
        local boss=enemy:GetAttribute('Monster')=='Guardian'
        local goal
        if boss then
            -- Keep the weapon/crosshair within the enemy's hitbox reach.
            -- Old 3.8-up / 2.1-away orbit caused repeated no-damage swings.
            local angle=os.clock()*.72 + (C.combatOrbitShift or 0)
            local r=(C.followHeight>2) and 1.65 or 1.12
            goal=at+Vector3.new(math.cos(angle)*r,C.followHeight,
                math.sin(angle)*r)
            C.stage='BOSS: close air follow + attacking'
        else
            goal=at+Vector3.new(.55,math.min(C.followHeight,1.65),.55)
        end
        if C.enableAirHold then C:enableAirHold(root) end
        root.CFrame=CFrame.lookAt(goal,Vector3.new(at.X,goal.Y,at.Z))
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end)
    -- Keep the camera crosshair on the MOVING target every rendered frame.
    -- Tool useItem also resolves the point again immediately before a click.
    C:connect(rs.RenderStepped,function()
        local enemy=C.followTarget
        if not enemy or not C.running or not C.cfg.combat or (C.isDodging and C:isDodging()) then return end
        local at=C:enemyPosition(enemy)
        if at then C:aimAt(C:combatAimPoint(enemy) or (at+Vector3.new(0,.55,0))) end
    end)
    -- Prefer actual replicated body/hitbox parts over the model pivot.
    -- Decorative outer models can put GetPivot far from the hittable body.
    function C:combatAimPoint(enemy)
        if not enemy or not enemy.Parent then return nil end
        local selected=nil
        for _,name in ipairs({'Hitbox','HitBox','DamageHitbox','Body','HumanoidRootPart','Root','Torso'}) do
            local node=enemy:FindFirstChild(name,true)
            if node and node:IsA('BasePart') then selected=node; break end
        end
        selected=selected or enemy.PrimaryPart
        if selected and selected:IsA('BasePart') then
            return selected.Position+Vector3.new(0,math.clamp(selected.Size.Y*.08,0,.4),0)
        end
        local pivot=self:enemyPosition(enemy)
        return pivot and pivot+Vector3.new(0,.5,0) or nil
    end
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
        if self.cfg.move=='Instant TP' then task.wait(.045) end -- one hover frame before first LPM
        local misses,shots=0,0
        local lastHP=enemy:GetAttribute('HP')
        local boss=enemy:GetAttribute('Monster')=='Guardian'
        if boss then self.bossLock=enemy end
        local deadline=os.clock()+(self.cfg.move=='Walk' and 55 or 42)
        while self.running and self.cfg.combat and not self:isPaused() and self:enemyValid(enemy)
            and shots<(boss and 250 or 65) and os.clock()<deadline do
            if self.cfg.bossOnly and not boss then break end
            if not boss then
                local guardian=self:pickBoss()
                if self.combatFallback and guardian and (guardian:GetAttribute('State')=='Fighting'
                    or self.bossLock==guardian) then
                    self.bossLock=guardian
                    self:note('BOSS ACTIVE: dropping minion target')
                    break
                end
            end
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
                -- Live sampled part, not stale model pivot coordinates.
                return self:combatAimPoint(enemy)
            end,'Combat')
            if not ok then
                if self.isDodging and self:isDodging() then
                    -- Do not abandon an in-progress fight during a short dodge.
                    task.wait(.045)
                else
                    self:note(why or 'Combat input failed')
                    break
                end
            else
            shots=shots+1
            local confirmed=false
            local untilAt=os.clock()+(boss and .21 or .20)
            while self.running and self.cfg.combat and not self:isPaused() and os.clock()<untilAt do
                local after=enemy:GetAttribute('HP')
                if type(before)=='number' and type(after)=='number' and after<before-.01 then
                    confirmed=true; lastHP=after; break
                end
                if not self:enemyValid(enemy) then break end
                task.wait(.045)
            end
            if confirmed then
                -- Gradually shorten client input spacing only while hits
                -- are ACTUALLY confirmed by server-replicated HP drops.
                self.combatFastScale=math.max(.70,(self.combatFastScale or 1)-.025)
                misses=0
                self.followHeight=1.55
            else
                self.combatFastScale=math.min(1.15,(self.combatFastScale or 1)+.055)
                misses=misses+1
                -- Move THROUGH close hitbox sectors, not higher above Jack.
                self.followHeight=misses%2==0 and 1.10 or 1.85
                self.combatOrbitShift=(self.combatOrbitShift or 0)+.85
                if misses>=4 then
                    self:note('Combat no HP delta: adjusting close hitbox')
                    if not boss and misses>=6 or boss and misses>=16 then break end
                end
            end
            end -- successful input
            end -- walk range gate
            end -- dodge gate
        end
        self:stopHover()
        self.followHeight=1.55
        local finalHP=enemy:GetAttribute('HP')
        local dead=(type(finalHP)=='number' and finalHP<=0)
            or enemy:GetAttribute('State')=='Dead'
        if dead then
            if boss then
                self.bossLock=nil
                self.bossResetWatch=nil -- finished boss is NOT a future reset
            end
            self.stats.kills=self.stats.kills+1
            self:note('Monster defeated (HP confirmed)')
            return true
        end
        self.enemyRetry[enemy]=os.clock()+(boss and .35 or math.min(7,2+misses))
        return false
    end
end
