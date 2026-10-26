-- V4.8.6: robust Endless button input with progressive fallbacks.
-- V10 confirms RunEnd.Stage.Endless -> STARTING... -> EndlessRound.
return function(C)
    C.lastEndlessTry=-100
    C.endlessStarted=false
    C.endlessAttempt=0
    local function shown(obj)
        if not obj or not obj.Parent then return false end
        if obj:IsA('ScreenGui') then return obj.Enabled end
        if obj:IsA('GuiObject') then return obj.Visible end
        return false
    end
    local function starting(btn)
        for _,node in ipairs(btn:GetDescendants()) do
            if node:IsA('TextLabel') and
                tostring(node.Text):upper():find('STARTING',1,true) then
                return true
            end
        end
        return false
    end
    local function activateByMouse(btn)
        local ok,vim=pcall(function() return game:GetService('VirtualInputManager') end)
        if not ok or not vim then return false end
        local pos=btn.AbsolutePosition+btn.AbsoluteSize*.5
        return pcall(function()
            vim:SendMouseButtonEvent(pos.X,pos.Y,0,true,game,0)
            task.wait(.07)
            vim:SendMouseButtonEvent(pos.X,pos.Y,0,false,game,0)
        end)
    end
    local function activateDirect(btn)
        local ok=pcall(function() btn:Activate() end)
        return ok
    end
    -- Last resort when injected mouse input cannot reach game UI.
    -- Do not call every frame; one pass only per retry.
    local function activateConnections(btn)
        local worked=false
        if type(firesignal)=='function' then
            worked=pcall(function() firesignal(btn.MouseButton1Click) end)
        end
        if not worked and type(getconnections)=='function' then
            local ok,cons=pcall(getconnections,btn.MouseButton1Click)
            if ok and type(cons)=='table' then
                for _,conn in ipairs(cons) do
                    if type(conn.Function)=='function' then
                        local result=pcall(conn.Function)
                        worked=worked or result
                    end
                end
            end
        end
        return worked
    end
    function C:endlessStep()
        if not self.cfg.combat or not self.running then return false end
        local pg=self.player:FindFirstChild('PlayerGui')
        local run=pg and pg:FindFirstChild('RunEnd')
        if not (run and run:IsA('ScreenGui') and shown(run)) then
            self.endlessStarted=false
            self.endlessAttempt=0
            return false
        end
        local stage=run:FindFirstChild('Stage')
        if not (stage and shown(stage)) then
            self.stage='ENDLESS: waiting for visible results'
            task.wait(.11)
            return true
        end
        local btn=stage:FindFirstChild('Endless')
        if not (btn and btn:IsA('GuiButton') and shown(btn)) then
            self.stage='ENDLESS: waiting for Endless button'
            task.wait(.11)
            return true
        end
        if starting(btn) then
            self.endlessStarted=true
            self.stage='ENDLESS: STARTING confirmed'
            self.combatFallback=false
            self.bossResetWatch=nil
            self.cfg.dodge=true
            task.wait(.12)
            return true
        end
        if self.endlessStarted then
            self.stage='ENDLESS: waiting for next round'
            task.wait(.12)
            return true
        end
        if os.clock()-self.lastEndlessTry<1.5 then
            self.stage='ENDLESS: awaiting confirmation'
            task.wait(.12)
            return true
        end
        if btn.AbsoluteSize.X<25 or btn.AbsoluteSize.Y<15 then
            self.stage='ENDLESS: waiting for button layout'
            task.wait(.11)
            return true
        end
        self.lastEndlessTry=os.clock()
        self.endlessAttempt=self.endlessAttempt+1
        if self.stopHover then self:stopHover() end
        if self.clearWorkHover then self:clearWorkHover() end
        if self.releaseMouse then self:releaseMouse() end
        local method=(self.endlessAttempt-1)%3
        local methodLabel=method==0 and 'mouse' or method==1 and 'Activate' or 'signal'
        local ok=false
        if method==0 then ok=activateByMouse(btn)
        elseif method==1 then ok=activateDirect(btn)
        else ok=activateConnections(btn) end
        task.wait(.19)
        if starting(btn) then
            self.endlessStarted=true
            self.combatFallback=false
            self.bossResetWatch=nil
            self.cfg.dodge=true
            self:note('ENDLESS: STARTING confirmed via '..methodLabel)
        else
            self:note('ENDLESS: '..methodLabel..' attempt '..self.endlessAttempt
                ..(ok and ', awaiting game ack' or ' failed; fallback next'))
        end
        return true
    end
end
