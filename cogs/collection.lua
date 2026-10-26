-- V4.3: E first, mouse click fallback; confirmation is backpack delta.
return function(C)
    function C:collectOne(log)
        -- A HUD 0/30 is not proof the server cleared its bag.
        if self.salePending or os.clock()<(self.pickupUnblockAt or 0) then return false end
        local job=self.wood[log]
        if not job or job.done or not self:woodReady(log,job) then return false end
        if self:isPaused() or self:urgentCombat()
            or self:mobInterrupt() then return false end
        local _,bagOwned,carried=self:equipmentStatus()
        -- V9: without backpack, HUD is 0/5 and CarriedLogs counts 0..5.
        -- Continue collecting by hand; do not mistake 0/5 for owned backpack.
        local handMode=not bagOwned
        local have,cap=self:backpack()
        if not have or not cap or have>=cap then return false end
        local at=self:woodPosition(log)
        if not at then return false end
        self.stage='WOOD: approaching'
        if not self:goTo(at,self.cfg.pickupRange) then
            job.nextTry=os.clock()+2.5; return false
        end
        if self.setWorkHover then self:setWorkHover(log,true) end
        if self:isPaused() or self:urgentCombat() or log.Parent~=self.logsFolder then
            return false
        end
        self.stage='WOOD: E pickup'
        local success=false
        for attempt=1,2 do
            if not self.running or self:isPaused() or self:urgentCombat() or job.done
                or self:mobInterrupt() then break end
            local before=self:backpack()
            local oldCarry=self.player:GetAttribute('CarriedLogs') or 0
            if before==nil or before>=cap then break end
            local p=self:woodPosition(log)
            if p then at=p end
            -- With loose logs in hands, use a directed click first.
            -- Blind E can THROW already held logs when the target isn't found.
            local sent=self:useItem(at,handMode and 'PickupClick' or 'Pickup')
            if sent then
                local deadline=os.clock()+.30
                while self.running and not self:isPaused() and os.clock()<deadline do
                    local after=self:backpack()
                    local held=self.player:GetAttribute('CarriedLogs') or 0
                    if (after and after>before) or held>oldCarry then
                        success=true; break
                    end
                    if log.Parent~=self.logsFolder then break end
                    task.wait(.035)
                end
            end
            if success or log.Parent~=self.logsFolder then break end
            -- Avoid E while already carrying logs: it can throw them.
            self.stage='WOOD: click fallback'
            local ok=(not handMode) and self:useItem(at,'PickupClick') or false
            if ok then
                local deadline=os.clock()+.48
                while self.running and not self:isPaused() and os.clock()<deadline do
                    local after=self:backpack()
                    local held=self.player:GetAttribute('CarriedLogs') or 0
                    if (after and after>before) or held>oldCarry then
                        success=true; break
                    end
                    if log.Parent~=self.logsFolder then break end
                    task.wait(.045)
                end
            end
            if success or log.Parent~=self.logsFolder then break end
            if attempt==1 then self:goTo(at,2.5) end
        end
        if success then
            self.stats.collected=self.stats.collected+1
            -- E sometimes takes the NEAREST log, not necessarily our chosen
            -- log. Never discard the chosen one while it's still in Workspace.
            if log.Parent==self.logsFolder then
                job.nextTry=os.clock()+.5
                self:note('Pickup +1, target log still present; retry queued')
            else
                job.done=true
                self:note('E pickup confirmed')
            end
            return true
        end
        if log.Parent~=self.logsFolder then
            return true -- Model was removed, probably collected by somebody.
        end
        job.failures=job.failures+1
        job.nextTry=os.clock()+math.min(18,1.5+job.failures*1.5)
        self:note('Pickup failed; wood remains in queue')
        return false
    end
    -- V4.8.8: Server-confirmed sale.
    -- V9 showed that a real deposit changes BOTH:
    --   CarriedLogs 5->0 and Stat_LogsSold 3908->3913.
    -- Cash/Stat_CashEarned may also rise from MOB KILLS and must NEVER
    -- be the sole reason we unlock pickups after a HUD 0/30 flicker.
    local function readCash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local cash=stats and stats:FindFirstChild('Cash')
        return cash and tonumber(cash.Value) or nil
    end
    local function readSold(self)
        return tonumber(self.player:GetAttribute('Stat_LogsSold'))
    end
    local function readCarried(self)
        return tonumber(self.player:GetAttribute('CarriedLogs'))
    end
    function C:findSellPad()
        local pads={}
        local function scan(where)
            if not where then return end
            for _,obj in ipairs(where:GetDescendants()) do
                if obj.Name=='DepositPad' and obj:IsA('BasePart') then
                    pads[#pads+1]=obj
                end
            end
        end
        scan(self.sellSpot)
        scan(self.map and self.map:FindFirstChild('SellIntakes'))
        local here=self:position()
        local best,distance=nil,math.huge
        for _,pad in ipairs(pads) do
            local d=here and (pad.Position-here).Magnitude or math.huge
            if d<distance then best,distance=pad,d end
        end
        return best
    end
    -- The owner of the sale lock is sellBag. Never unlock in workStep.
    function C:reconcileSale() return false end

    -- Manually selling in the V7 logger produced a DepositPad ray hit and
    -- the bag fell to zero immediately. Stand BESIDE the pad when clicking,
    -- not exactly over it where a straight-down aim can be obstructed.
    -- DO NOT do this if carrying logs in HANDS: LMB can throw them.
    local function clickSellPad(self,pad,origin)
        local _,ownsBag,carrying=self:equipmentStatus()
        if not ownsBag or (carrying and carrying>0 and readCarried(self)==nil) then
            return false,'hand_carry_no_click'
        end
        local _,root=self:character()
        if not root then return false,'no_root' end
        local center=pad.Position
        local delta=origin-center
        local side=Vector3.new(delta.X,0,delta.Z)
        if side.Magnitude<.25 then
            local forward=pad.CFrame.LookVector
            side=Vector3.new(forward.X,0,forward.Z)
        end
        if side.Magnitude<.25 then side=Vector3.new(0,0,1) end
        local dist=math.clamp(math.max(pad.Size.X,pad.Size.Z)*.6+2.5,5,10)
        local vantage=center+side.Unit*dist
        local ground=self:ground(vantage)
        if not ground then return false,'vantage_missing' end
        if self.cfg.move=='Instant TP' then
            root.CFrame=CFrame.new(ground)*root.CFrame.Rotation
            root.AssemblyLinearVelocity=Vector3.zero
        elseif not self:goTo(vantage,1.0) then
            return false,'walk_vantage_blocked'
        end
        self:aimAt(center+Vector3.new(0,pad.Size.Y*.5,0))
        task.wait(.05)
        if not self.running or self:isPaused() then return false,'interrupted' end
        -- VIM/Mouse click is NOT guaranteed to hit the pad: verify the ray.
        local cam=self.ws.CurrentCamera
        if cam then
            self:aimAt(center+Vector3.new(0,pad.Size.Y*.5,0))
            local params=RaycastParams.new()
            params.FilterType=Enum.RaycastFilterType.Exclude
            local ch=self.player.Character
            params.FilterDescendantsInstances=ch and {ch} or {}
            local hit=self.ws:Raycast(cam.CFrame.Position,cam.CFrame.LookVector*35,params)
            if not hit or hit.Instance~=pad then
                return false,'pad_not_under_crosshair'
            end
        end
        return self:tap(),'aimed_pad_click'
    end

    function C:sellBag()
        if not self.running or self:isPaused() then return false end
        local now=os.clock()
        local sale=self.salePending
        if sale and now<(sale.retryAt or 0) then return false end
        if not sale and now<(self.nextSellTry or 0) then return false end
        if not sale then
            local hud=self:backpack()
            local carried=readCarried(self)
            local before=math.max(hud or 0,carried or 0)
            if before<1 then return false end
            sale={before=before,at=now,retryAt=0,visits=0,
                soldStart=readSold(self),carriedStart=carried,cashStart=readCash(self)}
            self.salePending=sale
        end
        local pad=self:findSellPad()
        if not pad then
            sale.retryAt=os.clock()+1.5
            self:note('SELL: no DepositPad, retrying')
            return false
        end
        if self.clearWorkHover then self:clearWorkHover() end
        if self.disableAirHold then self:disableAirHold() end
        if self.releaseMouse then self:releaseMouse() end
        -- We deliberately DO NOT use generic ground() for the pad center:
        -- it can raycast onto decor/woodchipper OVER the actual DepositPad.
        local center=pad.Position
        local standPos=center+Vector3.new(0,pad.Size.Y*.5+2.65,0)
        local approachFrom=self:position() or center+Vector3.new(0,0,10)
        self.stage='SELL: entering DepositPad'
        -- goTo handles walking mode; precise placement below handles TP.
        if not self:goTo(center,.8) then
            sale.retryAt=os.clock()+.7
            return false
        end
        sale.visits=sale.visits+1
        local started=os.clock()
        local maxUntil=started+12.5
        local firstZero=nil
        local firstAck=nil
        local clicked=false
        local clickTried=false
        local retryClickAt=started+.85
        local lastClickReason='none'
        local lastTouch=started
        local bestSold=0
        local function audit(status,after,carried,soldDelta)
            self.sellAudit=self.sellAudit or {}
            local history=self.sellAudit
            history[#history+1]={status=status,before=sale.before,
                bagAfter=after,carriedAfter=carried,
                soldStart=sale.soldStart,soldAfter=readSold(self),
                soldDelta=soldDelta,cashBefore=sale.cashStart,
                cashAfter=readCash(self),visits=sale.visits,
                clicked=clicked,clickReason=lastClickReason,
                seconds=math.floor((os.clock()-started)*10+.5)/10}
            if #history>20 then table.remove(history,1) end
        end
        local function success(status,after,carried,soldDelta)
            audit(status,after,carried,soldDelta)
            self.stats.sold=self.stats.sold+sale.before
            self.salePending=nil
            -- Short post-sale settle avoids an immediate pickup before
            -- the server has replicated all parts of the bag update.
            self.pickupUnblockAt=os.clock()+.60
            self:note('SELL: confirmed '..tostring(sale.before)..' logs ('..status..')')
            return true
        end
        self.stage='SELL: waiting for server LogsSold + carried=0'
        while self.running and self.live and not self:isPaused()
            and not self:urgentCombat() and pad.Parent and os.clock()<maxUntil do
            local tick=os.clock()
            local _,root,hum=self:character()
            if not root then break end
            -- Keep avatar physically at the PAD, not floating above the
            -- woodchipper. Do not zero velocity every frame (touch events).
            if self.cfg.move=='Instant TP' then
                if (root.Position-standPos).Magnitude>1.35 then
                    root.CFrame=CFrame.new(standPos)*root.CFrame.Rotation
                end
            elseif hum and tick-lastTouch>.5 then
                hum:MoveTo(standPos)
            end
            if tick-lastTouch>.5 then lastTouch=tick end
            local bag=self:backpack()
            local carried=readCarried(self)
            local sold=readSold(self)
            local soldDelta=(sale.soldStart and sold)
                and math.max(0,sold-sale.soldStart) or 0
            bestSold=math.max(bestSold,soldDelta)
            if bag==0 and (carried==nil or carried==0) then
                firstZero=firstZero or tick
            else
                firstZero=nil
            end
            -- Strong server acknowledgement captured in V9; never substitute
            -- a random mob cash drop for a wood sale.
            local strongAck=sale.soldStart~=nil and sale.carriedStart~=nil
                and soldDelta>=sale.before and carried==0 and bag==0
            if strongAck then firstAck=firstAck or tick else firstAck=nil end
            if strongAck and firstAck and tick-firstAck>=.40 then
                return success('SERVER_LOGS_SOLD',bag,carried,soldDelta)
            end
            -- First allow pad contact. If it hasn't sold, click the PAD
            -- from beside it (not from inside its own collider).
            -- NEVER click while carrying logs without a backpack.
            if not clickTried and tick>=retryClickAt
                and not strongAck and math.max(carried or 0,bag or 0)>0 then
                clickTried=true
                self.stage='SELL: looking at DepositPad and clicking'
                local ok,why=clickSellPad(self,pad,approachFrom)
                clicked=ok and true or false
                lastClickReason=why
                if not ok then self:note('SELL: click '..tostring(why)..'; pad touch fallback') end
                -- Enter pad again after the click: this retriggers the pad
                -- touch path if the server ignores a click-only approach.
                local _,r=self:character()
                if r and self.cfg.move=='Instant TP' then
                    r.CFrame=CFrame.new(standPos)*r.CFrame.Rotation
                elseif r then
                    self:goTo(center,.8)
                end
                self.stage='SELL: waiting for server LogsSold + carried=0'
            end
            -- If attributes are completely unavailable, use the old long
            -- stable-HUD fallback. Never use this if either attr exists but
            -- explicitly disagrees with the HUD.
            if sale.soldStart==nil and sale.carriedStart==nil
                and firstZero and tick-firstZero>=5 and tick-started>=9 then
                return success('LEGACY_HUD_ONLY',bag,carried,soldDelta)
            end
            task.wait(.10)
        end
        local bag=self:backpack()
        local carried=readCarried(self)
        local soldDelta=(sale.soldStart and readSold(self))
            and math.max(0,readSold(self)-sale.soldStart) or 0
        audit('WAITING_SERVER',bag,carried,soldDelta)
        sale.retryAt=os.clock()+.85
        self:note('SELL: no server confirmation (hud='..tostring(bag)
            ..', carried='..tostring(carried)..', soldDelta='..tostring(soldDelta)
            ..'); retry on DepositPad')
        return false
    end
end
