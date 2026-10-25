return function(C)
    function C:chopTree(tree)
        if not self:treeValid(tree) then return false end
        if not self.cfg.farm then return false end
        self.workTree = tree
        self.stage = 'TREE: walking'
        local part = self:treePart(tree)
        if not part then return false end
        if not self:goTo(part.Position, self.cfg.treeRange) then return false end
        self.stage = 'TREE: chopping'
        local failed, swings = 0, 0
        while self.running and self.cfg.farm and not self:isPaused() and not self:urgentCombat()
            and not self:mobInterrupt()
            and self:treeValid(tree) and swings < 65 do
            if self.isDodging and self:isDodging() then return false end
            part=self:treePart(tree)
            if not part then break end
            local pos=self:position()
            if not pos then break end
            if (part.Position-pos).Magnitude>5.6 then
                if not self:goTo(part.Position,self.cfg.treeRange) then break end
            end
            local previous=tree:GetAttribute('HP')
            local ok,reason=self:useItem(part.Position+Vector3.new(0,1.1,0),'Tree')
            if not ok then
                if self.isDodging and self:isDodging() then return false end
                self:note(reason or 'No attack input'); failed=failed+1
            end
            if ok then
                local deadline=os.clock()+1.15
                local changed=false
                while self.running and self.cfg.farm and not self:isPaused() and not self:urgentCombat()
                    and not self:mobInterrupt()
                    and os.clock()<deadline do
                    local hp=tree:GetAttribute('HP')
                    if tree:GetAttribute('Felled')==true or (type(hp)=='number' and hp<previous-.01) then
                        changed=true; break
                    end
                    task.wait(.07)
                end
                local profile=self:activeProfile()
                if profile=='Axe' and self.learnAxeHit then
                    self:learnAxeHit(changed)
                end
                if changed then failed=0 else failed=failed+1 end
            end
            swings=swings+1
            if failed>=3 then
                self.blockedTrees[tree]=os.clock()+18
                self:note('Tree attacks not confirmed; cooling down target')
                break
            end
        end
        if tree:GetAttribute('Felled')==true or (tree:GetAttribute('HP') or 1)<=0 then
            self.workTree=nil
            self.stats.trees=self.stats.trees+1
            self.stage='WOOD: falling in background'
            task.wait(.045)
            return true
        end
        return false
    end
end
