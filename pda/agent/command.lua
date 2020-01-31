local KC = require 'klib/container/container'

local Command = KC.class('pda.agent.Command', function(self, agent)
    self.agent = agent
    self.command = nil
end)

function Command:on_destroy()
    self:clear()
end

function Command:clear()
    if self.command then
        self.command:destroy()
    end
end

--- example:
--- 1. pass a command class and construct argument except agent
---   agent.execute_command(Move, position)
--- 2. pass a behavior instance
---   agent.execute_command(move_to_position)
function Command:execute(command, ...)
    -- if pass a command class and arguments, create its instance first
    if KC.is_class(command) then
        local Command = command
        command = Command:new(self.agent, ...)
    elseif KC.is_object(command) then
    else
        error('command must be a subclass of Command or its instance')
    end

    self:clear()
    self.command = command
    command:execute()
end

return Command
