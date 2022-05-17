local KC = require('klib/container/container')
local Behavior = require 'ai/behavior/behavior'

local Follow = KC.class('ai.behavior.Follow', Behavior, function(self, agent, target)
    Behavior(self, agent)
    self.target = target
end)

function Follow:get_name()
    return "follow"
end

function Follow:update()
    if self.target and self.target.valid then
        self:get_agent():get_steer():arrival(self.target.position, {
            slowdown_distance = 10,
            stop_distance = 2
        })
    end
end

return Follow
