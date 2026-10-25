-- V10 verified: Workspace.JackLantern.PumpkinHead; RunEnd.Stage.Endless.
return function(C)
    C.nextEndlessTry=0
    C.endlessClicks=0
    function C:postBossStep()
        if not self.cfg.autoEndless then return false end
        local pg=self.player:FindFirstChild('PlayerGui')
        local run=pg and pg:FindFirstChild('RunEnd')
        local stage=run and run:FindFirstChild('Stage')
        local endless=stage and stage:FindFirstChild('Endless')
        if endless and endless:IsA('GuiButton') and run.Enabled
            and stage.Visible and endless.Visible then
            if os.clock()<self.nextEndlessTry then return true end
            self.nextEndlessTry=os.clock()+7
            self.stage='RUN END: selecting Endless'
            if self:gameClick(endless) then
                self.endlessClicks=self.endlessClicks+1
                self:note('Endless clicked (awaiting next round)')
            else self:note('Endless: executor GUI input unavailable') end
            return true
        end
        local pumpkinGui=pg and pg:FindFirstChild('PumpkinChop')
        if not pumpkinGui or not pumpkinGui.Enabled then return false end
        self.stage='BOSS REWARD: smashing pumpkin'
        local jack=self.ws:FindFirstChild('JackLantern')
        local head=jack and jack:FindFirstChild('PumpkinHead',true)
        if not head or not head:IsA('BasePart') then
            self:note('PumpkinChop active, JackLantern.PumpkinHead not found')
            task.wait(.35)
            return true
        end
        local at=head.Position
        self.postBossAction=true
        local reached=self:goTo(at,4.0)
        self.postBossAction=false
        if not reached or not self.running then return true end
        local previous=self.player:GetAttribute('PumpkinDamage') or 0
        -- Existing axe swing uses the game's input, verified in V10.
        local hit=self:useItem(at,'Combat')
        if hit then
            local untilAt=os.clock()+.55
            while self.running and pumpkinGui.Enabled and os.clock()<untilAt do
                if (self.player:GetAttribute('PumpkinDamage') or 0)>previous then
                    return true
                end
                task.wait(.07)
            end
        end
        self:note('Pumpkin: awaiting registered hit')
        return true
    end
end
