return function(C)
    C.trees, C.wood, C.enemies = {}, {}, {}
    C.blockedTrees, C.workTree = {}, nil
    local function modelPos(model)
        if not model or not model.Parent then return nil end
        local ok, cf = pcall(function() return model:GetPivot() end)
        return ok and cf.Position or nil
    end
    function C:treePart(tree)
        local part = tree and (tree:FindFirstChild('TrunkBase') or tree:FindFirstChild('Root'))
        return part and part:IsA('BasePart') and part or nil
    end
    function C:treeValid(tree)
        return tree and tree.Parent == self.treesFolder
            and type(tree:GetAttribute('TreeId')) == 'number'
            and type(tree:GetAttribute('HP')) == 'number'
            and tree:GetAttribute('HP') > 0
            and tree:GetAttribute('Felled') ~= true
            and self:treePart(tree) ~= nil
    end
    local function addTree(tree)
        if tree:IsA('Model') and type(tree:GetAttribute('TreeId')) == 'number' then
            C.trees[tree] = true
        end
    end
    if C.treesFolder then
        for _, tree in ipairs(C.treesFolder:GetChildren()) do addTree(tree) end
        C:connect(C.treesFolder.ChildAdded, addTree)
        C:connect(C.treesFolder.ChildRemoved, function(tree)
            C.trees[tree], C.blockedTrees[tree] = nil, nil
            if C.workTree == tree then C.workTree = nil end
        end)
    end
    local function addLog(log)
        if not log:IsA('Model') or log.Name ~= 'Log' then return end
        if C.wood[log] then return end
        C.wood[log] = {
            born = os.clock(), last = modelPos(log), stableAt = os.clock(),
            nextTry = 0, failures = 0, done = false
        }
    end
    if C.logsFolder then
        for _, log in ipairs(C.logsFolder:GetChildren()) do addLog(log) end
        C:connect(C.logsFolder.ChildAdded, addLog)
        C:connect(C.logsFolder.ChildRemoved, function(log) C.wood[log] = nil end)
    end
    function C:woodPosition(log)
        local p = log and (log:FindFirstChild('Wood') or log.PrimaryPart)
        if p and p:IsA('BasePart') then return p.Position end
        return modelPos(log)
    end
    function C:woodReady(log, job)
        if not log or log.Parent ~= self.logsFolder or job.done then return false end
        local now = os.clock()
        local at = self:woodPosition(log)
        if not at then return false end
        if job.last and (at-job.last).Magnitude > .18 then job.stableAt = now end
        job.last = at
        -- Let server-side falling animation finish before attempting pickup.
        return now-job.born >= 2.2 and (now-job.stableAt >= .75 or now-job.born > 8)
    end
    function C:woodCounts()
        local total, ready = 0, 0
        for log, job in pairs(self.wood) do
            if log.Parent ~= self.logsFolder then self.wood[log] = nil
            elseif not job.done then
                total = total + 1
                if self:woodReady(log, job) then ready = ready + 1 end
            end
        end
        return total, ready
    end
    function C:chooseWood()
        local playerPos = self:position()
        if not playerPos then return nil end
        local selected, dist = nil, math.huge
        local now = os.clock()
        for log, job in pairs(self.wood) do
            if not job.done and now >= job.nextTry and self:woodReady(log, job) then
                local pos = self:woodPosition(log)
                if pos and not self:isRiskPos(pos) then
                    local d = (pos-playerPos).Magnitude
                    if d < dist then selected, dist = log, d end
                end
            end
        end
        return selected
    end
    function C:chooseTree()
        if self.workTree and self:treeValid(self.workTree) then
            local part = self:treePart(self.workTree)
            if part and not self:isRiskPos(part.Position) then return self.workTree end
        end
        local playerPos = self:position()
        if not playerPos then return nil end
        local selected, best = nil, math.huge
        local now = os.clock()
        for tree in pairs(self.trees) do
            if self:treeValid(tree) and (self.blockedTrees[tree] or 0) < now then
                local part = self:treePart(tree)
                if part and not self:isRiskPos(part.Position) then
                    local d = (part.Position-playerPos).Magnitude
                    if d < self.cfg.maxTreeDistance then
                        local golden = tree:GetAttribute('Mutation') == 'Golden'
                        local score = d - (golden and 10 or 0)
                        if score < best then selected, best = tree, score end
                    end
                end
            end
        end
        return selected
    end
    function C:isEnemy(model)
        return model and model:IsA('Model') and model.Parent == self.monstersFolder
            and model:GetAttribute('MonsterId') ~= nil
            and type(model:GetAttribute('Monster')) == 'string'
            and type(model:GetAttribute('HP')) == 'number'
            and type(model:GetAttribute('MaxHP')) == 'number'
    end
    function C:enemyValid(model)
        return self:isEnemy(model) and model:GetAttribute('HP') > 0
            and model:GetAttribute('State') ~= 'Dead'
    end
    function C:enemyPosition(model) return modelPos(model) end
    local function addEnemy(model)
        if C:isEnemy(model) then C.enemies[model] = true end
    end
    if C.monstersFolder then
        for _, model in ipairs(C.monstersFolder:GetChildren()) do addEnemy(model) end
        C:connect(C.monstersFolder.ChildAdded, function(model)
            task.spawn(function()
                -- Attributes can replicate after the Model reaches Workspace.
                for _=1,12 do
                    if not C.live or model.Parent~=C.monstersFolder then break end
                    addEnemy(model)
                    if C.enemies[model] then break end
                    task.wait(.25)
                end
            end)
        end)
        C:connect(C.monstersFolder.ChildRemoved, function(model) C.enemies[model] = nil end)
    end
end
