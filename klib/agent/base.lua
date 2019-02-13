local KC = require 'klib/container/container'
local Vector = require 'klib/math/vector'
local KEvent = require 'klib/kevent'

local Agent = KC.define_class('KAgent', {
    ON_AGENT_DESTROY = "on_agent_destroy"
}, function(self, control)
    self.control = control
    self.vector = Vector.zero
    self._command = nil
    self.groups = {}
end)

function Agent:on_ready()
    KEvent.register_removable(defines.events.on_tick, {
        condition = function()
            return not self.control.valid
        end,
        on_remove = function()
            self:destroy()
        end,
        handler = function(event)
            self.vector = Vector.zero
            if self._command then
                self._command:execute()
            end
            self:perform_walk()
        end
    })
end

function Agent:on_destroy()
    if self._command then
        self._command:destroy()
    end
    for _, group in self.groups do
        if group[Agent.ON_AGENT_DESTROY] then
            group[Agent.ON_AGENT_DESTROY](group, self)
        end
    end
end

function Agent:position()
    return self.control.position
end

function Agent:perform_walk()
    --log("agent[".. self[KContainer.OBJECT_ID] .. "]: vector: " .. self.vector.x .. "," .. self.vector.y)
    local dir = self.vector:direction()
    --log("agent[" .. self[KContainer.OBJECT_ID] .. "]: direction: " .. dir)
    self.control.walking_state = {
        walking = dir ~= nil,
        direction = dir or self.control.walking_state.direction
    }
end


--- example:
--- 1. pass a command class and construct argument except agent
---   agent.command(Follow, me)
--- 2. pass a command instance
---   agent.command(follow_me_command)
function Agent:command(command, ...)
    -- if pass a command class and arguments, create its instance first
    if not command[KC.OBJECT_ID] then
        local Command = command
        command = Command:new(self, ...)
    end

    if command ~= self._command then
        if self._command then
            self._command:destroy()
        end
        self._command = command
    end
end

return Agent