local KC = require('klib/container/container')
local Behaviors = require 'kai/behavior/behaviors'
local Command = require 'kai/command/command'

local Follow = KC.class('kai.command.Follow', Command, function(self, agent, target)
    Command(self, agent)
    self.target = target
end)

function Follow:execute()
    local agent = self:get_agent()
    agent:add_behavior(Behaviors.Follow, self.target)
end

return Follow
