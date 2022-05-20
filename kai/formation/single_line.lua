local KC = require('klib/container/container')
local Direction = require 'klib/gmo/direction'

local Formation = require 'kai/formation/formation'

local SingleLine = KC.class('kai.formation.SingleLine', Formation, function(self, group, props)
    Formation(self, group)
    props = props or {}
    self.scale = props.scale or 2
end)

function SingleLine:update()
    local group = self:get_group()
    local position = group:get_position()
    local vector = Direction.to_vector(group:get_direction())
    group:for_each_member(function(agent, i)
        agent.formation_force = agent:get_steer():get_arrival_force({
            x = position.x - vector.x * i * self.scale,
            y = position.y - vector.y * i * self.scale
        },{
            slowdown_distance = 2,
        })
    end)
end

return SingleLine