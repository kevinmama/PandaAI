local KC = require('klib/container/container')

local Standby = KC.define_class('klib.agent.command.Standby', {

}, function(self, agent)
    self.agent = agent
end)

function Standby:execute()
end

return Standby