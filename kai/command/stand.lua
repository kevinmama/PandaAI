local KC = require('klib/container/container')
local Command = require 'kai/command/command'
local Group = require 'kai/agent/group'

local Stand = KC.class('kai.command.Stand', Command, function(self, agent, stand)
    Command(self, agent)
    self.stand = stand
end)

function Stand:execute()
    local agent = self:get_agent()
    agent.stand = self.stand
    if KC.is_object(agent, Group) then
        agent:for_each_member_recursive(function(member)
            member.stand = self.stand
        end)
    end
end

return Stand
