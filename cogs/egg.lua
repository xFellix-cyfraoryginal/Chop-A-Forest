-- V12: owner's Guardian drop; PICK only, never the paid EggPrompt.
return function(C)
    C.eggRetry={}
    C.eggReceived=0
    local RS=game:GetService('ReplicatedStorage')
    local notices=RS:FindFirstChild('PetEggs')
    local notice=notices and notices:FindFirstChild('EggNotice')
    if notice and notice:IsA('RemoteEvent') then
        C:connect(notice.OnClientEvent,function(data)
            if type(data)=='table' and data.Picked then
                C.eggReceived=C.eggReceived+1
                C.stats.eggs=(C.stats.eggs or 0)+1
                C:note('EGG PICKED: '..tostring(data.Picked))
            end
        end)
    end
    local function eggPos(model)
        local anchor=model:FindFirstChild('PromptAnchor',true)
        if anchor and anchor:IsA('BasePart') then return anchor.Position end
        local ok,p=pcall(function() return model:GetPivot().Position end)
        return ok and p or nil
    end
    function C:eggStep()
        if not self.cfg.combat then return false end
        local folder=self.ws:FindFirstChild('EggDrops')
        if not folder then return false end
        local egg, prompt=nil,nil
        for _,m in ipairs(folder:GetChildren()) do
            if m:IsA('Model') and tonumber(m:GetAttribute('Owner'))==self.player.UserId
                and os.clock()>=(self.eggRetry[m] or 0) then
                local p=m:FindFirstChild('PickPrompt',true)
                if p and p:IsA('ProximityPrompt') and p.Enabled then
                    egg,prompt=m,p; break
                end
            end
        end
        if not egg then return false end
        self.stage='EGG: collecting owner drop'
        if self.clearWorkHover then self:clearWorkHover() end
        if self.stopHover then self:stopHover() end
        local point=eggPos(egg)
        if not point then return false end
        -- A spawned egg falls from high up. Wait for it to land before prompt.
        local _,root=self:character()
        if not root then return true end
        if math.abs(point.Y-root.Position.Y)>12 then
            task.wait(.18); return true
        end
        self.postBossAction=true
        local reached=self:goTo(point,4)
        self.postBossAction=false
        if not reached then self.eggRetry[egg]=os.clock()+1; return true end
        point=eggPos(egg)
        local _,near=self:character()
        if not point or not near or (near.Position-point).Magnitude>math.max(3,prompt.MaxActivationDistance-1) then
            self.eggRetry[egg]=os.clock()+.5;return true
        end
        local count=self.eggReceived
        local triggered=false
        if type(fireproximityprompt)=='function' then
            triggered=pcall(function() fireproximityprompt(prompt) end)
            if triggered then
                local first=os.clock()+.50
                while self.running and egg.Parent and self.eggReceived==count
                    and os.clock()<first do task.wait(.05) end
            end
        end
        if self.eggReceived==count and egg.Parent then
            triggered=pcall(function()
                prompt:InputHoldBegin()
                task.wait(math.max(.45,prompt.HoldDuration+.1))
                prompt:InputHoldEnd()
            end)
        end
        local untilAt=os.clock()+.9
        while self.running and egg.Parent and self.eggReceived==count
            and os.clock()<untilAt do task.wait(.06) end
        if self.eggReceived>count or not egg.Parent then
            self:note('EGG: pickup confirmed')
        else
            self:note('EGG: pickup not confirmed, retrying later')
            self.eggRetry[egg]=os.clock()+2.5
        end
        return true
    end
end
