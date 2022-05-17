local KC = require('klib/container/container')

local Command = KC.class('kai.command.command', function(self, agent)
    self:set_agent(agent)
end)

Command:reference_objects("agent")

function Command:execute()

end

return Command