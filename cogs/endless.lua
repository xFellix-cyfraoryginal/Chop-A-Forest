-- V4.8.7: fix UI top inset (V10 user click Y=754 vs btn Y~695).
-- All approaches use the REAL existing RunEnd.Stage.Endless button.
return function(C)
    C.lastEndlessTry=-100
    C.endlessStarted=false
    C.endlessAttempt=0
    local GuiService=game:GetService('GuiService')
    local function visible(node)
        if not node or not node.Parent then return false end
        local curr=node
        while curr and curr~=game do
            if curr:IsA('ScreenGui') then
                if not curr.Enabled then return false end
                break
            elseif curr:IsA('GuiObject') and not curr.Visible then
                return false
            end
            curr=curr.Parent
        end
        return true
    end
    local function buttonText(btn)
        for _,node in ipairs(btn:GetDescendants()) do
            if (node:IsA('TextLabel') or node:IsA('TextButton'))
                and type(node.Text)=='string' then
                local t=node.Text:upper()
                if t:find('STARTING',1,true) then return 'STARTING' end
                if t:find('ENDLESS',1,true) then return 'ENDLESS' end
            end
        end
        return 'UNKNOWN'
    end
    local function clickAt(x,y)
        local ok,vim=pcall(function() return game:GetService('VirtualInputManager') end)
        if not ok or not vim then return false end
        return pcall(function()
            pcall(function() vim:SendMouseMoveEvent(x,y,game) end)
            task.wait(.025)
            vim:SendMouseButtonEvent(x,y,0,true,game,0)
            task.wait(.085)
            vim:SendMouseButtonEvent(x,y,0,false,game,0)
        end)
    end
    local function clickButton(btn,attempt)
        local center=btn.AbsolutePosition+btn.AbsoluteSize*.5
        local inset=Vector2.zero
        pcall(function() inset=GuiService:GetGuiInset() end)
        -- Log V10 confirms manual mouse Y was ~58 px LOWER than
        -- the GuiObject.AbsolutePosition-based center. Try adjusted first.
        local y=center.Y+inset.Y
        if inset.Y<=2 then y=center.Y+58 end
        local mode=(attempt-1)%3
        if mode==0 then
            return clickAt(center.X,y),'mouse + GUI inset'
        elseif mode==1 then
            return clickAt(center.X,center.Y),'mouse viewport'
        else
            -- Prefer game input over synthetic events. Some executors
            -- expose getconnections or firesignal, so try once as fallback.
            local ok=false
            if type(firesignal)=='function' then
                ok=pcall(function() firesignal(btn.Activated) end)
                if not ok then ok=pcall(function() firesignal(btn.MouseButton1Click) end) end
            end
            if not ok then
                local success=pcall(function() btn:Activate() end)
                ok=success
            end
            return ok,'signal / Activate'
        end
    end
    function C:endlessStep()
        if not self.cfg.combat or not self.running then return false end
        local pg=self.player:FindFirstChild('PlayerGui')
        local run=pg and pg:FindFirstChild('RunEnd')
        if not (run and run:IsA('ScreenGui') and run.Enabled) then
            self.endlessStarted=false
            self.endlessAttempt=0
            return false
        end
        local stage=run:FindFirstChild('Stage')
        local btn=stage and stage:FindFirstChild('Endless')
        if not (btn and btn:IsA('GuiButton') and visible(btn)) then
            self.stage='ENDLESS: waiting for button to appear'
            task.wait(.10)
            return true
        end
        if buttonText(btn)=='STARTING' then
            if not self.endlessStarted then
                self.endlessStarted=true
                self:note('ENDLESS: STARTING confirmed')
            end
            self.stage='ENDLESS: loading next round'
            self.combatFallback=false
            self.bossResetWatch=nil
            task.wait(.12)
            return true
        end
        if self.endlessStarted then
            -- If UI returns from STARTING to ENDLESS, do not wait forever.
            self.endlessStarted=false
        end
        if btn.AbsoluteSize.X<25 or btn.AbsoluteSize.Y<15 then
            self.stage='ENDLESS: button scaling into view'
            task.wait(.10)
            return true
        end
        if os.clock()-self.lastEndlessTry<.75 then
            self.stage='ENDLESS: awaiting game acknowledgment (retry armed)'
            task.wait(.08)
            return true
        end
        self.lastEndlessTry=os.clock()
        self.endlessAttempt=self.endlessAttempt+1
        if self.stopHover then self:stopHover() end
        if self.clearWorkHover then self:clearWorkHover() end
        if self.releaseMouse then self:releaseMouse() end
        local ok,method=clickButton(btn,self.endlessAttempt)
        self.stage='ENDLESS: click attempt '..self.endlessAttempt
        self:note(self.stage..' ('..method..'; '..tostring(ok)..')')
        task.wait(.14)
        return true
    end
end
