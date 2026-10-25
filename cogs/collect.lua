-- Confirm pickups through the actual backpack HUD; unfinished jobs persist.
return function(C)
    function C:collectLogs()
        if not self.config.autoCollect then return 0 end
        local grabbed, attempts = 0, 0
        while self.running and self.alive and not self.safetyAlert and attempts<35 do
            local bag,cap=self:backpack()
            if bag==nil then self:note('error','Brak plecaka HUD'); break end
            if cap and bag>=cap then break end
            local log,dist=self:nearestReadyLog(self.config.maxLogDistance)
            if not log then break end
            local part=self:logPart(log)
            if not part then break end
            attempts=attempts+1
            self.stage='Collect '..tostring(bag)..'/'..tostring(cap or '?')
            local reached=self:move(part.Position,self.config.pickupDistance)
            if not self.running or self.safetyAlert then break end
            if not reached then
                self:logRetry(log,'nie moge dojsc')
            else
                local successful=false
                for attempt=1,self.config.pickupRetries do
                    if not self.running or self.safetyAlert or not self:logPart(log) then break end
                    local pos=self:pos()
                    part=self:logPart(log)
                    if not pos or not part then break end
                    if (pos-part.Position).Magnitude>self.config.pickupDistance+1.6 then
                        if not self:move(part.Position,self.config.pickupDistance) then break end
                    end
                    if not self.running or self.safetyAlert then break end
                    self:face(part.Position)
                    task.wait(.08)
                    if not self:click() then
                        if not self.safetyAlert then self:logRetry(log,'klik nieudany') end
                        break
                    end
                    local timeout=os.clock()+math.max(.45,self.config.pickupDelay+.18)
                    while self.running and not self.safetyAlert and os.clock()<timeout do
                        local after=self:backpack()
                        if after and after<bag then
                            self:note('warn','Klik wyrzucil klode; pauzuje pickup')
                            self:logRetry(log,'wyrzucilo drewno')
                            return grabbed
                        end
                        if after and after>bag then
                            local delta=after-bag
                            self.stats.pickups=self.stats.pickups+delta
                            grabbed=grabbed+delta
                            successful=true
                            self:logClaimed(log)
                            self:note('pickup','+'..delta..' bag='..after)
                            break
                        end
                        task.wait(.065)
                    end
                    if successful then break end
                end
                if not successful and not self.safetyAlert and self:logPart(log) then
                    self:logRetry(log,'brak przyrostu plecaka')
                end
            end
            if not self.running or self.safetyAlert then break end
            task.wait(.08)
        end
        return grabbed
    end

    function C:sellLogs()
        if not self.config.autoSell then return false end
        local before=self:backpack()
        if not before or before<=0 then return true end
        local target=self:sellPos()
        if not target then self:note('error','Brak SellSpot'); return false end
        self.stage='Sell'
        if not self:move(target,3.6) then
            self:note('warn','Sell: dojscie nieudane'); return false
        end
        for n=1,3 do
            if not self.running or self.safetyAlert then return false end
            local now=self:backpack()
            if now==0 then
                self.stats.sold=self.stats.sold+1
                self:note('sell','Sprzedane: '..before)
                return true
            end
            self:face(target)
            task.wait(.09)
            self:click()
            local deadline=os.clock()+.9
            while self.running and not self.safetyAlert and os.clock()<deadline do
                if self:backpack()==0 then
                    self.stats.sold=self.stats.sold+1
                    self:note('sell','Depozyt: '..before)
                    return true
                end
                task.wait(.09)
            end
            if n<3 then self:move(target,2.3) end
        end
        self:note('warn','Sell bez potwierdzenia; bag='..tostring(self:backpack()))
        return false
    end
end
