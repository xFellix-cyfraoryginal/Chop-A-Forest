return function(C)
    function C:ground(position)
        if not position then return nil end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ch = self.player.Character
        local exclude = {}
        for _, inst in ipairs({self.treesFolder, self.logsFolder, self.monstersFolder, ch}) do
            if inst then exclude[#exclude+1] = inst end
        end
        params.FilterDescendantsInstances = exclude
        local ray = self.ws:Raycast(position + Vector3.new(0, 22, 0),
            Vector3.new(0, -80, 0), params)
        if ray then return Vector3.new(position.X, ray.Position.Y + 3.15, position.Z) end
        return position + Vector3.new(0, 2.5, 0)
    end
    function C:goTo(goal, radius, escape)
        if self.clearWorkHover then self:clearWorkHover() end
        if not goal or not self.running then return false end
        if not escape and not self.shopping and not self.postBossAction and not self.starterFarming
            and self.cfg.priority=='ATTACK' and self.cfg.combat
            and not self.stage:find('COMBAT',1,true)
            and self:pickSkeleton() then return false end
        if not escape and not self.postBossAction and self:mobInterrupt() then return false end
        if not escape and self.isDodging and self:isDodging() then return false end
        if (self:isPaused() or (self:urgentCombat() and not self.stage:find('COMBAT',1,true)))
            and not escape then return false end
        local _, root, hum = self:character()
        if not root then return false end
        self.motion = self.motion + 1
        local token, session = self.motion, self.session
        local function valid()
            return self.live and self.running and token == self.motion
                and session == self.session and hum.Health > 0
                and (escape or self.shopping or self.postBossAction
                    or self.starterFarming or self.cfg.priority~='ATTACK' or not self.cfg.combat
                    or self.stage:find('COMBAT',1,true) or not self:pickSkeleton())
                and (escape or self.shopping or self.postBossAction or not self:mobInterrupt())
                and (escape or (not (self.isDodging and self:isDodging())
                    and not self:isPaused()
                    and (not self:urgentCombat() or self.stage:find('COMBAT',1,true))))
        end
        radius = radius or 3.5
        local dest = self:ground(goal)
        if not dest then return false end
        if (root.Position-dest).Magnitude < radius then return true end
        if self.cfg.move == 'Instant TP' and not escape then
            root.CFrame = CFrame.new(dest) * root.CFrame.Rotation
            task.wait(.045) -- just enough for an initial physics update
            if not valid() then return false end
            if (root.Position-dest).Magnitude <= radius+2 then return true end
            -- One correction if the engine displaced us during the same frame.
            root.CFrame=CFrame.new(dest)*root.CFrame.Rotation
            task.wait(.05)
            return valid() and (root.Position-dest).Magnitude <= radius+2

        end
        local function walk(point, close)
            hum:MoveTo(point)
            local last, lastAt = root.Position, os.clock()
            local timeout = os.clock() + math.clamp((point-root.Position).Magnitude
                / math.max(hum.WalkSpeed, 8)+2.4, 3, 22)
            while valid() and os.clock()<timeout do
                if (root.Position-point).Magnitude <= close then return true end
                if (root.Position-last).Magnitude > 1 then
                    last, lastAt = root.Position, os.clock()
                elseif os.clock()-lastAt > 2.7 then break end
                task.wait(.11)
            end
            return valid() and (root.Position-point).Magnitude <= close + .5
        end
        local distance = (root.Position-dest).Magnitude
        if distance > 15 then
            local path
            local ok = pcall(function()
                path = self.pfs:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
                path:ComputeAsync(root.Position, dest)
            end)
            if ok and path and path.Status == Enum.PathStatus.Success then
                for _,node in ipairs(path:GetWaypoints()) do
                    if not valid() then break end
                    if node.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                    if not walk(node.Position, 3) then break end
                end
            end
            if path then pcall(function() path:Destroy() end) end
        end
        if valid() and (root.Position-dest).Magnitude > radius then
            walk(dest, radius)
        end
        return valid() and (root.Position-dest).Magnitude <= radius + 1
    end
    function C:approachModel(model, radius)
        local point = model and model:GetPivot().Position
        return point and self:goTo(point, radius) or false
    end
end
