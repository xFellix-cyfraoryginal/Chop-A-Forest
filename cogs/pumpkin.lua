-- V4.8.3: PumpkinHead is a MODEL. Attack next to its live hitbox,
-- at the same height, rather than over it. Never target decor pumpkins.
return function(C)
    local run=game:GetService('RunService')
    C.nextPumpkinWarn=0
    C.pumpkinTarget=nil
    C.pumpkinMisses=0
    C.pumpkinAngle=0
    local function headPos(head)
        if not head or not head.Parent then return nil end
        if head:IsA('BasePart') then return head.Position end
        local part=head:FindFirstChild('Hitbox',true)
        if not (part and part:IsA('BasePart')) then part=head.PrimaryPart end
        if not (part and part:IsA('BasePart')) then
            part=head:FindFirstChildWhichIsA('BasePart',true)
        end
        if part then return part.Position end
        local ok,p=pcall(function() return head:GetPivot().Position end)
        return ok and p or nil
    end
    function C:clearPumpkinLock()
        self.pumpkinTarget=nil
        if self.disableAirHold then self:disableAirHold() end
    end
    -- The spawned head can wobble / drift. Follow its Hitbox on every frame,
    -- staying <=1.15 studs horizontally from its center, never above it.
    C:connect(run.Heartbeat,function()
        local head=C.pumpkinTarget
        if not head then return end
        if not C.live or not C.running or not C.cfg.combat or not C.postBossAction then
            C:clearPumpkinLock(); return
        end
        if C.cfg.move~='Instant TP' or (C.isDodging and C:isDodging())
            or C:isPaused() then return end
        local at=headPos(head)
        local _,root=C:character()
        if not at or not root then C:clearPumpkinLock(); return end
        if C.disableAirHold then C:disableAirHold() end
        local r=(C.pumpkinMisses>=2) and .65 or 1.05
        local dx=math.cos(C.pumpkinAngle)*r
        local dz=math.sin(C.pumpkinAngle)*r
        local goal=at+Vector3.new(dx,-.15,dz)
        root.CFrame=CFrame.lookAt(goal,at)
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end)
    C:connect(run.RenderStepped,function()
        local head=C.pumpkinTarget
        if not head or not C.running or C:isPaused() or C.cfg.move~='Instant TP' then return end
        local at=headPos(head)
        if at then C:aimAt(at) end
    end)
    function C:postBossStep()
        if not self.cfg.combat then self:clearPumpkinLock();return false end
        local pg=self.player:FindFirstChild('PlayerGui')
        local screen=pg and pg:FindFirstChild('PumpkinChop')
        if not (screen and screen:IsA('ScreenGui') and screen.Enabled) then
            self:clearPumpkinLock(); return false
        end
        self.stage='POST-BOSS: pumpkin head'
        local jack=self.ws:FindFirstChild('JackLantern')
        local head=jack and jack:FindFirstChild('PumpkinHead',true)
        if not (head and (head:IsA('BasePart') or head:IsA('Model'))) then
            if os.clock()>self.nextPumpkinWarn then
                self.nextPumpkinWarn=os.clock()+4
                self:note('PumpkinChop active; waiting for PumpkinHead')
            end
            task.wait(.12)
            return true
        end
        local at=headPos(head)
        if not at then return true end
        local before=tonumber(self.player:GetAttribute('PumpkinDamage')) or 0
        if self.clearWorkHover then self:clearWorkHover() end
        if self.stopHover then self:stopHover() end
        if self.disableAirHold then self:disableAirHold() end
        self.postBossAction=true
        local reached=false
        if self.cfg.move=='Instant TP' then
            -- Do not call goTo(): it GROUNDS the goal and causes high misses.
            -- Set lock first; Heartbeat keeps the head at live melee range.
            self.pumpkinTarget=head
            local _,root=self:character()
            if root then
                local goal=at+Vector3.new(math.cos(self.pumpkinAngle)*1.05,-.15,
                    math.sin(self.pumpkinAngle)*1.05)
                root.CFrame=CFrame.lookAt(goal,at)
                root.AssemblyLinearVelocity=Vector3.zero
                reached=true
            end
        else
            reached=self:goTo(at,1.7)
        end
        if not reached or not self.running or not head.Parent then
            self.postBossAction=false;self:clearPumpkinLock();return true
        end
        self.stage='POST-BOSS: close-range head attack'
        -- Evaluate head position after the weapon cooldown, not on arrival.
        local hit=self:useItem(function()
            local pos=headPos(head)
            if pos and self.pumpkinTarget then self:aimAt(pos) end
            return pos
        end,'Combat')
        if hit then
            local deadline=os.clock()+.62
            while self.running and screen.Enabled and os.clock()<deadline do
                if (tonumber(self.player:GetAttribute('PumpkinDamage')) or 0)>before then
                    self.pumpkinMisses=0
                    self.postBossAction=false
                    self:clearPumpkinLock()
                    return true
                end
                task.wait(.045)
            end
        end
        self.pumpkinMisses=self.pumpkinMisses+1
        if self.pumpkinMisses>=2 then
            -- Vary direction through the hitbox when a side is obstructed.
            self.pumpkinAngle=self.pumpkinAngle+math.pi*.72
        end
        if os.clock()>self.nextPumpkinWarn then
            self.nextPumpkinWarn=os.clock()+3
            self:note('Pumpkin no damage; changing close-range angle')
        end
        self.postBossAction=false
        self:clearPumpkinLock()
        task.wait(.065)
        return true
    end
end
