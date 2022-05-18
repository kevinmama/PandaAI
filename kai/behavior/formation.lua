local KC = require('klib/container/container')
local Behavior = require 'kai/behavior/behavior'

local Formation = KC.class('kai.behavior.Formation', Behavior, function(self, agent)
    Behavior(self, agent)
end)

function Formation:get_name()
    return "formation"
end

function Formation:update()
    local agent = self:get_agent()
    local group = agent:get_group()
    if group then
        agent:get_steer():force(group:get_steer():get_force())
    end
end

return Formation
