local KC = require('klib/container/container')
local Direction = require 'klib/gmo/direction'

local Formation = require 'kai/formation/formation'

local SingleRow = KC.class('kai.formation.SingleRow', Formation, function(self, group, props)
    Formation(self, group)
    props = props or {}
    self.scale = props.scale or 2
end)

function SingleRow:update()
    local group = self:get_group()
    local position = group:get_position()
    local vector = Direction.to_vector(group:get_direction())
    group:for_each_member(function(agent, i)
        local scale =  (i%2 == 1 and i/2 or -i/2) * self.scale
        agent.formation_force = agent:get_steer():get_arrival_force({
            x = position.x + vector.y * scale,
            y = position.y - vector.x * scale
        },{
            slowdown_distance = 2,
        })
    end)
end

return SingleRow