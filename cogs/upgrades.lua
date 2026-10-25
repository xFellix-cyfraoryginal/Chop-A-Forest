-- Auto-upgrade via real TAB GUI, not guessed BuyUpgrade arguments.
-- Only Axe Speed/Sharpness are enabled; costs read from UI when possible.
return function(C)
    C.nextUpgradeTry=0
    C.upgradeChoice='Speed'
    local function cash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local obj=stats and stats:FindFirstChild('Cash')
        return obj and obj.Value or 0
    end
    local function visible(obj)
        local it=obj
        while it do
            if it:IsA('ScreenGui') and not it.Enabled then return false end
            if it:IsA('GuiObject') and not it.Visible then return false end
            it=it.Parent
        end
        return obj~=nil
    end
    local function findCard(page,text)
        if not page then return nil end
        local axe=page:FindFirstChild('Axe')
        if not axe then return nil end
        for _,card in ipairs(axe:GetDescendants()) do
            if card.Name=='Card' and card:IsA('GuiObject') then
                local title=card:FindFirstChild('Title',true)
                if title and title:IsA('TextLabel') and title.Text==text then
                    local amount=card:FindFirstChild('Amount',true)
                    return card,title,amount
                end
            end
        end
    end
    function C:upgradeStep()
        if not self.cfg.autoUpgrade or os.clock()<self.nextUpgradeTry then return false end
        local speed=self.player:GetAttribute('Up_AxeSpeed') or 0
        local sharp=self.player:GetAttribute('Up_AxeSharp') or 0
        local wanted,level,key
        if speed<=sharp then wanted,level,key='Speed',speed,'Up_AxeSpeed'
        else wanted,level,key='Sharpness',sharp,'Up_AxeSharp' end
        -- Verified V9 price ladder for first two levels only. Higher levels
        -- require a LIVE amount from UI, never speculative in-game purchases.
        local known=level==0 and 75 or level==1 and 125 or nil
        if known and cash(self)<known then return false end
        self.nextUpgradeTry=os.clock()+24
        local pg=self.player:FindFirstChild('PlayerGui')
        local gui=pg and pg:FindFirstChild('Upgrades')
        local panel=gui and gui:FindFirstChild('Panel')
        if not panel then return false end
        -- Click game's HUD button to open instead of changing Enabled locally.
        if not gui.Enabled then
            local hud=pg:FindFirstChild('HudButtons')
            local up=hud and hud:FindFirstChild('Upgrades',true)
            if up and not self:gameClick(up) then return false end
            task.wait(.2)
        end
        if not gui.Enabled then self:note('AutoUpgrade: TAB panel not open'); return false end
        local page=panel:FindFirstChild('Page1')
        local card,title,amount=findCard(page,wanted)
        if not card or not visible(card) then return false end
        local price=amount and tonumber((amount.Text or ''):match('%d+')) or known
        if not price or price<1 or cash(self)<price then return false end
        self.stage='UPGRADE: Axe '..wanted..' $'..price
        if not self:gameClick(title) then return true end
        task.wait(.22)
        if not self.running then return true end
        local detail=panel:FindFirstChild('Detail')
        local info=detail and detail:FindFirstChild('Info')
        local value=info and info:FindFirstChild('Value')
        local buy=info and info:FindFirstChild('Buy')
        if not (value and value.Text==wanted and buy and visible(buy)) then
            self:note('AutoUpgrade: target not selected'); return true
        end
        if not self:gameClick(buy) then
            self:note('AutoUpgrade: GUI click unsupported'); return true
        end
        local untilAt=os.clock()+1.4
        while self.running and os.clock()<untilAt do
            if (self.player:GetAttribute(key) or 0)>level then
                self:note('UPGRADE CONFIRMED: Axe '..wanted..' '..(level+1))
                return true
            end
            task.wait(.1)
        end
        self:note('AutoUpgrade: no server confirmation')
        return true
    end
end
