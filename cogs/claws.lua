-- Clawman Speed shop: reads current UI price, buys only ClawsSpeed.
-- V11 observed: first price 225, BuyUpgrade:FireServer('ClawsSpeed').
return function(C)
    C.nextClawsTry, C.clawsBuyFailures, C.clawsBuying = 0, 0, false
    local knownFirstPrice=225 -- V11 only, NEVER reuse this for later levels

    local function currentCash(self)
        local stats=self.player:FindFirstChild('leaderstats')
        local cash=stats and stats:FindFirstChild('Cash')
        return cash and tonumber(cash.Value) or nil
    end
    local function parsePrice(raw)
        raw=tostring(raw or ''):upper()
        if raw:find('MAX',1,true) then return nil,'MAX' end
        if raw:find('LOCK',1,true) then return nil,'LOCKED' end
        if raw:find('OWNED',1,true) then return nil,'OWNED' end
        raw=raw:gsub('<[^>]+>',''):gsub('[,%s]','')
        local digits=raw:match('%d+')
        local cost=digits and tonumber(digits)
        if cost and cost>=1 and cost<=100000000 then return cost,'UI' end
        return nil,'UNKNOWN'
    end
    local function child(parent,name)
        return parent and parent:FindFirstChild(name)
    end
    -- Read the price from Clawman's own Attack Speed card, even if TAB is hidden.
    local function speedCard(self)
        local pg=child(self.player,'PlayerGui')
        local u=child(pg,'Upgrades')
        local panel=child(u,'Panel')
        local page=child(panel,'Page2')
        local claws=child(page,'Claws')
        if not claws then return nil,nil,panel,u end
        for _,obj in ipairs(claws:GetDescendants()) do
            if obj.Name=='Title' and obj:IsA('TextLabel')
                and obj.Text:lower():match('^%s*attack speed%s*$') then
                local card=obj.Parent and obj.Parent.Parent
                local price=child(child(card,'Price'),'Amount')
                if price and price:IsA('TextLabel') then
                    return price.Text,'CARD',panel,u
                end
            end
        end
        return nil,nil,panel,u
    end
    function C:clawsSpeedOffer()
        local level=tonumber(self.player:GetAttribute('Up_ClawsSpeed')) or 0
        if self.player:GetAttribute('OwnsClaws')~=true then
            return nil,'NOT_OWNED',level
        end
        if level>=6 then return nil,'MAX',level end
        local raw,_,panel,upgrades=speedCard(self)
        local price,status=parsePrice(raw)
        if status=='MAX' then return nil,'MAX',level end
        if status=='LOCKED' or status=='OWNED' then return nil,status,level end
        if price then
            -- Client card can lag behind server level changes. Never reuse
            -- the cost of the just-purchased level while it is still stale.
            if self.clawsLastCost==price and self.clawsLastFromLevel
                and level>self.clawsLastFromLevel then
                return nil,'WAIT_PRICE_REFRESH',level
            end
            return price,'CARD',level
        end
        -- Detail price is trustworthy only when Clawman Attack Speed is selected.
        local detail=child(panel,'Detail')
        local info=child(detail,'Info')
        local key=child(info,'Key')
        local value=child(info,'Value')
        if upgrades and upgrades.Enabled and key and value
            and tostring(key.Text)=='Clawman' and tostring(value.Text)=='Attack Speed' then
            local right=child(child(child(info,'Buy'),'Row'),'Right')
            local left=child(child(child(info,'Buy'),'Row'),'Left')
            local cost,st=parsePrice(right and right.Text)
            if left and tostring(left.Text):upper():find('MAX',1,true) then
                return nil,'MAX',level
            end
            if cost then return cost,'DETAIL',level end
            if st=='MAX' then return nil,'MAX',level end
        end
        if level==0 then return knownFirstPrice,'V11_INITIAL',level end
        return nil,'PRICE_NOT_READY',level
    end
    function C:clawSpeedMax()
        local _,status=self:clawsSpeedOffer()
        return status=='MAX'
    end
    function C:tryBuyClawsSpeed(reason)
        if not self.live or not self.running or not self.cfg.farm
            or not self.cfg.autoClawsSpeed or self.clawsBuying then return false end
        if os.clock()<self.nextClawsTry then return false end
        -- Backpack has precedence, so a fresh run does not spend its money on Claws.
        if self.cfg.autoBackpack and
            (tonumber(self.player:GetAttribute('Up_GearBackpack')) or 0)<1 then
            return false
        end
        local price,source,level=self:clawsSpeedOffer()
        if not price then return false end
        local cash=currentCash(self)
        if not cash or cash<price then return false end
        local shared=game:GetService('ReplicatedStorage')
        local remotes=child(child(shared,'Shared'),'Services')
        remotes=child(remotes,'ChopRemotes')
        local remote=child(remotes,'BuyUpgrade')
        if not (remote and remote:IsA('RemoteEvent')) then
            self.nextClawsTry=os.clock()+30
            self:note('Claws Speed: BuyUpgrade remote missing')
            return false
        end
        self.clawsBuying=true
        self.nextClawsTry=os.clock()+3
        local ok,err=pcall(function() remote:FireServer('ClawsSpeed') end)
        if not ok then
            self.clawsBuying=false
            self.nextClawsTry=os.clock()+35
            self:note('Claws Speed request failed: '..tostring(err))
            return false
        end
        self:note('Claws Speed TRY Lv'..level..' price '..price
            ..' ('..source..', '..tostring(reason or 'sell')..')')
        local untilAt=os.clock()+1.5
        while self.live and self.running and os.clock()<untilAt do
            local newLevel=tonumber(self.player:GetAttribute('Up_ClawsSpeed')) or 0
            if newLevel>level then
                self.clawsBuying=false
                self.clawsLastCost,self.clawsLastFromLevel=price,level
                self.clawsBuyFailures=0
                self.nextClawsTry=os.clock()+.6
                self:note('Claws Speed CONFIRMED Lv'..newLevel)
                -- Recheck updated card price for another level if money remains.
                task.delay(.85,function()
                    if self.live and self.running then
                        self:tryBuyClawsSpeed('next level')
                    end
                end)
                return true
            end
            task.wait(.10)
        end
        self.clawsBuying=false
        self.clawsBuyFailures=self.clawsBuyFailures+1
        self.nextClawsTry=os.clock()+math.min(180,30*2^math.min(self.clawsBuyFailures,3))
        self:note('Claws Speed NOT CONFIRMED; server rejected/timeout. Next try later')
        return false
    end
    -- Buying happens at the cash payout, without opening TAB or stopping on pad.
    local subscribed=nil
    local function bindCash()
        local ls=C.player:FindFirstChild('leaderstats')
        local cash=ls and ls:FindFirstChild('Cash')
        if cash==subscribed or not cash then return end
        subscribed=cash
        C:connect(cash:GetPropertyChangedSignal('Value'),function()
            task.defer(function()
                if C.live and C.running then
                    C:tryBuyClawsSpeed('sale payout')
                end
            end)
        end)
    end
    bindCash()
    C:connect(C.player.ChildAdded,function(ch)
        if ch.Name=='leaderstats' then
            bindCash()
            C:connect(ch.ChildAdded,function() bindCash() end)
        end
    end)
    local initial=C.player:FindFirstChild('leaderstats')
    if initial then C:connect(initial.ChildAdded,function() bindCash() end) end
end
