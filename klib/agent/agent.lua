local KContainer = require 'klib/kcontainer'
local Vector = require 'klib/math/kvector'
local KEvent = require 'klib/kevent'

local KAgent = KContainer.define_class('KAgent', {
    ON_AGENT_DESTROY = "on_agent_destroy"
}, function(self, control)
    self.control = control
    self.vector = Vector.zero
    self._command = nil
    self.groups = {}
end)

function KAgent:on_ready()
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

function KAgent:on_destroy()
    if self._command then
        self._command:destroy()
    end
    for _, group in self.groups do
        if group[KAgent.ON_AGENT_DESTROY] then
            group[KAgent.ON_AGENT_DESTROY](group, self)
        end
    end
end

function KAgent:position()
    return self.control.position
end

function KAgent:perform_walk()
    --log("agent[".. self[KContainer.OBJECT_ID] .. "]: vector: " .. self.vector.x .. "," .. self.vector.y)
    local dir = self.vector:direction()
    --log("agent[" .. self[KContainer.OBJECT_ID] .. "]: direction: " .. dir)
    self.control.walking_state = {
        walking = dir ~= nil,
        direction = dir
    }
end


--- example:
--- 1. pass a command class and construct argument except agent
---   agent.command(Follow, me)
--- 2. pass a command instance
---   agent.command(follow_me_command)
function KAgent:command(command, ...)
    -- if pass a command class and arguments, create its instance first
    if not command[KContainer.OBJECT_ID] then
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

return KAgent