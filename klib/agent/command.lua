local KC = require('klib/container/container')

local Command = KC.class('klib.agent.Command', function(self, agent)
    self.agent = agent
    self.commands = {}
end)

function Command:on_destroy()
    self:clear_commands()
end

function Command:execute_commands()
    for _, command in pairs(self.commands) do
        command:execute()
    end
end

function Command:clear_commands()
    for _, command in pairs(self.commands) do
        command:destroy()
    end
    self.commands = {}
end

--- example:
--- 1. pass a command class and construct argument except agent
---   agent.command(Follow, me)
--- 2. pass a command instance
---   agent.command(follow_me_command)
function Command:add_command(command, ...)
    -- if pass a command class and arguments, create its instance first
    if KC.is_class(command) then
        local Command = command
        command = Command:new(self.agent, ...)
    elseif KC.is_object(command) then
    else
        error('command must be a subclass of Command or its instance')
    end

    local c = self.commands[command:get_name()]
    if c ~= command then
        if (c ~= nil) then
            c:destroy()
        end
        self.commands[command:get_name()] = command
    end
end

return Command
