-- Wait until severed logs exist AND stop shifting after the falling animation.
return function(C)
    function C:waitForWood(tree)
        local trunk = self:trunk(tree)
        local origin = trunk and trunk.Position or self:pos()
        local kind = tree and tree:GetAttribute("TreeType")
        local settled = {}
        local tracked, lastSpawn, stableSince = {}, os.clock(), nil
        local began = os.clock()
        local latest = began
        self.stage = "Waiting for falling logs"
        while self.running and not self.safetyAlert
            and os.clock() - began < self.config.logSettleTimeout do
            local changed, count = false, 0
            for log in pairs(self.drops) do
                local pt = self:logPart(log)
                if pt and origin and (pt.Position-origin).Magnitude < 72
                    and (not self.preFellLogs or not self.preFellLogs[log])
                    and (not kind or log:GetAttribute("TreeType") == kind) then
                    count = count + 1
                    if not tracked[log] then
                        tracked[log] = pt.Position
                        lastSpawn = os.clock()
                        changed = true
                    elseif (tracked[log] - pt.Position).Magnitude > 0.26 then
                        tracked[log] = pt.Position
                        changed = true
                    end
                end
            end
            for log in pairs(tracked) do
                if not self:logPart(log) then
                    tracked[log] = nil
                    changed = true
                end
            end
            if changed then stableSince = nil
            elseif count > 0 then stableSince = stableSince or os.clock() end
            local allAged = count > 0
            for log in pairs(tracked) do
                if os.clock() - (self.logSpawnAt[log] or began) < self.config.logMinAge then
                    allAged = false; break
                end
            end
            if os.clock()-began >= math.max(1.15,self.config.logMinAge)
                and allAged and stableSince
                and os.clock()-stableSince >= self.config.logSettleTime
                and os.clock()-lastSpawn >= .5 then
                for log in pairs(tracked) do
                    if self:logPart(log) then settled[log] = true end
                end
                self:note("collect", "Klod ustabilizowanych: " .. tostring(count)
                    .. "; wait " .. string.format("%.1fs", os.clock()-began))
                return settled
            end
            task.wait(.18)
        end
        for log in pairs(tracked) do
            if self:logPart(log) then settled[log] = true end
        end
        self:note("warn", "Animacja scinania: timeout/alert po "
            .. string.format("%.1fs", os.clock()-began))
        return settled
    end
end
