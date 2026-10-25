-- V4.7.1. V9 verified: Station_Axe -> E -> ToolStation.Stage.Coins.Sink.
-- Wait for the actual Axe purchase UI, not a fixed 0.35s delay.
return function(C)
    C.nextStarterTry=0
    local function cash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local item=stats and stats:FindFirstChild('Cash')
        return item and item.Value or 0
    end
    local function shown(obj)
        if not obj or not obj:IsA('GuiObject') then return false end
        local item=obj
        while item do
            if item:IsA('GuiObject') and not item.Visible then return false end
            if item:IsA('ScreenGui') and not item.Enabled then return false end
            item=item.Parent
        end
        return obj.AbsoluteSize.X>8 and obj.AbsoluteSize.Y>8
    end
    function C:gameClick(obj, method)
        if not shown(obj) then return false end
        local p,s=obj.AbsolutePosition,obj.AbsoluteSize
        local x,y=p.X+s.X*.5,p.Y+s.Y*.5
        -- V9 identifies Sink as a TextButton (not the surrounding Coins Frame).
        if method=='signal' and obj:IsA('GuiButton') and type(firesignal)=='function' then
            local ok=pcall(function() firesignal(obj.Activated) end)
            if ok then return true end
        end
        if method=='mouse' and type(mousemoveabs)=='function'
            and type(mouse1click)=='function' then
            return pcall(function() mousemoveabs(x,y);task.wait(.08);mouse1click() end)
        end
        local ok,vim=pcall(function() return game:GetService('VirtualInputManager') end)
        if ok and vim then
            local sent=pcall(function()
                vim:SendMouseButtonEvent(x,y,0,true,game,0)
                task.wait(.085)
                vim:SendMouseButtonEvent(x,y,0,false,game,0)
            end)
            if sent then return true end
        end
        if type(mousemoveabs)=='function' and type(mouse1click)=='function' then
            return pcall(function() mousemoveabs(x,y);task.wait(.08);mouse1click() end)
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
        self.shopping=true
        local arrived=self:goTo(anchor.Position,3.5)
        if not arrived or not self.running then
            self.shopping=nil; return false
        end
        local fired=false
        if type(fireproximityprompt)=='function' then
            fired=pcall(fireproximityprompt,prompt)
        end
        if not fired then fired=self:tapKey(Enum.KeyCode.E,0x45) end
        self.shopping=nil
        if not fired then self:note('Starter: E/prompt not sent at '..name) end
        return fired
    end
    local function axeSink(self)
        local pg=self.player:FindFirstChild('PlayerGui')
        local ui=pg and pg:FindFirstChild('ToolStation')
        local stage=ui and ui:FindFirstChild('Stage')
        local coins=stage and stage:FindFirstChild('Coins')
        local sink=coins and coins:FindFirstChild('Sink')
        local info=stage and stage:FindFirstChild('Info')
        local name=info and info:FindFirstChild('Name')
        local title=stage and stage:FindFirstChild('Title')
        local text=name and name:IsA('TextLabel') and name.Text
        if not text then text=title and title:IsA('TextLabel') and title.Text end
        return ui and ui.Enabled and text=='Axe' and shown(sink) and sink or nil
    end
    local function waitOwned(self,name,secs)
        local deadline=os.clock()+secs
        repeat
            local a,b=self:equipmentStatus()
            if (name=='Axe' and a) or (name=='Backpack' and b) then
                return true
            end
            task.wait(.10)
        until not self.running or os.clock()>=deadline
        return false
    end
    function C:starterStep()
        if not self.cfg.autoBuy then return false end
        local axe,bag=self:equipmentStatus()
        if axe and bag then return false end
        local name,cost=not bag and 'Backpack' or 'Axe',not bag and 90 or 75
        if cash(self)<cost or os.clock()<self.nextStarterTry then return false end
        self.nextStarterTry=os.clock()+8
        self.stage='STARTER: buying '..name
        local pg=self.player:FindFirstChild('PlayerGui')
        local stationGui=pg and pg:FindFirstChild('ToolStation')
        -- Do not press E again if Axe's purchase panel is already open.
        -- A second E could toggle it closed on some clients.
        local openAxe=name=='Axe' and stationGui and stationGui.Enabled
        if not openAxe and not self:openStation(name) then return true end
        if not self.running then return true end
        if name=='Backpack' then
            if waitOwned(self,name,2.0) then
                self:note('Backpack OWNED (server confirmed)')
            else
                self:note('Backpack unconfirmed, retry after earning coins')
            end
            return true
        end
        -- UI often appears >350 ms after E. Never click a different station.
        self.stage='STARTER: waiting for Axe UI'
        local deadline=os.clock()+4.0
        local sink
        repeat
            sink=axeSink(self)
            if sink then break end
            if waitOwned(self,'Axe',.12) then
                self:note('Axe owned; purchase screen no longer needed')
                return true
            end
            task.wait(.10)
        until not self.running or os.clock()>=deadline
        if not self.running then return true end
        if not sink then
            self:note('Axe UI not ready after 4s; no blind BUY click')
            return true
        end
        local before=cash(self)
        -- Progressive input fallbacks, NEVER multiple uncontrolled BUY calls.
        local methods={'vim','mouse','signal'}
        for i,method in ipairs(methods) do
            if not self.running then break end
            if waitOwned(self,'Axe',.05) then break end
            sink=axeSink(self)
            if not sink then
                self:note('Axe UI hidden / changed; stop clicking')
                break
            end
            self.stage='STARTER: Axe BUY '..i..'/3'
            local sent=self:gameClick(sink,method)
            self:note('Axe BUY '..method..': '..(sent and 'input sent' or 'input unavailable'))
            if sent and waitOwned(self,'Axe',1.15) then break end
            task.wait(.10)
        end
        local a=self:equipmentStatus()
        if a then
            self:note('Axe OWNED (confirmed; cash '..before..' -> '..cash(self)..')')
        else
            self.nextStarterTry=os.clock()+8
            self:note('Axe BUY not confirmed; still missing, retry later')
        end
        return true
    end
end
