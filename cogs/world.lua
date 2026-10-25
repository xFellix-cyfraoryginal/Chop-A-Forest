return function(C)
    C.trees = {}
    C.drops = {}
    local function treeOk(m)
        return m and m:IsA("Model") and m.Parent == C.treeFolder
            and type(m:GetAttribute("TreeId")) == "number"
            and type(m:GetAttribute("HP")) == "number"
    end
    function C:trunk(tree)
        if not treeOk(tree) then return nil end
        local p = tree:FindFirstChild("TrunkBase") or tree:FindFirstChild("Root")
        return p and p:IsA("BasePart") and p or nil
    end
    function C:treeOK(tree)
        return treeOk(tree) and tree:GetAttribute("Felled") ~= true
            and (tree:GetAttribute("HP") or 0) > 0 and self:trunk(tree) ~= nil
    end
    function C:area()
        local p = self:pos()
        if not p then return 1 end
        local nearest, dist = nil, math.huge
        for t in pairs(self.trees) do
            local pt = self:trunk(t)
            local d = pt and (pt.Position - p).Magnitude or math.huge
            if d < dist then dist, nearest = d, t end
        end
        return nearest and nearest:GetAttribute("AreaIndex") or 1
    end
    function C:pickTree()
        local p = self:pos()
        if not p then return nil end
        local best, score
        local area = self.config.selectedArea == "Current" and self:area()
            or tonumber(self.config.selectedArea)
        for t in pairs(self.trees) do
            if self:treeOK(t) and (not area or area == t:GetAttribute("AreaIndex"))
                and (not self.config.eventOnly or t:GetAttribute("Biome") == "Graveyard"
                    or tostring(t:GetAttribute("TreeType") or ""):find("^Haunted") ~= nil) then
                local part = self:trunk(t)
                local d = (part.Position - p).Magnitude
                if d <= self.config.maxTreeDistance and (self.failedTrees[t] or 0) < self.config.maxFailures then
                    local s = d
                    if self.config.goldFirst and t:GetAttribute("Mutation") == "Golden" then s = s - 120 end
                    if not score or s < score then score, best = s, t end
                end
            end
        end
        return best
    end
    local function addTree(tree)
        if not treeOk(tree) then return end
        C.trees[tree] = true
    end
    if C.treeFolder then
        for _, tree in ipairs(C.treeFolder:GetChildren()) do addTree(tree) end
        C:connect(C.treeFolder.ChildAdded, addTree)
        C:connect(C.treeFolder.ChildRemoved, function(tree)
            C.trees[tree] = nil
            C.failedTrees[tree] = nil
        end)
    end
    function C:logPart(log)
        if not log or log.Parent ~= self.logFolder then return nil end
        if log:IsA("BasePart") then return log end
        if log:IsA("Model") then return log.PrimaryPart or log:FindFirstChildWhichIsA("BasePart", true) end
        return nil
    end
    local function addLog(obj)
        if obj.Name ~= "Log" then return end
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
        C.drops[obj] = true
    end
    if C.logFolder then
        for _, obj in ipairs(C.logFolder:GetChildren()) do addLog(obj) end
        C:connect(C.logFolder.ChildAdded, addLog)
        C:connect(C.logFolder.ChildRemoved, function(obj) C.drops[obj] = nil end)
    end
    function C:nearestLog(maxD, rejected)
        local p = self:pos()
        if not p then return nil end
        local best, distance
        for log in pairs(self.drops) do
            local pt = self:logPart(log)
            local d = pt and (pt.Position - p).Magnitude or math.huge
            if not (rejected and rejected[log]) and d < (maxD or 65)
                and (not distance or d < distance) then
                best, distance = log, d
            end
        end
        return best, distance
    end
    function C:sellPos()
        local spot = self.sell
        if not spot or not spot.Parent then return nil end
        if spot:IsA("BasePart") then return spot.Position end
        if spot:IsA("Model") then
            local pad = spot:FindFirstChild("DepositPad", true)
            if pad and pad:IsA("BasePart") then return pad.Position end
            return spot:GetPivot().Position
        end
        return nil
    end
    function C:groundAt(position)
        local params = RaycastParams.new()
        local ch = self.player.Character
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ch and {ch} or {}
        local hit = self.ws:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -28, 0), params)
        return Vector3.new(position.X, hit and hit.Position.Y + 3.1 or position.Y + 3.1, position.Z)
    end
end
