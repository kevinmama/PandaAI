local KC = require('klib/container/container')
local Symbols = require('klib/agent/symbols')
local LazyFunction = require 'klib/utils/lazy_function'

local Group = KC.class('klib.agent.Group', function(self, agent)
    self.agent = agent
    self.groups = {}
end)

function Group:join_group(group)
    self.groups[group:id()] = group
end

function Group:leave_group(group)
    self.groups[group:id()] = nil
end

function Group:on_destroy()
    table.each(self.groups, function(group)
        --- may raise custom event: agent destroy
        LazyFunction.call(group, Symbols.ON_AGENT_DESTROY, self.agent)
    end)
end

return Group

