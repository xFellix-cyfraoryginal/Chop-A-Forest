-- Fast/safe combat switch: only fall back if the Guardian visibly resets HP.
return function(C)
    C.combatFallback=false
    C.bossResetWatch=nil
    C.combatOrbitShift=0
    function C:enterCombatFallback(reason)
        if self.combatFallback then return end
        self.combatFallback=true
        self.cfg.dodge=true
        self.followHeight=1.55
        self:note('BOSS RESET: old boss priority + selective dodge ('..tostring(reason)..')')
    end
    local rs=game:GetService('RunService')
    local lastScan=-100
    C:connect(rs.Heartbeat,function()
        if not C.live or not C.running or not C.cfg.combat then return end
        if os.clock()-lastScan<.16 then return end
        lastScan=os.clock()
        local boss=C:pickBoss()
        if boss then
            local hp=tonumber(boss:GetAttribute('HP'))
            local max=tonumber(boss:GetAttribute('MaxHP')) or 0
            local state=boss:GetAttribute('State')
            if not hp or max<=0 then return end
            if state=='Dead' or hp<=0 then
                if C.bossResetWatch then C.bossResetWatch.dead=true end
                return
            end
            local last=C.bossResetWatch
            local id=tostring(boss:GetAttribute('MonsterId') or '')
            if last and last.id==id and last.enemy==boss then
                if last.hp and last.hp<max*.85
                    and hp-last.hp>math.max(8,max*.25)
                    and hp>last.hp and state=='Fighting' then
                    C:enterCombatFallback('Guardian HP '..math.floor(last.hp)..' -> '..math.floor(hp))
                end
                last.hp=hp
                last.seenAt=os.clock()
                last.dead=false
            else
                if last and not last.dead and last.hp and last.max
                    and last.hp>0 and last.hp<last.max*.70
                    and last.seenAt and os.clock()-last.seenAt<35
                    and not (C.player:FindFirstChild('PlayerGui')
                        and C.player.PlayerGui:FindFirstChild('RunEnd')
                        and C.player.PlayerGui.RunEnd.Enabled) then
                    C:enterCombatFallback('Guardian replaced during battle')
                end
                C.bossResetWatch={enemy=boss,id=id,hp=hp,max=max,seenAt=os.clock()}
            end
        end
    end)
end
