local KC = require('klib/container/container')
local Position = require 'klib/gmo/position'

local Formation = require 'kai/formation/formation'

local Spiral = KC.class('kai.formation.Spiral', Formation, function(self, group)
    Formation(self, group)
end)

function Spiral:update()
    local group = self:get_group()
    local position = group:get_position()
    group:for_each_member(function(agent, i)
        local offset = Position.from_spiral_index(i)
        agent.formation_force = agent:get_steer():get_arrival_force({
            x = position.x + 2*offset.x,
            y = position.y + 2*offset.y
        },{
            slowdown_distance = 2,
        })
    end)
end

return Spiral