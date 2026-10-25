return function(C)
    local UI = {}
    C.ui = UI
    local colors = {bg = Color3.fromRGB(12, 17, 27), panel = Color3.fromRGB(22, 30, 45),
        border = Color3.fromRGB(45, 62, 83), text = Color3.fromRGB(236, 243, 253),
        secondary = Color3.fromRGB(155, 171, 193), accent = Color3.fromRGB(70, 138, 249),
        green = Color3.fromRGB(65, 198, 135), red = Color3.fromRGB(214, 87, 101)}
    local function new(class, props, parent)
        local x = Instance.new(class)
        for key, value in pairs(props or {}) do x[key] = value end
        if parent then x.Parent = parent end
        return x
    end
    local function rounded(obj, r)
        new("UICorner", {CornerRadius = UDim.new(0, r or 7)}, obj)
        return obj
    end
    local env = type(gethui) == "function" and gethui() or game:GetService("CoreGui")
    local gui = new("ScreenGui", {Name="CropForest_AutoFarm_Alpha", ResetOnSpawn=false,
        IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, env)
    C.gui = gui
    local main = rounded(new("Frame", {Position=UDim2.fromOffset(24, 115), Size=UDim2.fromOffset(408, 418),
        BackgroundColor3=colors.bg, BorderSizePixel=0}, gui), 12)
    new("UIStroke", {Color=colors.border, Thickness=1}, main)
    local head = rounded(new("Frame", {Size=UDim2.new(1, 0, 0, 46), BackgroundColor3=colors.panel,
        BorderSizePixel=0}, main), 12)
    new("TextLabel", {Size=UDim2.new(1, -110, 1, 0), Position=UDim2.fromOffset(16, 0),
        BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
        Text="CROP FOREST  |  AUTO FARM ALPHA", TextColor3=colors.text,
        Font=Enum.Font.GothamBold, TextSize=13}, head)
    local function action(parent, name, text, pos, size, bg, onClick)
        local b = rounded(new("TextButton", {Name=name, Position=pos, Size=size,
            BackgroundColor3=bg, Text=text, TextColor3=colors.text,
            Font=Enum.Font.GothamSemibold, TextSize=12, AutoButtonColor=true}, parent), 7)
        C:connect(b.MouseButton1Click, onClick)
        return b
    end
    action(head,"Close","X",UDim2.new(1,-38,0,8),UDim2.fromOffset(30,30),colors.red,function() C:unload() end)
    local minimized = false
    action(head,"Min","_",UDim2.new(1,-74,0,8),UDim2.fromOffset(30,30),colors.border,function()
        minimized = not minimized
        main.Size = minimized and UDim2.fromOffset(408,46) or UDim2.fromOffset(408,418)
        for _, c in ipairs(main:GetChildren()) do if c ~= head and c:IsA("GuiObject") then c.Visible=not minimized end end
    end)
    local tabs = new("Frame", {Position=UDim2.fromOffset(12,54),Size=UDim2.new(1,-24,0,31),BackgroundTransparency=1},main)
    local names = {"FARM","MOVE","OPTIONS","DEBUG"}
    local pages = {}
    local buttons = {}
    local selected = "FARM"
    for i,name in ipairs(names) do
        local b = action(tabs,name,name,UDim2.new((i-1)/4,3,0,0),UDim2.new(0.25,-6,1,0),colors.panel,function()
            selected=name
            for k,page in pairs(pages) do page.Visible=k==selected end
            for k,btn in pairs(buttons) do btn.BackgroundColor3=k==selected and colors.accent or colors.panel end
        end)
        buttons[name]=b
        local page=new("ScrollingFrame", {Name=name,Position=UDim2.fromOffset(12,91), Size=UDim2.new(1,-24,1,-158),
            BackgroundTransparency=1,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=i==1,BorderSizePixel=0},main)
        new("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},page)
        pages[name]=page
    end
    buttons.FARM.BackgroundColor3=colors.accent
    local function row(page, label, value, callback)
        local bar=rounded(new("Frame",{Size=UDim2.new(1,-7,0,34),BackgroundColor3=colors.panel,BorderSizePixel=0},page),7)
        new("TextLabel",{Size=UDim2.new(0.56,0,1,0),Position=UDim2.fromOffset(10,0),BackgroundTransparency=1,
            Text=label,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=colors.text,Font=Enum.Font.Gotham,TextSize=12},bar)
        local b
        b=action(bar,"Value",tostring(value),UDim2.new(0.57,0,0,4),UDim2.new(0.41,-7,1,-8),colors.border,function()
            local nextVal=callback()
            b.Text=tostring(nextVal)
        end)
        return b
    end
    local function switch(page,title,key)
        row(page,title,C.config[key] and "ON" or "OFF",function()
            C.config[key]=not C.config[key]
            return C.config[key] and "ON" or "OFF"
        end)
    end
    local function options(page,title,key,list)
        local index=table.find(list,C.config[key]) or 1
        row(page,title,C.config[key],function()
            index=index%#list+1
            C.config[key]=list[index]
            return list[index]
        end)
    end
    local function number(page,title,key,min,max,delta)
        local bar=rounded(new("Frame",{Size=UDim2.new(1,-7,0,36),BackgroundColor3=colors.panel,BorderSizePixel=0},page),7)
        new("TextLabel",{Size=UDim2.new(.49,0,1,0),Position=UDim2.fromOffset(10,0),BackgroundTransparency=1,
            Text=title,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=colors.text,Font=Enum.Font.Gotham,TextSize=12},bar)
        local field=rounded(new("TextBox",{Position=UDim2.new(.53,0,0,4),Size=UDim2.new(.42,0,1,-8),
            BackgroundColor3=colors.border,Text=tostring(C.config[key]),ClearTextOnFocus=false,
            TextColor3=colors.text,Font=Enum.Font.Gotham,TextSize=12},bar),5)
        C:connect(field.FocusLost,function()
            local n=tonumber(field.Text)
            if n then C.config[key]=math.floor(math.clamp(n,min,max)/delta+0.5)*delta end
            field.Text=tostring(C.config[key])
        end)
    end
    switch(pages.FARM,"Auto Collect","autoCollect")
    switch(pages.FARM,"Auto Sell","autoSell")
    switch(pages.FARM,"Sell after each tree","sellAfterTree")
    switch(pages.FARM,"Sell when full","sellWhenFull")
    switch(pages.FARM,"Golden Tree priority","goldFirst")
    options(pages.FARM,"Attack", "attackMode", {"Input","Experimental Remote"})
    options(pages.FARM,"Tool slot","toolSlot",{"2","1","Auto"})
    options(pages.MOVE,"Movement","mode",{"Walk","Step TP","Instant TP"})
    number(pages.MOVE,"Step TP speed", "stepSpeed",8,180,2)
    number(pages.MOVE,"Attack delay (s)","attackDelay",0.45,3,0.05)
    number(pages.MOVE,"Distance from tree","hitDistance",2.5,6,0.1)
    number(pages.MOVE,"Max tree distance","maxTreeDistance",25,1500,5)
    options(pages.MOVE,"Area","selectedArea",{"Current","1","2","3","4","5","6","7","8","All"})
    number(pages.OPTIONS,"Failures per target","maxFailures",1,8,1)
    switch(pages.OPTIONS,"Target highlight","showTree")
    switch(pages.OPTIONS,"Log highlights","showLogs")
    new("TextLabel",{Size=UDim2.new(1,-7,0,45),BackgroundTransparency=1,TextWrapped=true,
        Text="Walk uses Pathfinding. Step TP and Instant TP can be reset by the server.\nExperimental Remote uses an unverified sequence.",
        Font=Enum.Font.Gotham,TextColor3=colors.secondary,TextSize=11},pages.OPTIONS)
    local dbg=new("TextLabel",{Size=UDim2.new(1,-7,0,194),BackgroundColor3=colors.panel,
        TextColor3=colors.secondary,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},pages.DEBUG)
    rounded(dbg,7)
    local info = new("TextLabel",{Position=UDim2.new(0,15,1,-63),Size=UDim2.new(1,-30,0,25),
        BackgroundTransparency=1,Text="Idle",TextColor3=colors.secondary,Font=Enum.Font.Gotham,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left},main)
    local start=action(main,"Start","START",UDim2.new(0,12,1,-38),UDim2.new(.45,-16,0,31),colors.green,function()
        if C.running then C:stop() else C:start() end
    end)
    action(main,"Export","EXPORT JSON",UDim2.new(.46,0,1,-38),UDim2.new(.28,-6,0,31),colors.accent,function()
        local ok, out=C:export()
        C:note(ok and "info" or "error",out)
    end)
    action(main,"Unload","UNLOAD",UDim2.new(.75,0,1,-38),UDim2.new(.25,-12,0,31),colors.red,function() C:unload() end)
    local dragging, dragStart, origin=false,nil,nil
    C:connect(head.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=input.Position; origin=main.Position
        end
    end)
    C:connect(head.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    C:connect(C.uid.InputChanged,function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local d=input.Position-dragStart
            main.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
        end
    end)
    local acc=0
    C:connect(game:GetService("RunService").Heartbeat,function(dt)
        if not C.alive then return end
        acc=acc+dt
        if acc<.4 then return end
        acc=0
        start.Text=C.running and "STOP" or "START"
        start.BackgroundColor3=C.running and colors.red or colors.green
        local bag,cap=C:backpack()
        info.Text=C.stage.."  |  Bag "..tostring(bag or "?").."/"..tostring(cap or "?")
            .."  |  Trees "..C.stats.felled.."  |  Sold "..C.stats.sold
        local last={}
        for i=math.max(1,#C.logs-9),#C.logs do
            local v=C.logs[i]
            if v then table.insert(last,(v.level or "").."  "..v.message) end
        end
        dbg.Text=table.concat(last,"\n")
    end)
end
