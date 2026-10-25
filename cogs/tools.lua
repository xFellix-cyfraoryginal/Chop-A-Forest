return function(C)
    C.pressedMouse = false
    local function getVIM()
        local ok, service = pcall(function() return game:GetService('VirtualInputManager') end)
        if ok then return service end
    end
    function C:releaseMouse()
        if not self.pressedMouse then return end
        self.pressedMouse = false
        local cam = self.ws.CurrentCamera
        local vim = getVIM()
        if vim and cam then
            local center = cam.ViewportSize/2
            pcall(function() vim:SendMouseButtonEvent(center.X,center.Y,0,false,game,0) end)
        end
        if type(mouse1release)=='function' then pcall(mouse1release) end
    end
    function C:mouseDown()
        local vim, cam = getVIM(), self.ws.CurrentCamera
        if vim and cam then
            local center = cam.ViewportSize/2
            local ok=pcall(function()
                vim:SendMouseButtonEvent(center.X,center.Y,0,true,game,0)
            end)
            if ok then self.pressedMouse = true; return true end
        end
        if type(mouse1press)=='function' then
            local ok=pcall(mouse1press)
            if ok then self.pressedMouse = true; return true end
        end
        return false
    end
    function C:tap()
        if not self.running or self.panic then return false end
        -- Prefer viewport-center input over a stale system cursor position.
        if self:mouseDown() then
            task.wait(.055)
            self:releaseMouse()
            return true
        end
        if type(mouse1click)=='function' then
            local cam=self.ws.CurrentCamera
            if cam and type(mousemoveabs)=='function' then
                pcall(mousemoveabs,cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
            end
            return pcall(mouse1click)
        end
        return false
    end
    function C:hold(duration)
        if not self.running or self.panic then return false end
        if not self:mouseDown() then return false end
        local deadline = os.clock() + duration
        while self.running and not self.panic and os.clock() < deadline do task.wait(.06) end
        self:releaseMouse()
        return true
    end
    function C:aimAt(position)
        local cam = self.ws.CurrentCamera
        if not cam or not position then return end
        local origin=cam.CFrame.Position
        if (origin-position).Magnitude > .2 then
            cam.CFrame=CFrame.lookAt(origin, position)
        end
    end
    function C:activeProfile()
        local ch=self.player.Character
        local held=ch and ch:FindFirstChildOfClass('Tool')
        local name = held and held.Name:lower() or ''
        local preferred=self.cfg.tool
        if preferred ~= 'Auto' then return preferred, held end
        if name:find('chain') or name:find('saw') then return 'Chainsaw',held end
        if name:find('vacuum') or name:find('vac') then return 'Vacuum',held end
        if name:find('pistol') or name:find('gun') then return 'Pistol',held end
        if name:find('fist') then return 'Fists',held end
        if self.toolSlot == '1' then return 'Fists',held end
        return 'Axe',held
    end
    function C:pressSlot(slot)
        if not slot then return false end
        if self.toolSlot == tostring(slot) then return true end
        local code=slot==1 and Enum.KeyCode.One or Enum.KeyCode.Two
        local vim = getVIM()
        if vim then
            local ok=pcall(function()
                vim:SendKeyEvent(true,code,false,game)
                task.wait(.04)
                vim:SendKeyEvent(false,code,false,game)
            end)
            if ok then self.toolSlot=tostring(slot); task.wait(.15); return true end
        end
        if type(keypress)=='function' and type(keyrelease)=='function' then
            local value=0x30+slot
            local ok=pcall(function() keypress(value); task.wait(.04); keyrelease(value) end)
            if ok then self.toolSlot=tostring(slot); task.wait(.15); return true end
        end
        return false
    end
    function C:toolCooldown(profile, held)
        local base=profile=='Fists' and .50 or profile=='Pistol' and .34 or .60
        if profile=='Chainsaw' or profile=='Vacuum' then base=.54 end
        if held then
            for _, key in ipairs({'AttackCooldown','SwingCooldown','Cooldown','AttackDelay'}) do
                local num=held:GetAttribute(key)
                if type(num)=='number' and num>=.12 and num<4 then
                    base=math.max(base,num); break
                end
            end
        end
        return base
    end
    function C:useItem(target, purpose)
        if not self.running or self.panic then return false end
        local profile, held = self:activeProfile()
        -- In Auto, prefer the verified Axe for tree work, pickup and melee.
        if self.cfg.tool=='Auto' then
            local needsAxe=(purpose=='Pickup' and profile~='Axe')
                or (purpose=='Tree' and (profile=='Fists' or profile=='Pistol'
                    or profile=='Vacuum'))
                or (purpose=='Combat' and profile=='Fists')
            if needsAxe then
                self:pressSlot(2)
                profile,held=self:activeProfile()
            end
        end
        -- Unsupported equipment uses experimental generic input only when opted in.
        if purpose=='Tree' and (profile=='Pistol' or profile=='Vacuum') then
            return false, 'Incompatible tool for tree'
        end
        if purpose=='Combat' and profile=='Vacuum' then
            return false, 'Vacuum is not combat gear'
        end
        if purpose=='Pickup' and profile=='Pistol' then
            return false, 'Pistol cannot pick logs'
        end
        if purpose=='Pickup' and profile=='Chainsaw' then
            return false, 'Chainsaw pickup unverified'
        end
        if purpose=='Pickup' and profile=='Vacuum' and not self.cfg.useExperimental then
            return false, 'Vacuum beta disabled'
        end
        if (profile=='Chainsaw' or profile=='Vacuum' or profile=='Pistol')
            and not self.cfg.useExperimental then
            return false, 'Tool beta disabled'
        end
        if (profile=='Chainsaw' or profile=='Vacuum' or profile=='Pistol') and not held then
            return false, 'Equip the selected tool in game first'
        end
        if profile=='Axe' then self:pressSlot(2)
        elseif profile=='Fists' then self:pressSlot(1) end
        if target then self:aimAt(target) end
        local key=profile
        local now=os.clock()
        local waitUntil=math.max(self.toolAt[key] or 0,self.lastInputAt or 0)
        while self.running and not self.panic and now<waitUntil do
            task.wait(math.min(.08,waitUntil-now)); now=os.clock()
        end
        if not self.running or self.panic then return false end
        local worked
        if profile=='Chainsaw' or (profile=='Vacuum' and purpose=='Pickup') then
            worked=self:hold(.40)
        else worked=self:tap() end
        if worked then
            self.toolAt[key]=os.clock()+self:toolCooldown(profile,held)
            self.lastInputAt=os.clock()+.15
        end
        return worked
    end
end
