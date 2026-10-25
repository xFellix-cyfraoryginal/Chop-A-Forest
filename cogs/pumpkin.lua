-- V10: after Jack dies, the target is Workspace.JackLantern.PumpkinHead.
-- Not decor pumpkins, and no automatic Endless clicks.
return function(C)
    C.nextPumpkinWarn=0
    function C:postBossStep()
        if not self.cfg.combat then return false end
        local pg=self.player:FindFirstChild('PlayerGui')
        local screen=pg and pg:FindFirstChild('PumpkinChop')
        if not (screen and screen:IsA('ScreenGui') and screen.Enabled) then
            return false
        end
        self.stage='POST-BOSS: pumpkin head'
        local jack=self.ws:FindFirstChild('JackLantern')
        local head=jack and jack:FindFirstChild('PumpkinHead',true)
        if not (head and head:IsA('BasePart')) then
            if os.clock()>self.nextPumpkinWarn then
                self.nextPumpkinWarn=os.clock()+4
                self:note('PumpkinChop active; waiting for PumpkinHead')
            end
            task.wait(.2)
            return true
        end
        local before=tonumber(self.player:GetAttribute('PumpkinDamage')) or 0
        self.postBossAction=true
        local reached=self:goTo(head.Position,3.8)
        self.postBossAction=false
        if not reached or not self.running then return true end
        self.stage='POST-BOSS: hitting pumpkin head'
        local hit=self:useItem(function()
            return head.Parent and head.Position or nil
        end,'Combat')
        if hit then
            local deadline=os.clock()+.7
            while self.running and screen.Enabled and os.clock()<deadline do
                if (tonumber(self.player:GetAttribute('PumpkinDamage')) or 0)>before then
                    return true
                end
                task.wait(.08)
            end
        end
        if os.clock()>self.nextPumpkinWarn then
            self.nextPumpkinWarn=os.clock()+3
            self:note('Pumpkin: no damage confirmed; adjusting/retrying')
        end
        task.wait(.12)
        return true
    end
end
