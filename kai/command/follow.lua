local KC = require('klib/container/container')
local Behaviors = require 'kai/behavior/behaviors'
local Command = require 'kai/command/command'
local Agent = require 'kai/agent/agent'
local Unit = require 'kai/agent/unit'

local Follow = KC.class('kai.command.Follow', Command, function(self, agent, target)
    Command(self, agent)
    if not KC.is_object(target, Agent) then
        target = Unit:new(target, false)
    end
    self:set_target(target)
end)

Follow:reference_objects("target")

function Follow:execute()
    self:get_agent():add_behavior(Behaviors.Follow, self:get_target())
end

return Follow
