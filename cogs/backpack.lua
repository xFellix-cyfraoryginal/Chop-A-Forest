-- Verified V9: Backpack costs 90; Up_GearBackpack 0 -> 1, bag 5 -> 15.
-- Never buys Axe or upgrades. No guessed purchase remotes.
return function(C)
    C.nextBackpackTry=0
    local function money(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local value=stats and stats:FindFirstChild('Cash')
        return value and tonumber(value.Value) or 0
    end
    local function owned(self)
        return (tonumber(self.player:GetAttribute('Up_GearBackpack')) or 0)>0
    end
    function C:buyBackpackStep()
        if not self.cfg.autoBackpack or owned(self) then return false end
        if money(self)<90 or os.clock()<self.nextBackpackTry then return false end
        -- Do not interrupt mob combat to visit the station.
        if self:pendingEventMob() then return false end
        self.nextBackpackTry=os.clock()+14
        local cabin=self.ws:FindFirstChild('Map')
        cabin=cabin and cabin:FindFirstChild('LogCabin')
        local shop=cabin and cabin:FindFirstChild('Shop')
        local stations=shop and shop:FindFirstChild('Stations')
        local station=stations and stations:FindFirstChild('Station_Backpack')
        local prompt=station and station:FindFirstChild('Buy',true)
        if not (prompt and prompt:IsA('ProximityPrompt')) then
            self:note('Backpack: prompt not found');return false
        end
        local base=prompt.Parent
        if not (base and base:IsA('BasePart')) then
            base=station:FindFirstChildWhichIsA('BasePart',true)
        end
        if not base then self:note('Backpack: station part missing');return false end
        self.stage='BACKPACK: walking to station'
        self.shopping=true
        local reached=self:goTo(base.Position,3.5)
        if not reached or not self.running then
            self.shopping=false;return false
        end
        self.stage='BACKPACK: activating station'
        local fired=false
        if type(fireproximityprompt)=='function' then
            fired=pcall(fireproximityprompt,prompt)
        end
        if not fired then fired=self:tapKey(Enum.KeyCode.E,0x45) end
        self.shopping=false
        if not fired then self:note('Backpack interaction unavailable');return true end
        local deadline=os.clock()+2.2
        while self.running and os.clock()<deadline do
            if owned(self) then
                self:note('Backpack server confirmed');return true
            end
            task.wait(.1)
        end
        self:note('Backpack not confirmed; retry later')
        return true
    end
end
