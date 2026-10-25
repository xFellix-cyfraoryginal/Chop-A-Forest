-- Event logic intentionally uses biome attributes, not names of monsters or decorations.
return function(C)
    function C:eventInfo()
        local time = game:GetService("Lighting").ClockTime
        local visible = nil
        local pg = self.player:FindFirstChild("PlayerGui")
        local hud = pg and pg:FindFirstChild("AreaHud")
        if hud then
            local pr = hud:FindFirstChild("Progress")
            local row = pr and pr:FindFirstChild("Row")
            local area = row and row:FindFirstChild("AreaName")
            if area and area:IsA("TextLabel") then visible = area.Text end
        end
        local minions, bosses = 0, 0
        for mob in pairs(self.enemies or {}) do
            if self:enemyOK(mob) then
                if mob:GetAttribute("Monster") == "Guardian" then bosses = bosses + 1
                else minions = minions + 1 end
            end
        end
        return {clock = time, areaName = visible, minions = minions, bosses = bosses,
            halloween = visible and visible:find("Graveyard") ~= nil or false}
    end
end
