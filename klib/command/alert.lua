local KC = require('klib/container/container')
local CommandHelper = require('klib/command/command_helper')

local Alert = KC.class('klib.agent.command.Standby', function(self, agent)
    self.agent = agent
end)

CommandHelper.define_name(Alert, "alert")

function Alert:execute()
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
    end
end

return Alert