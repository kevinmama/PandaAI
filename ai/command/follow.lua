local KC = require('klib/container/container')
local Behaviors = require 'ai/behavior/behaviors'
local Command = require 'ai/command/command'

local Follow = KC.class('ai.command.Follow', Command, function(self, agent, target)
    Command(self, agent)
    self.target = target
end)

function Follow:execute()
    local agent = self:get_agent()
    agent:add_behavior(Behaviors.Follow, self.target)
end

return Follow
