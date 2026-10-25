-- V4.8.3: live tree-facing/camera aim + continuous Instant TP hover.
-- Sell and pumpkin stages deliberately remain grounded.
return function(C)
    local rs=game:GetService('RunService')
    C.workHover=nil
    C.airHold=nil
    C.workAimTarget=nil
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
        self.workAimTarget=nil
        if not self.followTarget then self:disableAirHold() end
    end
    function C:setWorkHover(part,short)
        if self.cfg.move~='Instant TP' or not part or not part:IsA('BasePart') then return end
        self.workHover=part
        if self.stage and tostring(self.stage):find('TREE:',1,true) then
            self.workAimTarget=part
        end
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
        -- Face the moving trunk on EVERY heartbeat, never keep previous yaw.
        local flat=Vector3.new(at.X,goal.Y,at.Z)
        if (flat-goal).Magnitude>.08 then
            root.CFrame=CFrame.lookAt(goal,flat)
        else
            root.CFrame=CFrame.new(goal)*root.CFrame.Rotation
        end
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end)
    -- The avatar and Roblox camera can turn independently. Refresh both at
    -- frame rate so the crosshair doesn't stay on the PREVIOUS tree after TP.
    C:connect(rs.RenderStepped,function()
        local part=C.workAimTarget
        if not part or not part.Parent or not C.running or not C.live
            or not C.cfg.farm or C:isPaused() or C.followTarget
            or C.postBossAction or (C.isDodging and C:isDodging()) then return end
        if C.stage~='TREE: chopping' then return end
        local at=part.Position+Vector3.new(0,1.05,0)
        C:aimAt(at)
        if C.cfg.move=='Walk' then
            local _,root=C:character()
            if root then
                local flat=Vector3.new(at.X,root.Position.Y,at.Z)
                if (flat-root.Position).Magnitude>.08 then
                    root.CFrame=CFrame.lookAt(root.Position,flat)
                end
            end
        end
    end)
    function C:treeAimAligned(part)
        if not part or not part.Parent then return false end
        local _,root=self:character()
        local cam=self.ws.CurrentCamera
        if not root or not cam then return false end
        local at=part.Position+Vector3.new(0,1.05,0)
        local toCamera=at-cam.CFrame.Position
        local toRoot=Vector3.new(at.X-root.Position.X,0,at.Z-root.Position.Z)
        if toCamera.Magnitude<.15 or toRoot.Magnitude<.15 then return true end
        local flatLook=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
        return cam.CFrame.LookVector:Dot(toCamera.Unit)>.968
            and flatLook.Magnitude>.01 and flatLook.Unit:Dot(toRoot.Unit)>.90
    end
    function C:ensureTreeAim(part)
        if not part or not part.Parent then return false end
        local _,root=self:character()
        if not root then return false end
        for _=1,4 do
            local at=part.Position+Vector3.new(0,1.05,0)
            local flat=Vector3.new(at.X,root.Position.Y,at.Z)
            if (flat-root.Position).Magnitude>.08 then
                root.CFrame=CFrame.lookAt(root.Position,flat)
            end
            self:aimAt(at)
            if self:treeAimAligned(part) then return true end
            task.wait(.018)
        end
        return self:treeAimAligned(part)
    end
end
