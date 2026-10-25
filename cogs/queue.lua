-- Persistent wood backlog: never forget a spawned log after retreat/failure.
return function(C)
    C.woodJobs = {}
    local jobs = C.woodJobs
    local clock = os.clock

    local function track(log)
        if not (log and C:logPart(log)) then return end
        if jobs[log] then return end
        local part = C:logPart(log)
        local born = C.logSpawnAt[log] or clock()
        jobs[log] = {born=born, lastPos=part.Position,
            lastLook=part.CFrame.LookVector, stableAt=clock(), retryAt=0, tries=0}
    end

    for log in pairs(C.drops) do track(log) end
    if C.logFolder then
        C:connect(C.logFolder.ChildAdded, track)
        C:connect(C.logFolder.ChildRemoved, function(log) jobs[log]=nil end)
    end

    -- No per-log Heartbeat connections; one low-frequency sampler for all logs.
    task.spawn(function()
        while C.alive do
            task.wait(C.running and .23 or .7)
            if not C.alive then break end
            local now = clock()
            for log in pairs(C.drops) do
                if not jobs[log] then track(log) end
            end
            for log, state in pairs(jobs) do
                local part = C:logPart(log)
                if not part then
                    jobs[log] = nil
                else
                    local moved=(part.Position-state.lastPos).Magnitude
                    local dot=math.clamp(part.CFrame.LookVector:Dot(state.lastLook), -1, 1)
                    if moved > .19 or dot < .985 then state.stableAt = now end
                    state.lastPos=part.Position
                    state.lastLook=part.CFrame.LookVector
                end
            end
        end
    end)

    function C:logReady(log)
        local s=jobs[log]
        if not s or not self:logPart(log) then return false end
        local now=clock()
        return now-s.born >= self.config.logMinAge
            and now-s.stableAt >= self.config.logSettleTime
    end

    function C:logClaimed(log)
        local s=jobs[log]
        if s then
            s.tries=0
            -- Let the server remove the object; don't click the same log twice.
            s.retryAt=clock()+1.6
        end
    end

    function C:logRetry(log,reason)
        local s=jobs[log]
        if not s then return end
        s.tries=s.tries+1
        local cooldown=math.min(12, 1.2*2^math.min(s.tries-1, 4))
        s.retryAt=clock()+cooldown
        if s.tries==1 or s.tries%3==0 then
            self:note('pickup', 'Odkladam klode na '..string.format('%.1f',cooldown)
                ..'s, ale nadal pamietam ('..tostring(reason)..')')
        end
    end

    function C:woodStatus(maxDistance)
        local p=self:pos()
        local stats={total=0,ready=0,settling=0,risky=0,cooling=0}
        if not p then return stats end
        for log,s in pairs(jobs) do
            local part=self:logPart(log)
            if part and (part.Position-p).Magnitude<=(maxDistance or self.config.maxLogDistance) then
                stats.total=stats.total+1
                if not self:logReady(log) then
                    -- Perpetually moving physics must not freeze the scheduler.
                    if clock()-s.born>self.config.logSettleTimeout+1.5 then
                        stats.cooling=stats.cooling+1
                    else
                        stats.settling=stats.settling+1
                    end
                elseif self.locationRisk and self:locationRisk(part.Position) then
                    stats.risky=stats.risky+1
                elseif clock()<s.retryAt then
                    stats.cooling=stats.cooling+1
                else
                    stats.ready=stats.ready+1
                end
            end
        end
        return stats
    end

    function C:nearestReadyLog(maxDistance)
        local p=self:pos()
        if not p then return nil end
        local chosen,distance
        local now=clock()
        for log,s in pairs(jobs) do
            if now >= s.retryAt and self:logReady(log) then
                local part=self:logPart(log)
                if part then
                    local d=(part.Position-p).Magnitude
                    if d <= (maxDistance or self.config.maxLogDistance)
                        and (not distance or d<distance)
                        and not (self.locationRisk and self:locationRisk(part.Position)) then
                        chosen,distance=log,d
                    end
                end
            end
        end
        return chosen,distance
    end
end
