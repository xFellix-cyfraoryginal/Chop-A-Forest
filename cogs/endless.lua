-- Click the observed RunEnd.Stage.Endless GUI button after PumpkinHead.
-- Grounded in V10 log: GUI_BUTTON_ACTIVATED => STARTING => EndlessRound.
return function(C)
    C.lastEndlessTry=-100
    C.endlessStarted=false
    local function shown(gui)
        if not gui or not gui.Parent then return false end
        if gui:IsA('ScreenGui') then return gui.Enabled end
        if gui:IsA('GuiObject') then return gui.Visible end
        return false
    end
    function C:endlessStep()
        if not self.cfg.combat or not self.running then return false end
        local pg=self.player:FindFirstChild('PlayerGui')
        local run=pg and pg:FindFirstChild('RunEnd')
        if not (run and run:IsA('ScreenGui') and shown(run)) then
            self.endlessStarted=false
            return false
        end
        local stage=run:FindFirstChild('Stage')
        if not (stage and shown(stage)) then return false end
        local button=stage:FindFirstChild('Endless')
        if not (button and button:IsA('GuiButton') and shown(button)) then
            self.stage='ENDLESS: waiting for button'
            task.wait(.12)
            return true
        end
        local label=button:FindFirstChildWhichIsA('TextLabel',true)
        if (label and tostring(label.Text):upper():find('STARTING',1,true)) or self.endlessStarted then
            self.stage='ENDLESS: starting next round'
            task.wait(.2)
            return true
        end
        if os.clock()-self.lastEndlessTry<2.4 then
            self.stage='ENDLESS: awaiting GUI response'
            task.wait(.12)
            return true
        end
        local size=button.AbsoluteSize
        if size.X<25 or size.Y<15 then
            self.stage='ENDLESS: button loading'
            task.wait(.1)
            return true
        end
        self.lastEndlessTry=os.clock()
        if self.stopHover then self:stopHover() end
        if self.clearWorkHover then self:clearWorkHover() end
        if self.releaseMouse then self:releaseMouse() end
        -- The V10 log confirms an actual mouse click on this GUI button.
        -- Use VIM first, because Activate() availability differs by client.
        local clicked=false
        local ok,vim=pcall(function() return game:GetService('VirtualInputManager') end)
        if ok and vim then
            local point=button.AbsolutePosition+button.AbsoluteSize*.5
            clicked=pcall(function()
                vim:SendMouseButtonEvent(point.X,point.Y,0,true,game,0)
                task.wait(.055)
                vim:SendMouseButtonEvent(point.X,point.Y,0,false,game,0)
            end)
        end
        if not clicked then
            clicked=pcall(function() button:Activate() end)
        end
        -- Only a confirmed starting banner counts as success.
        task.wait(.18)
        if label and tostring(label.Text):upper():find('STARTING',1,true) then
            self.endlessStarted=true
            self.combatFallback=false  -- a completed run is not a boss reset
            self.bossResetWatch=nil
            self.cfg.dodge=false
            self:note('ENDLESS: round start confirmed by GUI')
        else
            self:note(clicked and 'ENDLESS: clicked, awaiting confirmation'
                or 'ENDLESS: input unavailable, will retry')
        end
        return true
    end
end
