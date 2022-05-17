local KC = require('klib/container/container')
local Behavior = require 'kai/behavior/behavior'

local Alert = KC.class('kai.behavior.Alert', Behavior, function(self, agent)
    Behavior(self, agent)
end)

function Alert:get_name()
    return "alert"
end

function Alert:update()
    local entity = self:get_agent().entity
    local enemy = entity.surface.find_nearest_enemy({
        position = entity.position,
        max_distance = 36,
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