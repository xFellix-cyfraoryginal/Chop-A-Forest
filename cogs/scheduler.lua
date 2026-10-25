-- Exactly one decision-maker. Priority: survive > sell full > remembered wood > combat > tree.
return function(C)
    function C:workStep()
        local bag,cap=self:backpack()
        if bag==nil then
            self.stage='WAIT: backpack HUD'
            task.wait(.6); return
        end
        if self.panic then self:recover(); return end
        if self.cfg.sell and cap and bag>=cap then
            if not self:sellBag() then task.wait(1) end
            return
        end
        local wood,ready=self:woodCounts()
        if self.cfg.collect and wood>0 then
            local log=self:chooseWood()
            if log then self:collectOne(log); return end
            if ready==0 then
                -- Fresh/falling wood gets priority over new tree selection.
                local coming=false
                local now=os.clock()
                for obj,job in pairs(self.wood) do
                    if obj.Parent==self.logsFolder and not job.done
                        and now-job.born<8.5 then coming=true; break end
                end
                if coming then
                    self.stage='WAIT: falling logs ('..wood..')'
                    task.wait(.32); return
                end
            end
        end
        if self.cfg.sell and bag>0 then
            if not self:sellBag() then task.wait(1) end
            return
        end
        local enemy=self:pickEnemy()
        if enemy then self:fight(enemy); return end
        local tree=self:chooseTree()
        if tree then self:chopTree(tree); return end
        self.stage=wood>0 and 'WAIT: wood unsafe / cooldown' or 'WAIT: no safe trees'
        task.wait(.55)
    end
    function C:workLoop(session)
        while self.running and self.live and self.session==session do
            local ok,err=pcall(function() self:workStep() end)
            if not ok then
                self:note('Error: '..tostring(err))
                self.stage='ERROR: stopped'
                self:stop()
                break
            end
            task.wait(self.cfg.idlePause)
        end
    end
    function C:start()
        if self.running or not self.live then return end
        if not self.treesFolder or not self.logsFolder then
            self:note('Missing Workspace.Map.Trees or Workspace.Logs')
            return
        end
        self.running=true
        self.session=self.session+1
        self.panic=false
        self.lastHP=nil
        local session=self.session
        self.stage='STARTING'
        self:note('V4 started / '..self.cfg.move..' / '..self.cfg.style)
        task.spawn(function() self:watchSafety(session) end)
        task.spawn(function() self:workLoop(session) end)
    end
end
