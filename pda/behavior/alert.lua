local KC = require('klib/container/container')
local Helper = require('pda/behavior/helper')

local Alert = KC.class('pda.behavior.Alert', function(self, agent)
    self.agent = agent
end)

Helper.define_name(Alert, "alert")

function Alert:update()
    local entity = self.agent.entity
    local enemy = entity.surface.find_nearest_enemy({
        position = entity.position,
        max_distance = 15,
        entity.force
    })
    if (enemy ~= nil) then
        entity.selected_gun_index = 1 -- 以后改成寻找可用的武器
        entity.shooting_state = {
            state = defines.shooting.shooting_enemies,
            position = enemy.position
        }
    else
        entity.shooting_state = {
            state = defines.shooting.not_shooting
        }
    end
end

return Alert