return function(C)
    C.pressedMouse = false
    C.axeDelay = .33 -- Adaptive; tree HP feedback can lower this after upgrades.
    C.axeStreak, C.axeMisses = 0, 0
    local function getVIM()
        local ok, service = pcall(function() return game:GetService('VirtualInputManager') end)
        if ok then return service end
    end
    function C:tapKey(code, virtualCode)
        local vim=getVIM()
        if vim then
            local ok=pcall(function()
                vim:SendKeyEvent(true,code,false,game)
                task.wait(.045)
                vim:SendKeyEvent(false,code,false,game)
            end)
            if ok then return true end
        end
        if type(keypress)=='function' and type(keyrelease)=='function' then
            return pcall(function()
                keypress(virtualCode); task.wait(.045); keyrelease(virtualCode)
            end)
        end
        return false
    end
    function C:learnAxeHit(confirmed)
        if confirmed then
            self.axeStreak=self.axeStreak+1
            self.axeMisses=0
            if self.axeStreak>=2 then
                self.axeDelay=math.max(.135,self.axeDelay-.017)
            end
        else
            self.axeStreak=0
            self.axeMisses=self.axeMisses+1
            if self.axeMisses>=2 then
                self.axeDelay=math.min(.85,self.axeDelay+.055)
                self.axeMisses=0
            end
        end
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
        if not self.running or self:isPaused() then return false end
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
        if not self.running or self:isPaused() then return false end
        if not self:mouseDown() then return false end
        local deadline = os.clock() + duration
        while self.running and not self:isPaused()
            and not (self.isDodging and self:isDodging()) and os.clock() < deadline do
            task.wait(.06)
        end
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
        if self.toolSlot=='3' and self.player:GetAttribute('OwnsClaws')==true then
            return 'Claws',self.player.Character and self.player.Character:FindFirstChildOfClass('Tool')
        end
        local ch=self.player.Character
        local held=ch and ch:FindFirstChildOfClass('Tool')
        local name = held and held.Name:lower() or ''
        local preferred=self.cfg.tool
        if preferred ~= 'Auto' then return preferred, held end
        local gameTool=self.player:GetAttribute('Tool')
        if type(gameTool)=='string' then
            local lower=gameTool:lower()
            if lower:find('chain') then return 'Chainsaw',held end
            if lower:find('vacuum') then return 'Vacuum',held end
            if lower:find('pistol') then return 'Pistol',held end
            if lower:find('claw') then return 'Claws',held end
            if lower:find('axe') then return 'Axe',held end
            if lower:find('fist') then return 'Fists',held end
        end
        if name:find('chain') or name:find('saw') then return 'Chainsaw',held end
        if name:find('vacuum') or name:find('vac') then return 'Vacuum',held end
        if name:find('pistol') or name:find('gun') then return 'Pistol',held end
        if name:find('claw') then return 'Claws',held end
        if name:find('fist') then return 'Fists',held end
        if self.toolSlot == '3' and self.player:GetAttribute('OwnsClaws')==true then return 'Claws',held end
        if self.toolSlot == '1' then return 'Fists',held end
        return 'Axe',held
    end
    function C:pressSlot(slot)
        if not slot then return false end
        if self.toolSlot == tostring(slot) then return true end
        local code=slot==1 and Enum.KeyCode.One or slot==3 and Enum.KeyCode.Three or Enum.KeyCode.Two
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
    function C:toolCooldown(profile, held, purpose)
        local base=profile=='Fists' and .50 or profile=='Pistol' and .34 or .58
        if profile=='Axe' then base=self.axeDelay or .33 end
        if profile=='Chainsaw' or profile=='Vacuum' then base=.54 end
        if profile=='Claws' then
            local lv=tonumber(self.player:GetAttribute('Up_ClawsSpeed')) or 0
            base=math.max(.17,.53-.045*lv)
        end
        if held then
            for _,key in ipairs({'AttackCooldown','SwingCooldown','Cooldown','AttackDelay'}) do
                local num=held:GetAttribute(key)
                if type(num)=='number' and num>=.08 and num<4 then
                            if profile=='Axe' then
                        base=math.min(base,math.clamp(num,.10,3.99))
                    else
                        base=math.clamp(num,.10,3.99)
                    end
                    break
                end
            end
        end
        if purpose=='Combat' and (profile=='Claws' or profile=='Axe') then
            base=math.max(.13,base*(self.combatFastScale or 1))
        end
        return base
    end
    function C:useItem(target, purpose)
        if not self.running or self:isPaused() then return false end
        if purpose=='Combat' and not self.cfg.combat then return false,'Mob killing disabled' end
        if purpose~='Combat' and not self.cfg.farm then return false,'Farm disabled' end
        if purpose=='Tree' then
            local _,owned,carry=self:equipmentStatus()
            local bag=self:backpack()
            if not owned and math.max(carry or 0,bag or 0)>0 then
                return false,'Hands full: sell before chopping'
            end
        end
        if self.isDodging and self:isDodging() then return false,'Dodging red zone' end
        if purpose~='Combat' and self:mobInterrupt() then
            return false,'Mob spawned; interrupting farm'
        end
        if purpose=='Pickup' then
            local now=os.clock()
            local nextAt=math.max(self.pickupKeyAt or 0,self.lastInputAt or 0)
            while self.running and not self:isPaused() and now<nextAt do
                task.wait(math.min(.05,nextAt-now)); now=os.clock()
            end
            if not self.running or self:isPaused() then return false,'Interrupted' end
            local sent=self:tapKey(Enum.KeyCode.E,0x45)
            if sent then
                self.pickupKeyAt=os.clock()+.13
                self.lastInputAt=os.clock()+.095
            end
            return sent, sent and nil or 'Executor did not accept E input'
        end
        local profile, held = self:activeProfile()
        if self.cfg.tool=='Auto' and purpose=='Tree'
            and self.clawSpeedMax and self:clawSpeedMax() then
            if profile~='Claws' then
                self:pressSlot(3)
                profile,held=self:activeProfile()
            end
        end
        if self.cfg.tool=='Auto' then
            local needsAxe=((purpose=='PickupClick' or purpose=='Deposit') and profile~='Axe')
                or (purpose=='Tree' and (profile=='Fists' or profile=='Pistol'
                    or profile=='Vacuum'))
                or (purpose=='Combat' and profile=='Fists')
            local owned=self.player:GetAttribute('OwnsAxe')==true
                or type(self.player:GetAttribute('AxeBoughtAt'))=='number'
            if needsAxe and owned then
                self:pressSlot(2)
                profile,held=self:activeProfile()
            end
        end
        if self.cfg.tool=='Auto' and not self.cfg.useExperimental
            and (profile=='Chainsaw' or profile=='Pistol' or profile=='Vacuum')
            and purpose~='Pickup' then
            self:pressSlot(2)
            profile,held=self:activeProfile()
            if profile=='Chainsaw' or profile=='Pistol' or profile=='Vacuum' then
                return false,'Axe not equipped; experimental tool remains OFF'
            end
        end
        if purpose=='Tree' and (profile=='Pistol' or profile=='Vacuum') then
            return false, 'Incompatible tool for tree'
        end
        if purpose=='Combat' and profile=='Vacuum' then
            return false, 'Vacuum is not combat gear'
        end
        if purpose=='PickupClick' and profile=='Pistol' then
            return false, 'Pistol cannot pick logs'
        end
        if purpose=='PickupClick' and profile=='Chainsaw' then
            return false, 'Chainsaw pickup unverified'
        end
        if purpose=='PickupClick' and profile=='Vacuum' and not self.cfg.useExperimental then
            return false, 'Vacuum beta disabled'
        end
        if (profile=='Chainsaw' or profile=='Vacuum' or profile=='Pistol')
            and not self.cfg.useExperimental then
            return false, 'Tool beta disabled'
        end
        if (profile=='Chainsaw' or profile=='Vacuum' or profile=='Pistol') and not held and self.player:GetAttribute('Tool')~=profile then
            return false, 'Equip the selected tool in game first'
        end
        if profile=='Axe' then self:pressSlot(2)
        elseif profile=='Claws' then self:pressSlot(3)
        elseif profile=='Fists' then self:pressSlot(1) end
        local key=profile
        local now=os.clock()
        local waitUntil=math.max(self.toolAt[key] or 0,self.lastInputAt or 0)
        while self.running and not self:isPaused() and now<waitUntil do
            task.wait(math.min(.08,waitUntil-now)); now=os.clock()
        end
        if not self.running or self:isPaused() then return false end
        if purpose=='Combat' and not self.cfg.combat then return false,'Mob killing disabled' end
        if purpose~='Combat' and (not self.cfg.farm or self:mobInterrupt()) then
            return false,'Farm disabled or mob appeared'
        end
        if self.isDodging and self:isDodging() then return false,'Dodging red zone' end
        local aimPoint=target
        if type(target)=='function' then
            local ok,pos=pcall(target)
            if not ok or typeof(pos)~='Vector3' then
                return false,'Target disappeared during cooldown'
            end
            aimPoint=pos
        end
        if aimPoint then
            self:aimAt(aimPoint)
            task.wait(.035) -- allow camera/input frame to observe the new aim
            if purpose=='Combat' and type(target)=='function' then
                -- A moving enemy may move DURING those 35ms; aim again.
                local ok,fresh=pcall(target)
                if not ok or typeof(fresh)~='Vector3' then
                    return false,'Enemy moved or despawned before hit'
                end
                self:aimAt(fresh)
            end
        end
        if not self.running or self:isPaused() then return false end
        if self.isDodging and self:isDodging() then return false,'Dodging red zone' end
        local worked
        if profile=='Chainsaw' then
            -- V8.1 confirms heat/rev attributes, but NOT a reload mechanic.
            local heat=self.player:GetAttribute('SawHeat')
            if type(heat)=='number' and heat>.85 then
                return false,'Chainsaw hot: let it cool'
            end
            worked=self:hold(1.15)
        elseif profile=='Vacuum' and purpose=='PickupClick' then
            worked=self:hold(.40)
        else worked=self:tap() end
        if worked then
            self.toolAt[key]=os.clock()+self:toolCooldown(profile,held,purpose)
            self.lastInputAt=os.clock()+.11
        end
        return worked
    end
end
