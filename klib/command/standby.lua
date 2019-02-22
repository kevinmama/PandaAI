local KC = require('klib/container/container')
local CommandHelper = require('klib/command/command_helper')

local Standby = KC.class('klib.agent.command.Standby', function(self, agent)
    self.agent = agent
end)

CommandHelper.define_name(Standby, 'follow')

function Standby:execute()
    self.agent.command.clear_commands()
end

return Standby