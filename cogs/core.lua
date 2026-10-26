return function(C)
    C.players = game:GetService('Players')
    C.player = C.players.LocalPlayer
    C.ws = game:GetService('Workspace')
    C.uis = game:GetService('UserInputService')
    C.pfs = game:GetService('PathfindingService')
    C.http = game:GetService('HttpService')
    C.map = C.ws:FindFirstChild('Map')
    C.treesFolder = C.map and C.map:FindFirstChild('Trees')
    C.logsFolder = C.ws:FindFirstChild('Logs')
    C.monstersFolder = C.ws:FindFirstChild('Monsters')
    C.sellSpot = C.map and C.map:FindFirstChild('SellSpot')
    C.live, C.running, C.session, C.motion = true, false, 0, 0
    C.stage, C.detail = 'Idle', 'Ready'
    C.connections, C.messages = {}, {}
    C.stats = {trees = 0, collected = 0, sold = 0, kills = 0, retreats = 0}
    C.cfg = {
        move = 'Instant TP', priority = 'EVENT', tool = 'Auto',
        farm = true, combat = true, collect = true, sell = true,
        autoBackpack = true, autoClawsSpeed = true,
        hpPause = true, ignoreHPPause = false, bossOnly = false,
        pauseHP = 0.40, pauseSeconds = 6,
        retaliateSeconds = 9, clearUntil = 1, combatRadius = 65,
        pickupRange = 3.7, treeRange = 3.7,
        maxTreeDistance = math.huge, idlePause = .15,
        useExperimental = false
    }
    -- Both UI toggles are required to enter the no-dodge boss rush.
    function C:bossRush()
        return self.cfg.combat and self.cfg.bossOnly and self.cfg.ignoreHPPause
    end
    function C:clearBossRushInterrupts()
        if not self:bossRush() then return end
        self.hpHoldUntil=0
        self.skyHoldPosition=nil
        self.skyLanding=nil
        self.dodgeHoldUntil=0
        if self.hazards then table.clear(self.hazards) end
        if self.releaseMouse then self:releaseMouse() end
    end
    C.toolAt, C.toolSlot = {}, ''
    function C:connect(signal, callback)
        local conn = signal:Connect(callback)
        self.connections[#self.connections+1] = conn
        return conn
    end
    function C:note(message)
        message = tostring(message)
        self.detail = message
        self.messages[#self.messages+1] = {t = os.clock(), text = message}
        if #self.messages > 55 then table.remove(self.messages, 1) end
    end
    function C:character()
        local character = self.player.Character
        local root = character and character:FindFirstChild('HumanoidRootPart')
        local hum = character and character:FindFirstChildOfClass('Humanoid')
        if not root or not hum or hum.Health <= 0 then return nil end
        return character, root, hum
    end
    function C:position()
        local _, root = self:character()
        return root and root.Position or nil
    end
    function C:backpack()
        local pg = self.player:FindFirstChild('PlayerGui')
        local hud = pg and pg:FindFirstChild('ChopHud')
        local bag = hud and hud:FindFirstChild('Backpack')
        local label = bag and bag:FindFirstChild('Count')
        if not label or not (label:IsA('TextLabel') or label:IsA('TextButton')) then
            return nil, nil
        end
        local have, capacity = label.Text:match('(%d+)%s*/%s*(%d+)')
        return tonumber(have), tonumber(capacity)
    end
    -- Verified ownership: AxeBoughtAt exists in observed event logs.
    -- Backpack purchase attribute isn't confirmed. Never infer ownership
    -- solely from the "0/5" HUD; rely on a positive Gear marker if present.
    function C:equipmentStatus()
        local axe=self.player:GetAttribute('AxeBoughtAt')
        local hasAxe=(type(axe)=='number' and axe>0)
            or self.player:GetAttribute('OwnsAxe')==true
        -- V9 verified: Up_GearBackpack 0 -> 1 and bag 5 -> 15.
        local level=self.player:GetAttribute('Up_GearBackpack')
        local bagAttr=type(level)=='number' and level>0 or nil
        local carrying=self.player:GetAttribute('CarriedLogs')
        local carried=type(carrying)=='number' and carrying or 0
        local _,capacity=self:backpack()
        -- Unknown isn't YES; a first-session purchase logger will reveal
        -- the actual marker, and until then we use a cautious fallback.
        return hasAxe,bagAttr,carried,capacity
    end
    C.healthLabel = nil
    function C:health()
        local _, _, hum = self:character()
        if not hum then return 0, 100 end
        local hp, maxHP = hum.Health, math.max(hum.MaxHealth, 1)
        local label = self.healthLabel
        if label and label.Parent then
            local a, b = label.Text:match('(%d+)%s*/%s*(%d+)')
            a, b = tonumber(a), tonumber(b)
            if a and b and b >= 20 and b <= 10000 and a / b < hp / maxHP then
                return a, b
            end
        end
        return hp, maxHP
    end
    function C:findHealthLabel()
        local pg = self.player:FindFirstChild('PlayerGui')
        if not pg then return end
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA('TextLabel') then
                local name = obj:GetFullName():lower()
                if (name:find('health') or name:find('hpbar') or name:find('hearthud'))
                    and obj.Text:find('%d+%s*/%s*%d+') then
                    self.healthLabel = obj
                    return
                end
            end
        end
    end
    function C:cancelMove()
        if self.clearWorkHover then self:clearWorkHover() end
        if self.stopHover then self:stopHover() end
        self.motion = self.motion + 1
        local _, root, hum = self:character()
        if root and hum then hum:MoveTo(root.Position) end
        if self.releaseMouse then pcall(function() self:releaseMouse() end) end
    end
    function C:stop()
        if not self.running then return end
        self.running = false
        self.session = self.session + 1
        self:cancelMove()
        if self.skyHoldPosition and self.skyLanding then
            local _,root=self:character()
            if root then
                root.CFrame=CFrame.new(self.skyLanding)*root.CFrame.Rotation
                root.AssemblyLinearVelocity=Vector3.zero
            end
        end
        self.skyHoldPosition,self.skyLanding=nil,nil
        if self.disableAirHold then self:disableAirHold() end
        self.stage = 'STOPPED'
        self:note('Stopped (F6/F8 / button)')
    end
    function C:unload()
        if not self.live then return end
        self:stop()
        self.live = false
        if self.disableAirHold then self:disableAirHold() end
        for _, conn in ipairs(self.connections) do pcall(function() conn:Disconnect() end) end
        if self.gui then pcall(function() self.gui:Destroy() end) end
        local env = (type(getgenv) == 'function' and getgenv()) or _G
        if env.CAF_V4 == self then env.CAF_V4 = nil end
        if env.CAF_ALPHA == self then env.CAF_ALPHA = nil end
        self.wood = {}
        self.hazards = {}
        self.trees, self.enemies = {}, {}
    end
    C:connect(C.uis.InputBegan, function(input, consumed)
        if input.KeyCode == Enum.KeyCode.F8 then C:stop() end
        if input.KeyCode == Enum.KeyCode.F6 and not consumed then
            if C.running then C:stop() elseif C.start then C:start() end
        end
        if consumed then return end
        if input.KeyCode == Enum.KeyCode.One then C.toolSlot = '1' end
        if input.KeyCode == Enum.KeyCode.Two then C.toolSlot = '2' end
        if input.KeyCode == Enum.KeyCode.Three then C.toolSlot = '3' end
    end)
    C:connect(C.player.CharacterRemoving, function() C:stop() end)
    task.defer(function() if C.live then C:findHealthLabel() end end)
end
