return function(C)
    local folder = Instance.new("Folder")
    folder.Name = "CropForest_Alpha_Visuals"
    folder.Parent = C.ws.CurrentCamera or C.ws
    C.espFolder = folder
    local targetHighlight = Instance.new("Highlight")
    targetHighlight.Name = "CurrentTarget"
    targetHighlight.FillTransparency = 0.8
    targetHighlight.OutlineTransparency = 0
    targetHighlight.FillColor = Color3.fromRGB(74, 237, 120)
    targetHighlight.OutlineColor = Color3.fromRGB(116, 255, 144)
    targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    targetHighlight.Parent = folder
    local label = Instance.new("BillboardGui")
    label.Name = "TargetLabel"
    label.Size = UDim2.fromOffset(220, 38)
    label.AlwaysOnTop = true
    label.StudsOffset = Vector3.new(0, 5, 0)
    label.Parent = folder
    local text = Instance.new("TextLabel")
    text.BackgroundColor3 = Color3.fromRGB(13, 20, 28)
    text.BackgroundTransparency = 0.16
    text.Size = UDim2.fromScale(1, 1)
    text.TextColor3 = Color3.fromRGB(145, 255, 167)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = label
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = text
    local logHighlight = {}
    local function clearLogs()
        for obj, visual in pairs(logHighlight) do visual:Destroy(); logHighlight[obj]=nil end
    end
    local elapsed = 0
    C:connect(game:GetService("RunService").Heartbeat, function(dt)
        if not C.alive then return end
        elapsed = elapsed + dt
        if elapsed < (C.config.perfMode == "Eco" and 1.1 or 0.4) then return end
        elapsed = 0
        local target = C.target
        local trunk = target and C:trunk(target)
        local show = C.config.showTree and C.running and trunk ~= nil
        targetHighlight.Enabled = show
        targetHighlight.Adornee = show and target or nil
        label.Enabled = show
        label.Adornee = show and trunk or nil
        if show then
            text.Text = tostring(target:GetAttribute("TreeType")) .. " #" .. tostring(target:GetAttribute("TreeId"))
                .. "  HP " .. string.format("%.2f", target:GetAttribute("HP") or 0)
                .. ((target:GetAttribute("Mutation") == "Golden") and "  GOLD" or "")
        end
        if C.config.showLogs and C.running then
            local near, playerPos={},C:pos()
            if playerPos then
                for obj in pairs(C.drops) do
                    local part=C:logPart(obj)
                    if part and (part.Position-playerPos).Magnitude<48 then
                        table.insert(near,{obj=obj,dist=(part.Position-playerPos).Magnitude})
                    end
                end
            end
            table.sort(near,function(a,b) return a.dist<b.dist end)
            local selected={}
            for i=1,math.min(10,#near) do
                local obj=near[i].obj
                selected[obj]=true
                if not logHighlight[obj] then
                    local h=Instance.new("Highlight")
                    h.Adornee=obj
                    h.FillColor=Color3.fromRGB(255,195,85)
                    h.OutlineColor=Color3.fromRGB(255,218,110)
                    h.FillTransparency=.85
                    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent=folder
                    logHighlight[obj]=h
                end
            end
            for obj,h in pairs(logHighlight) do
                if not selected[obj] then h:Destroy();logHighlight[obj]=nil end
            end
        else
            clearLogs()
        end
    end)
end
