-- Indexed world query: static tree positions divided into 96-stud cells.
return function(C)
    C.trees, C.drops = {}, {}
    C.treeCells, C.treeIndex = {}, {}
    C.blockedTrees = {}
    C.logSpawnAt = {}
    local CELL = 96
    local function cell(x,z) return math.floor(x/CELL)..":"..math.floor(z/CELL) end
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
    local function addTree(t)
        if not treeOk(t) then return end
        C.trees[t] = true
        local root = C:trunk(t)
        if root then
            local key = cell(root.Position.X, root.Position.Z)
            local bucket = C.treeCells[key]
            if not bucket then bucket = {}; C.treeCells[key] = bucket end
            bucket[t] = true
            C.treeIndex[t] = key
        end
    end
    local function removeTree(t)
        C.trees[t], C.failedTrees[t], C.blockedTrees[t] = nil,nil,nil
        local key=C.treeIndex[t]
        if key and C.treeCells[key] then
            C.treeCells[key][t] = nil
            if not next(C.treeCells[key]) then C.treeCells[key] = nil end
        end
        C.treeIndex[t] = nil
    end
    if C.treeFolder then
        for _,t in ipairs(C.treeFolder:GetChildren()) do addTree(t) end
        C:connect(C.treeFolder.ChildAdded, addTree)
        C:connect(C.treeFolder.ChildRemoved, removeTree)
    end
    local areaCache, areaAt, areaPos = 1, -math.huge, nil
    function C:area()
        local pos = self:pos()
        if not pos then return areaCache end
        if areaPos and (pos-areaPos).Magnitude < 20 and os.clock()-areaAt < 2 then
            return areaCache
        end
        local best, bestDist = nil, math.huge
        -- Area identification uses all trees, but only at most once every 2 s.
        for t in pairs(self.trees) do
            local p = self:trunk(t)
            if p then
                local dx, dz = p.Position.X-pos.X, p.Position.Z-pos.Z
                local d = dx*dx+dz*dz
                if d < bestDist then bestDist,best = d,t end
            end
        end
        areaCache = (best and best:GetAttribute("AreaIndex")) or 1
        areaPos, areaAt = pos, os.clock()
        return areaCache
    end
    function C:pickTree()
        local pos = self:pos()
        if not pos then return nil end
        local maxD=self.config.maxTreeDistance
        local area=self.config.selectedArea=="Current" and self:area()
            or tonumber(self.config.selectedArea)
        local minX,maxX=math.floor((pos.X-maxD)/CELL),math.floor((pos.X+maxD)/CELL)
        local minZ,maxZ=math.floor((pos.Z-maxD)/CELL),math.floor((pos.Z+maxD)/CELL)
        local candidates={}
        local now=os.clock()
        for x=minX,maxX do
            for z=minZ,maxZ do
                local bucket=self.treeCells[x..":"..z]
                if bucket then
                    for tree in pairs(bucket) do
                        if self:treeOK(tree) and (not area or tree:GetAttribute("AreaIndex")==area)
                            and (self.failedTrees[tree] or 0)<self.config.maxFailures
                            and (self.blockedTrees[tree] or 0)<now
                            and (not self.config.eventOnly
                                or tree:GetAttribute("Biome")=="Graveyard"
                                or tostring(tree:GetAttribute("TreeType") or ""):find("^Haunted")) then
                            local part=self:trunk(tree)
                            if part then
                                local d=(part.Position-pos).Magnitude
                                if d<=maxD then
                                    local score=d
                                    if self.config.goldFirst and tree:GetAttribute("Mutation")=="Golden" then score=score-120 end
                                    candidates[#candidates+1]={tree=tree,part=part,score=score}
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(candidates,function(a,b) return a.score<b.score end)
        -- Only run monster proximity checks on candidates in distance order.
        for _,entry in ipairs(candidates) do
            if not (self.locationRisk and self:locationRisk(entry.part.Position)) then
                return entry.tree
            end
        end
        return nil
    end
    function C:logPart(log)
        if not log or log.Parent~=self.logFolder then return nil end
        if log:IsA("BasePart") then return log end
        if log:IsA("Model") then
            return log.PrimaryPart or log:FindFirstChildWhichIsA("BasePart",true)
        end
        return nil
    end
    local function addLog(obj)
        if obj.Name=="Log" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            C.drops[obj]=true
            C.logSpawnAt[obj] = os.clock()
        end
    end
    if C.logFolder then
        for _,obj in ipairs(C.logFolder:GetChildren()) do addLog(obj) end
        C:connect(C.logFolder.ChildAdded,addLog)
        C:connect(C.logFolder.ChildRemoved,function(obj)
            C.drops[obj]=nil; C.logSpawnAt[obj]=nil
        end)
    end
    function C:nearestLog(maxD,rejected,allowed)
        local pos=self:pos()
        if not pos then return nil end
        local best,distance=nil,nil
        for log in pairs(self.drops) do
            if not (rejected and rejected[log]) and (not allowed or allowed[log])
                and os.clock() - (self.logSpawnAt[log] or 0) >= self.config.logMinAge then
                local pt=self:logPart(log)
                if pt then
                    local d=(pt.Position-pos).Magnitude
                    if d<(maxD or 65) and (not distance or d<distance)
                        and not (self.locationRisk and self:locationRisk(pt.Position)) then
                        best,distance=log,d
                    end
                end
            end
        end
        return best,distance
    end
    function C:sellPos()
        local spot=self.sell
        if not spot or not spot.Parent then return nil end
        if spot:IsA("BasePart") then return spot.Position end
        if spot:IsA("Model") then
            local pad=spot:FindFirstChild("DepositPad",true)
            if pad and pad:IsA("BasePart") then return pad.Position end
            return spot:GetPivot().Position
        end
        return nil
    end
    function C:groundAt(position)
        local params=RaycastParams.new()
        local ch=self.player.Character
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=ch and {ch} or {}
        local hit=self.ws:Raycast(position+Vector3.new(0,5,0),Vector3.new(0,-28,0),params)
        return Vector3.new(position.X,hit and hit.Position.Y+3.1 or position.Y+3.1,position.Z)
    end
end
