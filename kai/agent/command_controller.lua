local KC = require 'klib/container/container'

local CommandController = KC.class('kai.agent.CommandController', function(self, agent)
    self:set_agent(agent)
end)

CommandController:reference_objects("agent", "command")

function CommandController:on_destroy()
    self:destroy_command()
end

function CommandController:destroy_command()
    local command = self:get_command()
    if command then
        command:destroy()
    end
end

--- example:
--- pass a command class and construct argument except agent
---   agent.execute_command(Move, position)
function CommandController:execute(command, ...)
    self:destroy_command()
    -- if pass a command class and arguments, create its instance first
    if KC.is_class(command) then
        local Command = command
        command = Command:new(self:get_agent(), ...)
    elseif KC.is_object(command) then
    else
        error('command must be a subclass of Command or its instance')
    end
    self:set_command(command)
    command:execute()
end

return CommandController
