return function(C)
    local function make(class, props, parent)
        local item=Instance.new(class)
        for key,val in pairs(props) do item[key]=val end
        item.Parent=parent
        return item
    end
    local function round(frame,radius)
        make('UICorner',{CornerRadius=UDim.new(0,radius or 8)},frame)
        return frame
    end
    local ink=Color3.fromRGB(234,240,250)
    local muted=Color3.fromRGB(158,173,194)
    local bg=Color3.fromRGB(15,20,31)
    local surface=Color3.fromRGB(31,40,57)
    local blue=Color3.fromRGB(66,135,240)
    local red=Color3.fromRGB(204,79,89)
    local green=Color3.fromRGB(38,163,119)
    local parent=game:GetService('CoreGui')
    if type(gethui)=='function' then
        local ok,custom=pcall(gethui)
        if ok and custom then parent=custom end
    end
    local gui=make('ScreenGui',{Name='CAF_GlobalHunt_V4_2',ResetOnSpawn=false,
        IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
    C.gui=gui
    local panel=round(make('Frame',{Size=UDim2.fromOffset(394,382),
        Position=UDim2.fromOffset(26,112),BackgroundColor3=bg,BorderSizePixel=0},gui),12)
    make('UIStroke',{Color=Color3.fromRGB(65,78,99),Thickness=1},panel)
    local top=round(make('Frame',{Size=UDim2.new(1,0,0,48),
        BackgroundColor3=surface,BorderSizePixel=0},panel),12)
    make('TextLabel',{Size=UDim2.new(1,-92,1,0),Position=UDim2.fromOffset(13,0),
        BackgroundTransparency=1,Text='CHOP A FOREST  /  GLOBAL HUNT V4.2',TextSize=14,
        Font=Enum.Font.GothamBold,TextColor3=ink,TextXAlignment=Enum.TextXAlignment.Left},top)
    local function button(parent,text,y,height,color,clicked)
        local b=round(make('TextButton',{Size=UDim2.new(1,-20,0,height or 37),
            Position=UDim2.fromOffset(10,y or 0),BackgroundColor3=color or surface,
            BorderSizePixel=0,Font=Enum.Font.GothamSemibold,TextSize=13,
            TextColor3=ink,Text=text,AutoButtonColor=true},parent),8)
        C:connect(b.MouseButton1Click,clicked)
        return b
    end
    local close=round(make('TextButton',{Size=UDim2.fromOffset(30,29),
        Position=UDim2.fromOffset(355,9),Text='X',Font=Enum.Font.GothamBold,
        TextSize=12,TextColor3=ink,BackgroundColor3=red,BorderSizePixel=0},top),6)
    C:connect(close.MouseButton1Click,function() C:unload() end)
    local min=round(make('TextButton',{Size=UDim2.fromOffset(30,29),
        Position=UDim2.fromOffset(320,9),Text='_',Font=Enum.Font.GothamBold,
        TextSize=12,TextColor3=ink,BackgroundColor3=bg,BorderSizePixel=0},top),6)
    local collapsed=false
    local content=make('Frame',{Position=UDim2.fromOffset(0,48),
        Size=UDim2.new(1,0,1,-48),BackgroundTransparency=1},panel)
    C:connect(min.MouseButton1Click,function()
        collapsed=not collapsed
        panel.Size=UDim2.fromOffset(394,collapsed and 48 or 382)
        content.Visible=not collapsed
    end)
    local bar=make('Frame',{Position=UDim2.fromOffset(10,8),
        Size=UDim2.new(1,-20,0,32),BackgroundTransparency=1},content)
    local pages, tabs={},{}
    for i,name in ipairs({'MAIN','TOOLS','DEBUG'}) do
        local tab=round(make('TextButton',{Position=UDim2.fromOffset((i-1)*127,0),
            Size=UDim2.fromOffset(119,30),Text=name,Font=Enum.Font.GothamBold,
            TextSize=12,TextColor3=ink,BackgroundColor3=surface,BorderSizePixel=0},bar),7)
        tabs[name]=tab
        pages[name]=make('Frame',{Position=UDim2.fromOffset(0,49),
            Size=UDim2.new(1,0,1,-53),BackgroundTransparency=1,Visible=(i==1)},content)
    end
    local function select(name)
        for title,page in pairs(pages) do
            page.Visible=title==name
            tabs[title].BackgroundColor3=title==name and blue or surface
        end
    end
    for name,b in pairs(tabs) do
        C:connect(b.MouseButton1Click,function() select(name) end)
    end
    select('MAIN')
    local function label(page,text,y,size)
        return make('TextLabel',{Position=UDim2.fromOffset(13,y),Size=UDim2.new(1,-26,0,27),
            BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
            Text=text,Font=Enum.Font.Gotham,TextSize=size or 13,
            TextColor3=muted,TextTruncate=Enum.TextTruncate.AtEnd},page)
    end
    local main=pages.MAIN
    local status=label(main,'Status: Idle',4,14)
    status.TextColor3=ink
    local detail=label(main,'Ready',34,12)
    local bag=label(main,'HP --   |   Bag --   |   Wood --',61,12)
    local runButton=button(main,'START',96,43,green,function()
        if C.running then C:stop() else C:start() end
    end)
    local moveBtn=button(main,'Movement: Instant TP',148,35,surface,function() end)
    C:connect(moveBtn.MouseButton1Click,function()
        local options={'Walk','Instant TP'}
        local index=table.find(options,C.cfg.move) or 1
        C.cfg.move=options[index%#options+1]
        moveBtn.Text='Movement: '..C.cfg.move
    end)
    local priorityBtn=button(main,'Priority: FARM FIRST',190,35,surface,function() end)
    C:connect(priorityBtn.MouseButton1Click,function()
        C.cfg.priority=C.cfg.priority=='FARM' and 'ATTACK' or 'FARM'
        priorityBtn.Text='Priority: '..C.cfg.priority..' FIRST'
        C:note('Priority changed: '..C.cfg.priority..' FIRST')
    end)
    label(main,'F8  |  EMERGENCY STOP',237,12)
    local tools=pages.TOOLS
    label(tools,'Equip owned tools in-game before using them.',6,12)
    local profile=button(tools,'Tool: Auto',47,39,surface,function() end)
    C:connect(profile.MouseButton1Click,function()
        local items={'Auto','Axe','Fists','Chainsaw','Pistol','Vacuum'}
        local i=table.find(items,C.cfg.tool) or 1
        C.cfg.tool=items[i%#items+1]
        profile.Text='Tool: '..C.cfg.tool
    end)
    local combat=button(tools,'Combat: ON',95,37,surface,function() end)
    C:connect(combat.MouseButton1Click,function()
        C.cfg.combat=not C.cfg.combat
        combat.Text='Combat: '..(C.cfg.combat and 'ON' or 'OFF')
    end)
    local exp=button(tools,'Unverified tools: OFF',142,37,surface,function() end)
    C:connect(exp.MouseButton1Click,function()
        C.cfg.useExperimental=not C.cfg.useExperimental
        exp.Text='Unverified tools: '..(C.cfg.useExperimental and 'ON' or 'OFF')
    end)
    local holdBtn=button(tools,'HP Pause: ON (6s at <=40%)',187,34,surface,function() end)
    C:connect(holdBtn.MouseButton1Click,function()
        C.cfg.hpPause=not C.cfg.hpPause
        holdBtn.Text='HP Pause: '..(C.cfg.hpPause and 'ON' or 'OFF')
            ..' ('..C.cfg.pauseSeconds..'s at <=40%)'
    end)
    local durationBtn=button(tools,'Pause duration: 6 seconds',227,34,surface,function() end)
    C:connect(durationBtn.MouseButton1Click,function()
        local values={4,6,8,10}
        local i=table.find(values,C.cfg.pauseSeconds) or 2
        C.cfg.pauseSeconds=values[i%#values+1]
        durationBtn.Text='Pause duration: '..C.cfg.pauseSeconds..' seconds'
        holdBtn.Text='HP Pause: '..(C.cfg.hpPause and 'ON' or 'OFF')
            ..' ('..C.cfg.pauseSeconds..'s at <=40%)'
    end)
    local debug=pages.DEBUG
    local debugInfo=label(debug,'Waiting for actions...',6,12)
    local expBtn=button(debug,'EXPORT DIAGNOSTICS',49,39,blue,function()
        local records={version=C.version,stage=C.stage,stats=C.stats,
            messages=C.messages,settings=C.cfg,wood=C:woodCounts(),
            running=C.running}
        local ok,data=pcall(function() return C.http:JSONEncode(records) end)
        if not ok then C:note('Export failed'); return end
        if type(writefile)=='function' then
            local file='CAF_V4_debug_'..os.date('%Y%m%d_%H%M%S')..'.json'
            if pcall(writefile,file,data) then C:note('Saved '..file); return end
        end
        if type(setclipboard)=='function' then
            pcall(setclipboard,data); C:note('Debug JSON copied to clipboard')
        else C:note('Executor lacks writefile and clipboard') end
    end)
    local reset=button(debug,'CLEAR DEBUG MESSAGES',98,36,surface,function()
        C.messages={}; C:note('Messages cleared')
    end)
    label(debug,'No network hooks. No external UI library.',151,12)
    local dragging,dragStart,frameStart=false,nil,nil
    C:connect(top.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or
            input.UserInputType==Enum.UserInputType.Touch then
            dragging,dragStart,frameStart=true,input.Position,panel.Position
        end
    end)
    C:connect(C.uis.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or
            input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    C:connect(C.uis.InputChanged,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or
            input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            panel.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+delta.X,
                frameStart.Y.Scale,frameStart.Y.Offset+delta.Y)
        end
    end)
    task.spawn(function()
        while C.live and gui.Parent do
            local hp,cap=C:health()
            local have,maxBag=C:backpack()
            local wood=C:woodCounts()
            status.Text='Task: '..C.stage
            detail.Text=C.detail
            bag.Text=string.format('HP %d/%d   |   Bag %s/%s   |   Wood %d',
                math.floor(hp),math.floor(cap),tostring(have or '-'),
                tostring(maxBag or '-'),wood)
            runButton.Text=C.running and 'STOP   [F8]' or 'START'
            runButton.BackgroundColor3=C.running and red or green
            local info=C.treeScan or {}
            local threats=C:threats(C:position(),math.huge)
            debugInfo.Text=string.format('Trees %d/%d  |  Mobs %d  |  Chopped %d  |  Kills %d',
                info.valid or 0,info.cached or 0,threats,C.stats.trees,C.stats.kills)
            task.wait(.65)
        end
    end)
end
