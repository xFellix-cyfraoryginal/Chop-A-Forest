-- CropForest: pickup and sell verified through backpack HUD, no fake success on proximity
return function(C)
    function C:collectLogs()
        if not self.config.autoCollect then return end
        self.stage = "Collect"
        local rejected, attempts, gathered = {}, 0, 0
        -- Spawns can arrive after the Felled attribute has been replicated.
        local spawnDeadline = os.clock() + 2.3
        while self.running and self.alive and os.clock() < spawnDeadline do
            if self:nearestLog(90) then break end
            task.wait(0.13)
        end
        while self.running and self.alive and not self.safetyAlert and attempts < 42 do
            local before, capacity = self:backpack()
            if before == nil then
                self:note("error", "Brak licznika plecaka; pomijam pickup")
                return gathered
            end
            if capacity and before >= capacity then return gathered end
            local log, distance = self:nearestLog(90, rejected)
            if not log then break end
            local part = self:logPart(log)
            if not part then
                rejected[log] = true
            else
            attempts = attempts + 1
            local target = part.Position
            self.stage = "Pickup " .. tostring(before) .. "/" .. tostring(capacity or "?")
            local reached = self:move(target, self.config.pickupDistance)
            if not reached then
                rejected[log] = true
                self:note("warn", "Nie dotarlem do klody (" .. math.floor(distance or 0) .. " studs)")
            else
            -- On V7 pickups worked with MouseLeft and no prompt. Aim at the nearby log.
            local success = false
            for try = 1, self.config.pickupRetries do
                if not self.running or not self.alive or self.safetyAlert
                    or not self:logPart(log) then break end
                local root = self:pos()
                if not root then break end
                if (root - part.Position).Magnitude > self.config.pickupDistance + 2 then
                    if not self:move(part.Position, self.config.pickupDistance) then break end
                end
                self:face(part.Position)
                task.wait(0.10)
                if not self:click() then
                    self:note("error", "Brak symulacji klikniecia (VIM/mouse1click)")
                    return gathered
                end
                local deadline = os.clock() + math.max(0.45, self.config.pickupDelay + 0.18)
                while self.running and os.clock() < deadline do
                    local after = self:backpack()
                    if after and after < before then
                        self:note("warn", "Klikniecie WYRZUCILO klode! Przerywam serie pickup")
                        return gathered
                    end
                    if after and after > before then
                        local diff = after - before
                        self.stats.pickups = self.stats.pickups + diff
                        gathered = gathered + diff
                        self:note("pickup", "+" .. diff .. " log; bag=" .. tostring(after))
                        success = true
                        break
                    end
                    -- A log can disappear because another player took it; HUD is authoritative.
                    if not self:logPart(log) then break end
                    task.wait(0.07)
                end
                if success then break end
            end
            if not success then
                rejected[log] = true
                self:note("warn", "Kloda nie dodala sie do plecaka (id="
                    .. tostring(log:GetAttribute("Index") or "?") .. ")")
            end
            end -- reached
            task.wait(0.08)
            end -- valid log part
        end
        return gathered
    end

    function C:sellLogs()
        if not self.config.autoSell then return false end
        local before = self:backpack()
        if not before or before <= 0 then return true end
        local sellPosition = self:sellPos()
        if not sellPosition then
            self:note("error", "Brak Workspace.Map.SellSpot / DepositPad")
            return false
        end
        self.stage = "Sell"
        if not self:move(sellPosition, 3.6) then
            self:note("warn", "Nie dotarlem do Sell")
            return false
        end
        for attempt = 1, 3 do
            if not self.running or self.safetyAlert then return false end
            local now = self:backpack()
            if now == 0 then
                self.stats.sold = self.stats.sold + 1
                self:note("sell", "Sprzedano " .. tostring(before) .. " klod")
                return true
            end
            self:face(sellPosition)
            task.wait(0.10)
            self:click()
            local deadline = os.clock() + 0.9
            while self.running and os.clock() < deadline do
                now = self:backpack()
                if now == 0 then
                    self.stats.sold = self.stats.sold + 1
                    self:note("sell", "Depozyt zatwierdzony: " .. tostring(before))
                    return true
                end
                task.wait(0.10)
            end
            if attempt < 3 then self:move(sellPosition, 2.2) end
        end
        self:note("warn", "Sell nie oproznil plecaka; zachowano " .. tostring(self:backpack()))
        return false
    end
end
