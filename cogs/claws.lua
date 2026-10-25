return function(C)
    -- MAX level from the game's Clawman Attack Speed card, with
    -- six lit pips as the observed ceiling. UI check avoids guessing
    -- that simply owning Claws means max speed.
    function C:clawSpeedMax()
        if self.player:GetAttribute('OwnsClaws')~=true then return false end
        local lvl=tonumber(self.player:GetAttribute('Up_ClawsSpeed')) or 0
        if lvl>=6 then return true end
        local pg=self.player:FindFirstChild('PlayerGui')
        local ui=pg and pg:FindFirstChild('Upgrades')
        local panel=ui and ui:FindFirstChild('Panel')
        local page=panel and panel:FindFirstChild('Page2')
        local claws=page and page:FindFirstChild('Claws')
        if not claws then return false end
        -- Some cards share the name Card. Anchor price to its own title.
        for _,card in ipairs(claws:GetChildren()) do
            local face=card:FindFirstChild('Face')
            local title=face and face:FindFirstChild('Title')
            if title and title:IsA('TextLabel') and title.Text=='Attack Speed' then
                local price=card:FindFirstChild('Price')
                local amount=price and price:FindFirstChild('Amount')
                if amount and amount:IsA('TextLabel') then
                    local text=amount.Text:upper()
                    if text:find('MAX',1,true) then return true end
                end
            end
        end
        return false
    end

end
