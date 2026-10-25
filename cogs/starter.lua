-- V4.7: verified V9 starter purchases: Backpack $90, Axe $75.
return function(C)
    C.nextStarterTry=0
    local function cash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local item=stats and stats:FindFirstChild('Cash')
        return item and item.Value or 0
    end
    function C:gameClick(obj)
        if not obj or not obj:IsA('GuiObject') then return false end
        local p,s=obj.AbsolutePosition,obj.AbsoluteSize
        if s.X<8 or s.Y<8 then return false end
        local x,y=p.X+s.X*.5,p.Y+s.Y*.5
        local ok,vim=pcall(function() return game:GetService('VirtualInputManager') end)
        if ok and vim then
            local done=pcall(function()
                vim:SendMouseButtonEvent(x,y,0,true,game,0)
                task.wait(.045)
                vim:SendMouseButtonEvent(x,y,0,false,game,0)
            end)
            if done then return true end
        end
        if type(mousemoveabs)=='function' and type(mouse1click)=='function' then
            return pcall(function() mousemoveabs(x,y);mouse1click() end)
        end
        return false
    end
    function C:openStation(name)
        local stations=self.ws:FindFirstChild('Map')
        stations=stations and stations:FindFirstChild('LogCabin')
        stations=stations and stations:FindFirstChild('Shop')
        stations=stations and stations:FindFirstChild('Stations')
        local station=stations and stations:FindFirstChild('Station_'..name)
        local prompt=station and station:FindFirstChild('Buy',true)
        if not prompt or not prompt:IsA('ProximityPrompt') then
            self:note('Starter: station '..name..' not loaded'); return false
        end
        local anchor=prompt.Parent
        if not anchor or not anchor:IsA('BasePart') then
            anchor=station:FindFirstChildWhichIsA('BasePart',true)
        end
        if not anchor then return false end
        -- Shop flow is independent of ATTACK priority while buying.
        self.shopping=true
        local near=self:goTo(anchor.Position,3.5)
        if not near then self.shopping=nil; return false end
        local fired=false
        if type(fireproximityprompt)=='function' then
            fired=pcall(fireproximityprompt,prompt)
        end
        if not fired then fired=self:tapKey(Enum.KeyCode.E,0x45) end
        task.wait(.35)
        self.shopping=nil
        return fired
    end
    function C:starterStep()
        if not self.cfg.autoBuy then return false end
        local axe,bag=self:equipmentStatus()
        if axe and bag then return false end
        local have=cash(self)
        local name,cost=not bag and 'Backpack' or 'Axe',not bag and 90 or 75
        if have<cost or os.clock()<self.nextStarterTry then return false end
        self.nextStarterTry=os.clock()+8
        self.stage='STARTER: buying '..name
        if not self:openStation(name) or not self.running then return true end
        if name=='Axe' then
            local pg=self.player:FindFirstChild('PlayerGui')
            local station=pg and pg:FindFirstChild('ToolStation')
            local stage=station and station:FindFirstChild('Stage')
            local coins=stage and stage:FindFirstChild('Coins')
            local sink=coins and coins:FindFirstChild('Sink')
            if not (station and station.Enabled and sink and self:gameClick(sink)) then
                self:note('Axe UI not ready: ToolStation.Stage.Coins.Sink')
            end
        end
        local deadline=os.clock()+1.6
        repeat
            local ownedAxe,ownedBag=self:equipmentStatus()
            if (name=='Backpack' and ownedBag) or (name=='Axe' and ownedAxe) then
                self:note(name..' PURCHASE CONFIRMED')
                return true
            end
            task.wait(.1)
        until not self.running or os.clock()>deadline
        self:note(name..': purchase unconfirmed; retry later')
        return true
    end
end
