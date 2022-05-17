local KC = require('klib/container/container')

local Behavior = KC.class('ai.behavior.Behavior', function(self, agent)
    self:set_agent(agent)
end)

Behavior:reference_objects("agent")

function Behavior:update()
end

return Behavior