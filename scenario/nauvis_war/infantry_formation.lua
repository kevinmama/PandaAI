local KC = require('klib/container/container')
local Direction = require 'klib/gmo/direction'

local Formation = require 'kai/formation/formation'

local InfantryFormation = KC.class('scenario.nauvis_war.InfantryFormation', Formation, function(self, group)
    Formation(self, group)
end)

function InfantryFormation:update()
    local group = self:get_group()
    local position = group:get_position()
    local vector = Direction.to_vector(group:get_direction())
    group:for_each_member(function(agent, i)
        agent.formation_force = agent:get_steer():get_arrival_force({
            x = position.x - vector.x * (i - 5) * 3,
            y = position.y - vector.y * (i - 5) * 3
        }, {
            slowdown_distance = 10,
            stop_distance = 1
        })
    end)
end

return InfantryFormation