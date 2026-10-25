-- V4.8.0: continuous air position, scoped to Instant TP work/combat.
-- Sell and pumpkin stages deliberately remain grounded.
return function(C)
    local rs=game:GetService('RunService')
    C.workHover=nil
    C.airHold=nil
    function C:enableAirHold(root)
        if self.cfg.move~='Instant TP' then self:disableAirHold(); return end
        if not root or not root.Parent then return end
        if self.airHold and self.airHold.Parent~=root then self:disableAirHold() end
        if not self.airHold then
            local mover=Instance.new('BodyVelocity')
            mover.Name='CAF_AirHold'
            mover.P=18000
            mover.MaxForce=Vector3.new(2e7,2e7,2e7)
            mover.Velocity=Vector3.zero
            mover.Parent=root
            self.airHold=mover
        end
    end
    function C:disableAirHold()
        if self.airHold then pcall(function() self.airHold:Destroy() end) end
        self.airHold=nil
    end
    function C:clearWorkHover()
        self.workHover=nil
        if not self.followTarget then self:disableAirHold() end
    end
    function C:setWorkHover(part,short)
        if self.cfg.move~='Instant TP' or not part or not part:IsA('BasePart') then return end
        self.workHover=part
        self.workHoverUntil=short and os.clock()+2.6 or math.huge
    end
    C:connect(rs.Heartbeat,function()
        if not C.live or not C.running then C:clearWorkHover(); return end
        if C.cfg.move~='Instant TP' then C:clearWorkHover(); return end
        if C.followTarget then return end -- combat owns the air hold
        local part=C.workHover
        if not part then return end
        if not part.Parent or os.clock()>(C.workHoverUntil or 0) then
            C:clearWorkHover(); return
        end
        if not C.cfg.farm or C:isPaused() or C.postBossAction then
            C:clearWorkHover(); return
        end
        if (C.isDodging and C:isDodging()) then
            C:disableAirHold(); return
        end
        if C:mobInterrupt() then
            C:clearWorkHover(); return
        end
        local _,root,hum=C:character()
        if not root or not hum then C:clearWorkHover(); return end
        -- Stay within realistic tree melee reach; track live trunk movement.
        local at=part.Position
        local goal=Vector3.new(at.X+1.25,at.Y+2.45,at.Z+1.25)
        if (goal-at).Magnitude>4.6 then return end
        C:enableAirHold(root)
        root.CFrame=CFrame.new(goal)*root.CFrame.Rotation
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end)
end
