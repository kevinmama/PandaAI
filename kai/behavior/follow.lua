local KC = require('klib/container/container')
local Behavior = require 'kai/behavior/behavior'
local Agent = require 'kai/agent/agent'
local Unit = require 'kai/agent/unit'

local Follow = KC.class('kai.behavior.Follow', Behavior, function(self, agent, target, opts)
    Behavior(self, agent)
    if not KC.is_object(target, Agent) then
        target = Unit:new(target, false)
    end
    self:set_target(target)
    opts = opts or {}
    self.slowdown_distance = 10 or opts.slowdown_distance
    self.stop_distance = 2 or opts.slowdown_distance
end)

Follow:reference_objects("target")

function Follow:get_name()
    return "follow"
end

function Follow:update()
    local target = self:get_target()
    if target:is_valid() then
        self:get_agent():get_steer():arrival(target:get_position(), {
            slowdown_distance = 10,
            stop_distance = 2
        })
    end
end

return Follow
