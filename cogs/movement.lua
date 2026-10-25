return function(C)
    local function waitUntil(token, seconds)
        local deadline = os.clock() + seconds
        while C.alive and C.running and token == C.motionToken and os.clock() < deadline do
            task.wait(0.07)
        end
        return C.alive and C.running and token == C.motionToken
    end
    function C:move(position, stopAt)
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
        elseif mode == "Step TP" then
            local last = root.Position
            local dist = (p - last).Magnitude
            local steps = math.clamp(math.ceil(dist / math.max(self.config.stepSpeed * 0.08, 1)), 1, 180)
            for i = 1, steps do
                if not self.running or token ~= self.motionToken then return false end
                local nextPos = last:Lerp(p, i / steps)
                root.CFrame = CFrame.new(nextPos) * root.CFrame.Rotation
                task.wait(0.08)
            end
            return self.running
        end
        local function moveToPoint(v)
            hum:MoveTo(v)
            local deadline = os.clock() + math.clamp((v - root.Position).Magnitude / math.max(hum.WalkSpeed, 8) + 2.2, 2.5, 18)
            while self.running and token == self.motionToken and os.clock() < deadline do
                if (root.Position - v).Magnitude <= (stopAt or 3.0) then return true end
                if hum.Health <= 0 then return false end
                task.wait(0.12)
            end
            return (root.Position - v).Magnitude <= (stopAt or 3.0)
        end
        local ok, path = pcall(function()
            local pathObj = self.pathService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
            pathObj:ComputeAsync(root.Position, p)
            return pathObj
        end)
        if ok and path and path.Status == Enum.PathStatus.Success then
            for _, node in ipairs(path:GetWaypoints()) do
                if not self.running or token ~= self.motionToken then return false end
                if node.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                if not moveToPoint(node.Position) then break end
            end
        end
        if self.running and (root.Position - p).Magnitude > (stopAt or 3) then
            moveToPoint(p)
        end
        return self.running and (root.Position - p).Magnitude < (stopAt or 3.5) + 1
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
        if cam then
            local from = cam.CFrame.Position
            local target = position + Vector3.new(0, 0.35, 0)
            cam.CFrame = CFrame.lookAt(from, target)
        end
    end
end
