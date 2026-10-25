return function(C)
    local function clickMouse()
        local ok, vim = pcall(game.GetService, game, "VirtualInputManager")
        if ok and vim then
            local camera = workspace.CurrentCamera
            if camera then
                local xy = camera.ViewportSize / 2
                local succeed = pcall(function()
                    vim:SendMouseButtonEvent(xy.X, xy.Y, 0, true, game, 0)
                    task.wait(0.055)
                    vim:SendMouseButtonEvent(xy.X, xy.Y, 0, false, game, 0)
                end)
                if succeed then return true end
            end
        end
        if type(mouse1click) == "function" then
            if type(mousemoveabs) == "function" then
                local cam = workspace.CurrentCamera
                if cam then pcall(mousemoveabs, cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) end
            end
            return pcall(mouse1click)
        end
        if type(mouse1press) == "function" and type(mouse1release) == "function" then
            local okPress = pcall(mouse1press)
            task.wait(0.06)
            pcall(mouse1release)
            return okPress
        end
        local ok2, vu = pcall(game.GetService, game, "VirtualUser")
        if ok2 and vu then
            local cam = workspace.CurrentCamera
            if not cam then return false end
            local xy = cam.ViewportSize / 2
            return pcall(function()
                vu:Button1Down(xy, cam.CFrame)
                task.wait(0.055)
                vu:Button1Up(xy, cam.CFrame)
            end)
        end
        return false
    end
    function C:chooseTool()
        if self.config.toolSlot == "Auto" then return end
        local n = tonumber(self.config.toolSlot)
        if not n then return end
        if type(keypress) == "function" and type(keyrelease) == "function" then
            local vkey = 0x30 + n
            pcall(keypress, vkey)
            task.wait(0.04)
            pcall(keyrelease, vkey)
        else
            local ok, vim = pcall(game.GetService, game, "VirtualInputManager")
            if ok and vim then
                pcall(function()
                    local code = n == 1 and Enum.KeyCode.One or Enum.KeyCode.Two
                    vim:SendKeyEvent(true, code, false, game)
                    task.wait(0.04)
                    vim:SendKeyEvent(false, code, false, game)
                end)
            end
        end
        task.wait(0.11)
    end
    function C:attackTree(tree)
        local p = self:trunk(tree)
        if not p then return false end
        local hpBefore = tree:GetAttribute("HP") or 0
        local _, root = self:character()
        if not root then return false end
        self:face(p.Position + Vector3.new(0, 1.2, 0))
        task.wait(0.06)
        local fired = false
        if self.config.attackMode == "Experimental Remote" then
            local swings = self.remotes and self.remotes:FindFirstChild("Swing")
            local chops = self.remotes and self.remotes:FindFirstChild("Chop")
            if swings and chops and swings:IsA("RemoteEvent") and chops:IsA("RemoteEvent") then
                self.remoteSeq = self.remoteSeq + 1
                local seq = math.max(self.remoteSeq, (tree:GetAttribute("LastHitSeq") or 0) + 1)
                self.remoteSeq = seq
                local hit = p.Position + Vector3.new(0, 1, 0)
                fired = pcall(function()
                    swings:FireServer(1)
                    task.wait(0.31)
                    chops:FireServer(tree, hit, 1, seq)
                end)
            end
        else
            fired = clickMouse()
        end
        if not fired then
            self:note("error", "Brak metody ataku (mouse1click / VIM) lub RemoteEvents")
            return false
        end
        self.stats.hits = self.stats.hits + 1
        local deadline = os.clock() + math.max(self.config.attackDelay, 0.55)
        while self.running and os.clock() < deadline do
            if (tree:GetAttribute("HP") or hpBefore) < hpBefore - 0.01 then return true end
            if tree:GetAttribute("Felled") == true then return true end
            task.wait(0.09)
        end
        if (tree:GetAttribute("HP") or hpBefore) < hpBefore - 0.01 then return true end
        self:note("warn", "Uderzenie bez potwierdzonego spadku HP drzewa #" .. tostring(tree:GetAttribute("TreeId")))
        return false
    end
end
