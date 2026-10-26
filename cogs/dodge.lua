-- V4.5: server telegraph dodge. Observes inbound MonsterFx only (no hooks).
-- Warn packets contain true server-supplied Circle/Line geometry and delay.
return function(C)
    C.hazards, C.dodgeHoldUntil, C.dodgeLastAt = {}, 0, -100
    C.dodgeAudit = {}
    C.stats.dodges = 0
    C.cfg.dodge = true  -- Always check server Warn geometry, including during HP Pause
    local RunService = game:GetService('RunService')
    local RS = game:GetService('ReplicatedStorage')
    local chop = RS:FindFirstChild('Shared')
    chop = chop and chop:FindFirstChild('Services')
    chop = chop and chop:FindFirstChild('ChopRemotes')
    local remote = chop and chop:FindFirstChild('MonsterFx')
    local function vec(data)
        if typeof(data)=='Vector3' then return data end
        if type(data)~='table' then return nil end
        if type(data.x)=='number' and type(data.z)=='number' then
            return Vector3.new(data.x,tonumber(data.y) or 0,data.z)
        end
        if type(data.X)=='number' and type(data.Z)=='number' then
            return Vector3.new(data.X,tonumber(data.Y) or 0,data.Z)
        end
    end
    local function flat(point)
        return Vector3.new(point.X,0,point.Z)
    end
    local function lineInfo(h)
        local direction=flat(h.direction)
        if direction.Magnitude<.0001 then return nil end
        return direction.Unit
    end
    local function inside(h,p,margin)
        if h.shape=='Circle' then
            return (flat(p)-flat(h.at)).Magnitude <= h.radius+margin
        end
        if h.shape=='Line' then
            local dir=lineInfo(h)
            if not dir then return false end
            local delta=flat(p)-flat(h.at)
            local along=delta:Dot(dir)
            local across=(delta-dir*along).Magnitude
            return along>=-margin and along<=h.length+margin
                and across<=h.width*.5+margin
        end
        return false
    end
    local function prune(now)
        for i=#C.hazards,1,-1 do
            if C.hazards[i].expires<=now then table.remove(C.hazards,i) end
        end
    end
    function C:isDodging()
        return self.live and self.running and self.cfg.dodge
            and os.clock()<(self.dodgeHoldUntil or 0)
    end
    local function safe(p,now)
        for _,h in ipairs(C.hazards) do
            if h.expires>now and inside(h,p,3.2) then return false end
        end
        return true
    end
    local function escapePoint(pos,now)
        local candidates={}
        for _,h in ipairs(C.hazards) do
            if h.expires>now and inside(h,pos,3.2) then
                if h.shape=='Circle' then
                    local d=flat(pos)-flat(h.at)
                    if d.Magnitude<.01 then d=Vector3.new(1,0,0) end
                    candidates[#candidates+1]=flat(h.at)+d.Unit*(h.radius+5)
                elseif h.shape=='Line' then
                    local dir=lineInfo(h)
                    if dir then
                        local delta=flat(pos)-flat(h.at)
                        local along=math.clamp(delta:Dot(dir),0,h.length)
                        local side=Vector3.new(-dir.Z,0,dir.X)
                        if delta:Dot(side)<0 then side=-side end
                        local axis=flat(h.at)+dir*along
                        candidates[#candidates+1]=axis+side*(h.width*.5+5)
                        candidates[#candidates+1]=axis-side*(h.width*.5+5)
                    end
                end
            end
        end
        -- Try the shortest displacement; extended rings handle overlapping AoEs.
        for _,r in ipairs({7,13,22,30,44,64}) do
            for i=0,15 do
                local a=(i/16)*math.pi*2
                candidates[#candidates+1]=flat(pos)+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
            end
        end
        local best,dist=nil,math.huge
        for _,p in ipairs(candidates) do
            local candidate=Vector3.new(p.X,pos.Y,p.Z)
            if safe(candidate,now) then
                local d=(flat(candidate)-flat(pos)).Magnitude
                if d<dist then best,dist=candidate,d end
            end
        end
        return best
    end
    function C:dodgeTick()
        if not self.live or not self.running or not self.cfg.dodge then return end
        local now=os.clock()
        prune(now)
        if #self.hazards==0 or now-self.dodgeLastAt<.075 then return end
        local _,root,hum=self:character()
        if not root or not hum or safe(root.Position,now) then return end
        local target=escapePoint(root.Position,now)
        if not target then
            if now-self.dodgeLastAt>.5 then self:note('DODGE: no clear landing spot') end
            self.dodgeLastAt=now; return
        end
        local expiry=now+.2
        local threatKind='Unknown'
        for _,h in ipairs(self.hazards) do
            if h.expires>now and inside(h,root.Position,3.2) then
                threatKind=h.kind; break
            end
        end
        for _,h in ipairs(self.hazards) do
            if h.expires>now and inside(h,root.Position,3.2) then
                expiry=math.max(expiry,h.expires+.12)
            end
        end
        -- Never dodge an AoE drawn far from the player. The geometry is
        -- checked at the current position, not merely because Warn exists.
        self.dodgeHoldUntil=math.max(self.dodgeHoldUntil,expiry)
        self.dodgeLastAt=now
        self.motion=self.motion+1 -- invalidate older Walk / TP route
        if self.releaseMouse then self:releaseMouse() end
        local old=root.Position
        if self.skyHoldPosition and self:isPaused() then
            self.skyHoldPosition=target -- safety Heartbeat now follows the escape
        end
        root.CFrame=CFrame.new(target)*root.CFrame.Rotation
        hum:MoveTo(target)
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        self.stats.dodges=self.stats.dodges+1
        local audit=self.dodgeAudit
        audit[#audit+1]={kind=threatKind,at=now,
            from={x=old.X,z=old.Z},to={x=target.X,z=target.Z}}
        if #audit>35 then table.remove(audit,1) end
        self.stage='DODGE: moving outside red warning'
    end
    function C:trackWarning(action,data)
        if not self.live or not self.cfg.dodge or type(data)~='table' then return end
        local shape=data.Shape
        if action=='FireTrail' then shape='Line' end
        if action~='Warn' and action~='FireTrail' then return end
        if shape~='Circle' and shape~='Line' then return end
        local at=vec(data.At or data.From)
        if not at then return end
        local h={shape=shape,at=at,kind=tostring(data.Kind or action),
            expires=os.clock()+math.clamp(tonumber(data.Time) or .5,.1,7)}
        if shape=='Circle' then
            h.radius=tonumber(data.Radius)
            if not h.radius or h.radius<=0 then return end
        else
            h.direction=vec(data.Dir)
            h.length=tonumber(data.Length)
            h.width=tonumber(data.Width)
            if not h.direction or not h.length or not h.width
                or h.length<=0 or h.width<=0 then return end
        end
        self.hazards[#self.hazards+1]=h
        if #self.hazards>45 then table.remove(self.hazards,1) end
        self:dodgeTick() -- react immediately; shortest Bite warning is 0.45s
    end
    if remote and remote:IsA('RemoteEvent') then
        C:connect(remote.OnClientEvent,function(action,payload)
            if action=='Warn' or action=='FireTrail' then
                C:trackWarning(action,payload)
            end
        end)
        C:note('MonsterFx dodge ready (Circle / Line)')
    else
        C:note('MonsterFx missing: red-zone dodge unavailable')
    end
    C:connect(RunService.Heartbeat,function()
        if C.live and C.running and #C.hazards>0 then C:dodgeTick() end
    end)
end
