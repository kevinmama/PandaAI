local KC = require('klib/container/container')
local Position = require 'klib/gmo/position'
local Behavior = require 'kai/behavior/behavior'

local Formation = KC.class('kai.behavior.Formation', Behavior, function(self, agent)
    Behavior(self, agent)
end)

function Formation:get_name()
    return "formation"
end

function Formation:update()
    local agent = self:get_agent()
    if agent:is_group() then
        local group = agent
        local members = group:get_members()
        for i, agent in pairs(members) do
            local formation = group:get_formation()
            if formation then
                local g_pos = group:get_position()
                local offset = formation.get_offset(i)
                local x,y = g_pos.x + offset.x, g_pos.y + offset.y
                agent.formation_position = {x=x,y=y}
            end
        end
    end
    if agent.formation_position then
        local steer = agent:get_steer()
        local group = agent:get_group()
        if group then
            steer:force(group:get_steer():get_force())
            steer:arrival(agent.formation_position, {
                slowdown_distance = 2
            })
        end
    end
end

return Formation
