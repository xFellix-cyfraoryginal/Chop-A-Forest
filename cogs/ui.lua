-- Compact Luau UI: no external UI framework, 6 small tabs, draggable/minimizable.
return function(C)
    local colors = {bg=Color3.fromRGB(11,16,28), panel=Color3.fromRGB(21,30,47),
        field=Color3.fromRGB(39,53,75), text=Color3.fromRGB(238,244,255),
        muted=Color3.fromRGB(152,172,197), accent=Color3.fromRGB(78,143,255),
        green=Color3.fromRGB(53,194,136), red=Color3.fromRGB(209,80,97)}
    local function obj(class, props, parent)
        local v=Instance.new(class)
        for k,val in pairs(props) do v[k]=val end
        v.Parent=parent
        return v
    end
    local function round(v, r)
        obj("UICorner",{CornerRadius=UDim.new(0,r or 8)},v)
        return v
    end
    local parent = type(gethui)=="function" and gethui() or game:GetService("CoreGui")
    local gui=obj("ScreenGui",{Name="ChopAForest_CS_V3",ResetOnSpawn=false,
        IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
    C.gui=gui
    local width,height=454,470
    local panel=round(obj("Frame",{Size=UDim2.fromOffset(width,height),
        Position=UDim2.fromOffset(26,125),BackgroundColor3=colors.bg,BorderSizePixel=0},gui),12)
    obj("UIStroke",{Color=colors.field,Thickness=1},panel)
    local head=round(obj("Frame",{Size=UDim2.new(1,0,0,48),
        BackgroundColor3=colors.panel,BorderSizePixel=0},panel),12)
    obj("TextLabel",{Size=UDim2.new(1,-104,1,0),Position=UDim2.fromOffset(15,0),
        BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,TextSize=14,TextColor3=colors.text,
        Text="CROP FOREST  /  SMART FARM V3.3"},head)
    local function button(parent,text,x,y,w,h,col,click)
        local b=round(obj("TextButton",{Size=UDim2.fromOffset(w,h),
            Position=UDim2.fromOffset(x,y),BackgroundColor3=col,BorderSizePixel=0,
            Text=text,TextColor3=colors.text,Font=Enum.Font.GothamSemibold,TextSize=12},parent),7)
        C:connect(b.MouseButton1Click,click)
        return b
    end
    button(head,"X",width-38,9,28,29,colors.red,function() C:unload() end)
    local minimized=false
    local content
    button(head,"_",width-75,9,28,29,colors.field,function()
        minimized=not minimized
        panel.Size=UDim2.fromOffset(width,minimized and 48 or height)
        if content then content.Visible=not minimized end
    end)
    content=obj("Frame",{Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,1,-48),
        BackgroundTransparency=1},panel)
    local names={"FARM","MOVE","COMBAT","SAFETY","EVENT","CONFIG","DEBUG"}
    local pages,tabBtns={},{}
    local tabs=obj("Frame",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,29),
        BackgroundTransparency=1},content)
    local active=names[1]
    local function selectPage(name)
        active=name
        for id,page in pairs(pages) do page.Visible=id==active end
        for id,b in pairs(tabBtns) do
            b.BackgroundColor3=id==active and colors.accent or colors.panel
        end
    end
    local tabWidth=(width-24)/#names
    for i,name in ipairs(names) do
        tabBtns[name]=button(tabs,name,math.floor((i-1)*tabWidth),0,
            math.floor(tabWidth-5),29,colors.panel,function() selectPage(name) end)
        local page=obj("ScrollingFrame",{Position=UDim2.fromOffset(12,44),
            Size=UDim2.new(1,-24,1,-129),CanvasSize=UDim2.fromOffset(0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,
            BackgroundTransparency=1,BorderSizePixel=0,Visible=(i==1)},content)
        obj("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},page)
        pages[name]=page
    end
    selectPage("FARM")
    local function settingRow(page,title,initial,cb)
        local row=round(obj("Frame",{Size=UDim2.new(1,-7,0,35),
            BackgroundColor3=colors.panel,BorderSizePixel=0},page),7)
        obj("TextLabel",{Position=UDim2.fromOffset(10,0),Size=UDim2.new(.56,-10,1,0),
            BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
            Text=title,Font=Enum.Font.Gotham,TextSize=12,TextColor3=colors.text},row)
        local b
        b=round(obj("TextButton",{Position=UDim2.new(.57,0,0,4),Size=UDim2.new(.41,-8,1,-8),
            Text=tostring(initial),TextColor3=colors.text,TextSize=11,
            Font=Enum.Font.GothamBold,BackgroundColor3=colors.field,BorderSizePixel=0},row),6)
        C:connect(b.MouseButton1Click,function() b.Text=tostring(cb()) end)
        return b
    end
    local function toggle(page,title,key)
        settingRow(page,title,C.config[key] and "ON" or "OFF",function()
            C.config[key]=not C.config[key]
            return C.config[key] and "ON" or "OFF"
        end)
    end
    local function options(page,title,key,values)
        local idx=table.find(values,C.config[key]) or 1
        settingRow(page,title,C.config[key],function()
            idx=idx%#values+1
            C.config[key]=values[idx]
            return values[idx]
        end)
    end
    local function number(page,title,key,minV,maxV,step)
        local row=round(obj("Frame",{Size=UDim2.new(1,-7,0,35),
            BackgroundColor3=colors.panel,BorderSizePixel=0},page),7)
        obj("TextLabel",{Position=UDim2.fromOffset(10,0),Size=UDim2.new(.53,-10,1,0),
            BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
            Text=title,Font=Enum.Font.Gotham,TextSize=12,TextColor3=colors.text},row)
        local field=round(obj("TextBox",{Position=UDim2.new(.56,0,0,4),
            Size=UDim2.new(.42,-8,1,-8),Text=tostring(C.config[key]),
            ClearTextOnFocus=false,TextColor3=colors.text,TextSize=12,
            Font=Enum.Font.GothamSemibold,BackgroundColor3=colors.field},row),6)
        C:connect(field.FocusLost,function()
            local n=tonumber(field.Text)
            if n then C.config[key]=math.floor(math.clamp(n,minV,maxV)/step+.5)*step end
            field.Text=tostring(C.config[key])
        end)
    end
    local function notice(page,text)
        obj("TextLabel",{Size=UDim2.new(1,-9,0,45),BackgroundTransparency=1,
            Text=text,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Gotham,
            TextColor3=colors.muted,TextSize=11},page)
    end
    toggle(pages.FARM,"Auto Collect","autoCollect")
    toggle(pages.FARM,"Auto Sell","autoSell")
    toggle(pages.FARM,"Sell after each tree","sellAfterTree")
    toggle(pages.FARM,"Sell at full bag","sellWhenFull")
    toggle(pages.FARM,"Prioritize Golden","goldFirst")
    options(pages.FARM,"Tree attack","attackMode",{"Input","Experimental Remote"})
    options(pages.FARM,"Tree tool slot","toolSlot",{"2","1","Auto"})
    notice(pages.FARM,"WOOD MEMORY: unfinished logs stay queued after danger, escape and failed pickup. F8 = emergency STOP.")
    options(pages.MOVE,"Movement","mode",{"Walk","Step TP","Instant TP"})
    number(pages.MOVE,"TP step speed","stepSpeed",8,180,2)
    number(pages.MOVE,"Tree attack delay","attackDelay",.45,3,.05)
    number(pages.MOVE,"Held item cooldown","itemCooldown",.2,3,.05)
    toggle(pages.MOVE,"Read equipped Tool cooldown","autoToolCooldown")
    number(pages.MOVE,"Log spawn minimum age","logMinAge",.5,4,.1)
    number(pages.MOVE,"Log settle seconds","logSettleTime",.3,2,.1)
    number(pages.MOVE,"Falling logs timeout","logSettleTimeout",2,9,.5)
    number(pages.MOVE,"Tree hit distance","hitDistance",2.5,6,.1)
    number(pages.MOVE,"Search trees within","maxTreeDistance",25,1500,5)
    options(pages.MOVE,"Area","selectedArea",{"Current","All","1","2","3","4","5","6","7","8"})
    number(pages.MOVE,"Pickup approach","pickupDistance",2.5,7,.1)
    number(pages.MOVE,"Pickup delay","pickupDelay",.15,1,.05)
    number(pages.MOVE,"Pickup retries","pickupRetries",1,5,1)
    number(pages.MOVE,"Recover wood range","maxLogDistance",80,650,10)
    toggle(pages.COMBAT,"Auto Combat","autoCombat")
    options(pages.COMBAT,"Combat mode","combatMode",{"Defend","Hunt"})
    options(pages.COMBAT,"Priority","combatPriority",{"Threats","Combat","Trees"})
    options(pages.COMBAT,"Combat tool slot","combatTool",{"2","1","Auto"})
    number(pages.COMBAT,"Attack distance","combatReach",3,10,.5)
    number(pages.COMBAT,"Enemy search range","combatSearch",15,350,5)
    number(pages.COMBAT,"Combat hit delay","combatDelay",.35,2,.05)
    number(pages.COMBAT,"Absolute HP floor","combatHealth",30,95,1)
    toggle(pages.COMBAT,"Allow bosses (risky)","allowBoss")
    toggle(pages.SAFETY,"Survival watchdog","safetyOn")
    toggle(pages.SAFETY,"Avoid dangerous trees/logs","avoidMobs")
    number(pages.SAFETY,"Retreat at HP %","panicPercent",35,95,5)
    number(pages.SAFETY,"Resume at HP %","resumePercent",60,100,5)
    number(pages.SAFETY,"Mob crowd limit","maxThreats",1,5,1)
    number(pages.SAFETY,"Threat radius","dangerRadius",8,30,1)
    number(pages.SAFETY,"Keep away from mobs","avoidDistance",4,22,1)
    options(pages.SAFETY,"Emergency escape","escapeMode",{"Match farm","Instant TP","Step TP"})
    toggle(pages.SAFETY,"Circle threats while walking","kiteEnabled")
    number(pages.SAFETY,"Kite activation range","kiteRadius",6,25,1)
    number(pages.SAFETY,"Orbit radius","orbitDistance",3,10,.5)
    number(pages.SAFETY,"Side step length","kiteStep",2,9,.5)
    number(pages.SAFETY,"Melee panic radius","meleeDangerRadius",3,12,.5)
    number(pages.SAFETY,"Heal timeout (sec)","healTimeout",10,120,5)
    notice(pages.SAFETY,"If HP is low or you are surrounded: interrupt the current action, retreat, hold until healed. If recovery fails: STOP. Emergency TP may be rejected by the server.")
    toggle(pages.COMBAT,"Highlight target","showMobs")
    toggle(pages.EVENT,"Graveyard trees only","eventOnly")
    toggle(pages.EVENT,"Graveyard mobs only","eventMobs")
    notice(pages.EVENT,"Mobs auto-detected by MonsterId, Monster, HP, MaxHP and State. Bosses are OFF by default for safety. No name whitelist.")
    local eventLabel=obj("TextLabel",{Size=UDim2.new(1,-7,0,46),Text="Event scan...",
        TextColor3=colors.muted,Font=Enum.Font.Code,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=colors.panel},pages.EVENT)
    round(eventLabel,7)
    notice(pages.CONFIG,"No Eco toggle. Indexing and modest UI refresh remain optimized automatically; safety checks run independently.")
    number(pages.CONFIG,"Tree failures limit","maxFailures",1,8,1)
    toggle(pages.CONFIG,"Highlight tree","showTree")
    toggle(pages.CONFIG,"Highlight logs","showLogs")
    notice(pages.CONFIG,"The server can reject teleport or attacks. Experimental Remote is unverified; Input is recommended.")
    local debug=round(obj("TextLabel",{Size=UDim2.new(1,-7,0,235),
        BackgroundColor3=colors.panel,TextColor3=colors.muted,
        Text="No events yet",Font=Enum.Font.Code,TextSize=12,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},pages.DEBUG),7)
    local status=obj("TextLabel",{Position=UDim2.fromOffset(15,height-48-75),
        Size=UDim2.new(1,-30,0,33),Text="IDLE",BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Gotham,
        TextColor3=colors.muted,TextSize=11},content)
    local start=button(content,"START / F8 STOP",12,height-48-37,195,31,colors.green,function()
        if C.running then C:stop() else C:start() end
    end)
    button(content,"EXPORT",216,height-48-37,102,31,colors.accent,function()
        local ok,msg=C:export()
        C:note(ok and "info" or "error",msg)
    end)
    button(content,"UNLOAD",326,height-48-37,116,31,colors.red,function() C:unload() end)
    local drag,point,origin=false,nil,nil
    C:connect(head.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true;point=input.Position;origin=panel.Position
        end
    end)
    C:connect(head.InputEnded,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    C:connect(C.uid.InputChanged,function(input)
        if drag and input.UserInputType==Enum.UserInputType.MouseMovement then
            local d=input.Position-point
            panel.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
        end
    end)
    local accumulator=0
    C:connect(game:GetService("RunService").Heartbeat,function(dt)
        if not C.alive then return end
        accumulator=accumulator+dt
        if accumulator < .55 then return end
        accumulator=0
        start.Text=C.running and "STOP  [F8]" or "START"
        start.BackgroundColor3=C.running and colors.red or colors.green
        local bag,cap=C:backpack()
        local hp, maxHP = C:healthStatus()
        local wood=C:woodStatus(C.config.maxLogDistance)
        status.Text=string.format("%s | HP %.0f/%.0f | BAG %s/%s | WOOD %d [%d ready]",
            C.stage,hp,maxHP,tostring(bag or "?"),tostring(cap or "?"),wood.total,wood.ready)
        if active == "DEBUG" then
            local recent={}
            for i=math.max(1,#C.logs-10),#C.logs do
                if C.logs[i] then table.insert(recent,C.logs[i].level.."  "..C.logs[i].message) end
            end
            debug.Text=table.concat(recent,"\n")
        elseif active == "EVENT" then
            local event=C:eventInfo()
            eventLabel.Text=string.format("AREA: %s\nTIME: %.1f  |  MOBS: %d  |  BOSSES: %d",
                event.areaName or "?",event.clock,event.minions,event.bosses)
        end
    end)
end
