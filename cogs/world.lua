-- V4.2: whole-map model registry; no fixed-distance tree or mob cutoff.
return function(C)
    C.trees, C.wood, C.enemies = {}, {}, {}
    C.blockedTrees, C.workTree = {}, nil
    C.worldScanAt, C.treeScan = 0, {cached=0,valid=0,blocked=0,nearest=nil}
    local function modelPos(model)
        if not model or not model.Parent then return nil end
        local ok, cf = pcall(function() return model:GetPivot() end)
        return ok and cf.Position or nil
    end
    function C:treePart(tree)
        if not tree then return nil end
        local part=tree:FindFirstChild('TrunkBase') or tree:FindFirstChild('Root')
        if not part then part=tree:FindFirstChild('TrunkBase',true) end
        return part and part:IsA('BasePart') and part or nil
    end
    function C:treeValid(tree)
        if not (tree and tree:IsA('Model') and self.treesFolder
            and tree:IsDescendantOf(self.treesFolder)) then return false end
        local hp=tree:GetAttribute('HP')
        return type(hp)=='number' and hp>0
            and tree:GetAttribute('Felled')~=true
            and self:treePart(tree)~=nil
    end
    local function addTree(tree)
        if tree:IsA('Model') and (tree:GetAttribute('TreeId')~=nil
            or type(tree:GetAttribute('HP'))=='number') then
            C.trees[tree]=true
        end
    end
    function C:scanTrees(force)
        local now=os.clock()
        if not force and now-self.worldScanAt<3 then return end
        self.worldScanAt=now
        if not self.treesFolder or not self.treesFolder.Parent then
            self.map=self.ws:FindFirstChild('Map')
            self.treesFolder=self.map and self.map:FindFirstChild('Trees',true)
        end
        if not self.treesFolder then return end
        for _,item in ipairs(self.treesFolder:GetDescendants()) do addTree(item) end
        -- Replicated models may be created with attributes after parenting.
        for _,item in ipairs(self.treesFolder:GetChildren()) do addTree(item) end
    end
    if C.treesFolder then
        C:scanTrees(true)
        C:connect(C.treesFolder.DescendantAdded,addTree)
        C:connect(C.treesFolder.DescendantRemoving,function(tree)
            C.trees[tree],C.blockedTrees[tree]=nil,nil
            if C.workTree==tree then C.workTree=nil end
        end)
    end
    local function addLog(log)
        if not log:IsA('Model') or log.Name~='Log' or C.wood[log] then return end
        C.wood[log]={born=os.clock(),last=modelPos(log),stableAt=os.clock(),
            nextTry=0,failures=0,done=false}
    end
    if C.logsFolder then
        for _,log in ipairs(C.logsFolder:GetChildren()) do addLog(log) end
        C:connect(C.logsFolder.ChildAdded,addLog)
        C:connect(C.logsFolder.ChildRemoved,function(log) C.wood[log]=nil end)
    end
    function C:woodPosition(log)
        local part=log and (log:FindFirstChild('Wood') or log.PrimaryPart)
        if part and part:IsA('BasePart') then return part.Position end
        return modelPos(log)
    end
    function C:woodReady(log,job)
        if not log or log.Parent~=self.logsFolder or job.done then return false end
        local now=os.clock()
        local at=self:woodPosition(log)
        if not at then return false end
        if job.last and (at-job.last).Magnitude>.18 then job.stableAt=now end
        job.last=at
        return now-job.born>=2.2 and (now-job.stableAt>=.75 or now-job.born>8)
    end
    function C:woodCounts()
        local total,ready=0,0
        for log,job in pairs(self.wood) do
            if log.Parent~=self.logsFolder then self.wood[log]=nil
            elseif not job.done then
                total=total+1
                if self:woodReady(log,job) then ready=ready+1 end
            end
        end
        return total,ready
    end
    function C:chooseWood()
        local from=self:position()
        if not from then return nil end
        local chosen,dist=nil,math.huge
        for log,job in pairs(self.wood) do
            if not job.done and os.clock()>=job.nextTry and self:woodReady(log,job) then
                local at=self:woodPosition(log)
                if at and (at-from).Magnitude<dist then
                    chosen,dist=log,(at-from).Magnitude
                end
            end
        end
        return chosen
    end
    function C:chooseTree()
        self:scanTrees(false)
        if self.safeTree and os.clock() < (self.safeTreeUntil or 0)
            and self:treeValid(self.safeTree) then return self.safeTree end
        if self.workTree and self:treeValid(self.workTree) then return self.workTree end
        local from=self:position()
        if not from then return nil end
        local chosen,score=nil,math.huge
        local cached,valid,blocked,nearest=0,0,0,math.huge
        local now=os.clock()
        for tree in pairs(self.trees) do
            if not tree.Parent then self.trees[tree]=nil
            else
                cached=cached+1
                if self:treeValid(tree) then
                    valid=valid+1
                    local at=self:treePart(tree)
                    local dist=(at.Position-from).Magnitude
                    if dist<nearest then nearest=dist end
                    if (self.blockedTrees[tree] or 0)>now then blocked=blocked+1
                    else
                        local golden=tree:GetAttribute('Mutation')=='Golden'
                        local value=dist-(golden and 10 or 0)
                        if value<score then chosen,score=tree,value end
                    end
                end
            end
        end
        self.treeScan={cached=cached,valid=valid,blocked=blocked,
            nearest=nearest~=math.huge and math.floor(nearest) or nil}
        -- There is NO 260-stud limit. This works for Haunted trees across the map.
        return chosen
    end
    function C:isEnemy(model)
        return model and model:IsA('Model') and model.Parent==self.monstersFolder
            and model:GetAttribute('MonsterId')~=nil
            and type(model:GetAttribute('Monster'))=='string'
            and type(model:GetAttribute('HP'))=='number'
            and type(model:GetAttribute('MaxHP'))=='number'
    end
    function C:enemyValid(model)
        return self:isEnemy(model) and model:GetAttribute('HP')>0
            and model:GetAttribute('State')~='Dead'
    end
    function C:enemyPosition(model)
        if not self:enemyValid(model) then return nil end
        return modelPos(model)
    end
    local function addEnemy(model)
        if model:IsA('Model') then C.enemies[model]=true end
    end
    if C.monstersFolder then
        for _,model in ipairs(C.monstersFolder:GetChildren()) do addEnemy(model) end
        C:connect(C.monstersFolder.ChildAdded,addEnemy)
        C:connect(C.monstersFolder.ChildRemoved,function(model)
            C.enemies[model]=nil
            if C.followTarget==model and C.stopHover then C:stopHover() end
        end)
    end
end
