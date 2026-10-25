return function(C)
    function C:move(position, stopAt, isEscape)
        if self.safetyAlert and not isEscape then return false end
        local _, root, hum = self:character()
        if not root or not position then return false end
        self.motionToken = self.motionToken + 1
        local token = self.motionToken
        local p = self:groundAt(position)
        local distance = (root.Position - p).Magnitude
        if distance <= (stopAt or 2.8) then return true end
        local mode = self.config.mode
        if mode == "Instant TP" then
            root.CFrame = CFrame.new(p) * root.CFrame.Rotation
            task.wait(0.24)
            return self.running and token == self.motionToken
                and (root.Position - p).Magnitude <= math.max(stopAt or 3, 5.5)
        elseif mode == "Step TP" then
            local last = root.Position
            local dist = (p - last).Magnitude
            local steps = math.clamp(math.ceil(dist / math.max(self.config.stepSpeed * 0.08, 1)), 1, 180)
            for i = 1, steps do
                if not self.running or token ~= self.motionToken
                    or (self.safetyAlert and not isEscape) then return false end
                local nextPos = last:Lerp(p, i / steps)
                root.CFrame = CFrame.new(nextPos) * root.CFrame.Rotation
                task.wait(0.08)
            end
            return self.running and token == self.motionToken
                and (root.Position - p).Magnitude <= math.max(stopAt or 3, 6)
        end
        local function moveToPoint(v)
            hum:MoveTo(v)
            local deadline = os.clock() + math.clamp((v - root.Position).Magnitude / math.max(hum.WalkSpeed, 8) + 2.2, 2.5, 18)
            while self.running and token == self.motionToken and os.clock() < deadline
                and (isEscape or not self.safetyAlert) do
                if (root.Position - v).Magnitude <= (stopAt or 3.0) then return true end
                if hum.Health <= 0 then return false end
                task.wait(0.12)
            end
            return (root.Position - v).Magnitude <= (stopAt or 3.0)
        end
        -- Most log pickups are a few studs away: don't allocate/compute a Path.
        local path
        if distance > 13 then
            local success = pcall(function()
                path = self.pathService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
                path:ComputeAsync(root.Position,p)
            end)
            if success and path and path.Status == Enum.PathStatus.Success then
                for _, node in ipairs(path:GetWaypoints()) do
                    if not self.running or token ~= self.motionToken
                        or (self.safetyAlert and not isEscape) then break end
                    if node.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                    if not moveToPoint(node.Position) then break end
                end
            end
        end
        -- Path is an Instance; explicitly release it, including failed paths.
        if path then pcall(function() path:Destroy() end) end
        if not self.running or token ~= self.motionToken
            or (self.safetyAlert and not isEscape) then return false end
        if (root.Position - p).Magnitude > (stopAt or 3) then
            moveToPoint(p)
        end
        return self.running and token == self.motionToken
            and (isEscape or not self.safetyAlert)
            and (root.Position - p).Magnitude < (stopAt or 3.5) + 1
    end
    function C:moveToTree(tree)
        local trunk = self:trunk(tree)
        local p = self:pos()
        if not trunk or not p then return false end
        local offset = p - trunk.Position
        offset = Vector3.new(offset.X, 0, offset.Z)
        if offset.Magnitude < 0.1 then offset = Vector3.new(0, 0, 1) end
        offset = offset.Unit * self.config.hitDistance
        local goal = trunk.Position + offset
        local ok = self:move(goal, 2.1)
        return ok
    end
    function C:face(position)
        local _, root = self:character()
        if not root then return end
        local look = Vector3.new(position.X, root.Position.Y, position.Z)
        if (look - root.Position).Magnitude > 0.1 then
            root.CFrame = CFrame.lookAt(root.Position, look)
        end
        local cam = self.ws.CurrentCamera
        if cam and not self.config.freeLook and not self.config.spectator then
            local from = cam.CFrame.Position
            local target = position + Vector3.new(0, 0.35, 0)
            cam.CFrame = CFrame.lookAt(from, target)
        end
    end
end
