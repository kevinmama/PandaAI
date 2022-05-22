local KC = require('klib/container/container')

local Formation = require 'kai/formation/formation'

local Snake = KC.class('kai.formation.Snake ', Formation, function(self, group, props)
    Formation(self, group)
    props = props or {}
    self.scale = props.scale or 1
end)

function Snake:update()
    local group = self:get_group()
    local prev_position = group:get_position()
    group:for_each_member(function(agent)
        agent.formation_force = agent:get_steer():get_arrival_force(prev_position, {
            slowdown_distance = 8 * self.scale,
            stop_distance = 4 * self.scale
        })
        prev_position = agent:get_position()
    end)
end

return Snake