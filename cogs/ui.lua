-- V4.7.5: compact farm/combat panel + Walk/Instant TP movement.
return function(C)
    local function make(class,props,parent)
        local obj=Instance.new(class)
        for k,v in pairs(props) do obj[k]=v end
        obj.Parent=parent
        return obj
    end
    local function round(obj,r)
        make('UICorner',{CornerRadius=UDim.new(0,r or 8)},obj)
        return obj
    end
    local white=Color3.fromRGB(239,243,251)
    local muted=Color3.fromRGB(164,178,199)
    local dark=Color3.fromRGB(15,20,31)
    local surface=Color3.fromRGB(34,44,62)
    local green=Color3.fromRGB(35,159,113)
    local red=Color3.fromRGB(202,75,90)
    local parent=game:GetService('CoreGui')
    if type(gethui)=='function' then
        local ok,hui=pcall(gethui)
        if ok and hui then parent=hui end
    end
    local gui=make('ScreenGui',{Name='CAF_FarmMobs_V4_7_5',ResetOnSpawn=false,
        IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
    C.gui=gui
    local panel=round(make('Frame',{Size=UDim2.fromOffset(344,322),
        Position=UDim2.fromOffset(24,112),BackgroundColor3=dark,BorderSizePixel=0},gui),11)
    make('UIStroke',{Color=Color3.fromRGB(68,83,106),Thickness=1},panel)
    local head=round(make('Frame',{Size=UDim2.new(1,0,0,44),
        BackgroundColor3=surface,BorderSizePixel=0},panel),11)
    make('TextLabel',{Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-86,1,0),
        Text='CHOP A FOREST  |  FARM + MOBS',BackgroundTransparency=1,
        TextColor3=white,TextSize=13,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left},head)
    local function action(parent,text,y,height,color,click,x,width)
        local btn=round(make('TextButton',{Position=UDim2.fromOffset(x or 10,y),
            Size=UDim2.fromOffset(width or 324,height),Text=text,BackgroundColor3=color,
            TextColor3=white,TextSize=14,Font=Enum.Font.GothamBold,
            BorderSizePixel=0,AutoButtonColor=true},parent),8)
        C:connect(btn.MouseButton1Click,click)
        return btn
    end
    action(head,'X',7,29,red,function() C:unload() end,308,28)
    local collapsed=false
    local body=make('Frame',{Position=UDim2.fromOffset(0,44),
        Size=UDim2.new(1,0,1,-44),BackgroundTransparency=1},panel)
    action(head,'_',7,29,dark,function()
        collapsed=not collapsed
        panel.Size=UDim2.fromOffset(344,collapsed and 44 or 322)
        body.Visible=not collapsed
    end,272,28)
    local taskLabel=make('TextLabel',{Position=UDim2.fromOffset(12,7),
        Size=UDim2.new(1,-24,0,27),BackgroundTransparency=1,
        Text='Idle',TextColor3=white,TextSize=12,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},body)
    local statsLabel=make('TextLabel',{Position=UDim2.fromOffset(12,32),
        Size=UDim2.new(1,-24,0,24),BackgroundTransparency=1,
        Text='HP -- | Bag -- | Kills 0',TextColor3=muted,
        TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},body)
    local run=action(body,'START  [F6]',67,43,green,function()
        if C.running then C:stop() else C:start() end
    end)
    local farm=action(body,'AUTO FARM: ON',119,38,surface,function()
        C.cfg.farm=not C.cfg.farm
        if not C.cfg.farm then C:cancelMove() end
        C:note('Auto Farm '..(C.cfg.farm and 'ON' or 'OFF'))
    end)
    local combat=action(body,'KILL MOBS: ON',165,38,surface,function()
        C.cfg.combat=not C.cfg.combat
        if not C.cfg.combat then
            if C.stopHover then C:stopHover() end
            -- Don't forget pending mobs; enabling again resumes hunting.
        end
        C:note('Kill Mobs '..(C.cfg.combat and 'ON' or 'OFF'))
    end)
    local move=action(body,'MOVEMENT: '..C.cfg.move,211,38,surface,function()
        C.cfg.move=(C.cfg.move=='Walk') and 'Instant TP' or 'Walk'
        -- Interrupt an old MoveTo/path without cancelling an active combat target.
        C.motion=C.motion+1
        C:note('Movement changed to '..C.cfg.move)
    end)
    make('TextLabel',{Position=UDim2.fromOffset(12,253),Size=UDim2.new(1,-24,0,22),
        BackgroundTransparency=1,Text='F6 START/STOP   |   F8 STOP',
        TextSize=11,TextColor3=muted,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left},body)
    local dragging,dragStart,startPos=false,nil,nil
    C:connect(head.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or
            input.UserInputType==Enum.UserInputType.Touch then
            dragging=true;dragStart=input.Position;startPos=panel.Position
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
            panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,
                startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    task.spawn(function()
        while C.live and gui.Parent do
            local hp,maxHP=C:health()
            local bag,capacity=C:backpack()
            taskLabel.Text='Task: '..tostring(C.stage)
            statsLabel.Text=string.format('HP %d/%d  |  Bag %s/%s  |  Kills %d',
                math.floor(hp),math.floor(maxHP),tostring(bag or '-'),
                tostring(capacity or '-'),C.stats.kills or 0)
            run.Text=C.running and 'STOP  [F6/F8]' or 'START  [F6]'
            run.BackgroundColor3=C.running and red or green
            farm.Text='AUTO FARM: '..(C.cfg.farm and 'ON' or 'OFF')
            farm.BackgroundColor3=C.cfg.farm and green or surface
            combat.Text='KILL MOBS: '..(C.cfg.combat and 'ON' or 'OFF')
            combat.BackgroundColor3=C.cfg.combat and green or surface
            move.Text='MOVEMENT: '..C.cfg.move
            move.BackgroundColor3=C.cfg.move=='Walk' and green or surface
            task.wait(.28)
        end
    end)
end
