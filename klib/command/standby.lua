local KContainer = require('klib/kcontainer')

local Standby = KContainer.define_class('klib.agent.command.Standby', {

}, function(self, agent)
    self.agent = agent
end)

function Standby:execute()
end

return Standby