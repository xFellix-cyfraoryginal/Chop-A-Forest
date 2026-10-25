-- Optional independent spectator camera; 3D continues to render normally.
-- Input-based clicks aim from the actual camera in some clients, so spectator
-- may prevent attacks/pickups. Free Look (no forced camera turn) is safer.
return function(C)
    local rs=game:GetService("RunService")
    local camera, oldType, oldSubject, oldMouse = nil,nil,nil,nil
    local free, yaw, pitch = false, 0, 0
    local down = {}
    local function restore()
        free=false
        if camera and camera.Parent then
            camera.CameraType=oldType or Enum.CameraType.Custom
            if oldSubject and oldSubject.Parent then camera.CameraSubject=oldSubject end
        end
        if oldMouse then C.uid.MouseBehavior=oldMouse end
        camera=nil
    end
    function C:enableSpectator(enable)
        if not enable then restore(); self.config.spectator=false; return end
        camera=self.ws.CurrentCamera
        if not camera then return end
        oldType,oldSubject,oldMouse=camera.CameraType,camera.CameraSubject,C.uid.MouseBehavior
        local look=camera.CFrame.LookVector
        yaw=math.atan2(-look.X,-look.Z)
        pitch=math.asin(math.clamp(look.Y,-.99,.99))
        camera.CameraType=Enum.CameraType.Scriptable
        free=true
        self.config.spectator=true
        self.config.freeLook=true
        self:note("camera","Spectator ON: RMB mouse, arrows move, PgUp/PgDn height")
    end
    C:connect(C.uid.InputBegan,function(input,processed)
        if not free or processed then return end
        if input.UserInputType==Enum.UserInputType.MouseButton2 then
            down.RMB=true
        elseif input.KeyCode then down[input.KeyCode.Name]=true end
    end)
    C:connect(C.uid.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton2 then down.RMB=false
        elseif input.KeyCode then down[input.KeyCode.Name]=nil end
    end)
    C:connect(C.uid.InputChanged,function(input)
        if free and down.RMB and input.UserInputType==Enum.UserInputType.MouseMovement then
            yaw=yaw-input.Delta.X*.0035
            pitch=math.clamp(pitch-input.Delta.Y*.0035,-1.47,1.47)
        end
    end)
    C:connect(rs.RenderStepped,function(dt)
        if not free or not C.alive or not camera or not camera.Parent then return end
        if camera.CameraType~=Enum.CameraType.Scriptable then camera.CameraType=Enum.CameraType.Scriptable end
        local basis=CFrame.fromOrientation(pitch,yaw,0)
        local v=Vector3.zero
        if down.Up then v=v+Vector3.new(0,0,-1) end
        if down.Down then v=v+Vector3.new(0,0,1) end
        if down.Left then v=v+Vector3.new(-1,0,0) end
        if down.Right then v=v+Vector3.new(1,0,0) end
        if down.PageUp then v=v+Vector3.new(0,1,0) end
        if down.PageDown then v=v+Vector3.new(0,-1,0) end
        local offset=v.Magnitude>.01 and basis:VectorToWorldSpace(v.Unit)*dt*C.config.spectatorSpeed or Vector3.zero
        camera.CFrame=CFrame.new(camera.CFrame.Position+offset)*basis
    end)
    table.insert(C.cleanup,restore)
    function C:cameraMarker()
        if self.characterMarker then return end
        local marker=Instance.new("BillboardGui")
        marker.Name="CropForestBotPosition"
        marker.AlwaysOnTop=true
        marker.Size=UDim2.fromOffset(180,34)
        marker.StudsOffset=Vector3.new(0,4,0)
        marker.Parent=self.ws.CurrentCamera or self.ws
        local txt=Instance.new("TextLabel")
        txt.Size=UDim2.fromScale(1,1)
        txt.BackgroundColor3=Color3.fromRGB(11,27,35)
        txt.BackgroundTransparency=.25
        txt.TextColor3=Color3.fromRGB(112,250,173)
        txt.Font=Enum.Font.GothamBold
        txt.TextScaled=true
        txt.Text="AUTOFARM | YOUR POSITION"
        txt.Parent=marker
        self.characterMarker=marker
        table.insert(self.cleanup,function() marker:Destroy() end)
        local elapsed=0
        self:connect(rs.Heartbeat,function(dt)
            elapsed=elapsed+dt
            if elapsed<.35 then return end
            elapsed=0
            local _,root=self:character()
            marker.Enabled=self.alive and self.running and (self.config.spectator or self.config.freeLook) and root~=nil
            marker.Adornee=root
        end)
    end
    C:cameraMarker()
end
