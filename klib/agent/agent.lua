local LazyFunction = require 'klib/utils/lazy_function'
local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Steer = require 'klib/agent/Steer'
local Group = require 'klib/agent/group'
local Command = require 'klib/agent/command'

local Agent = KC.class('klib.agent.Agent', function(self, entity)
    self.entity = entity
    self.group = Group:new(self)
    self.steer = Steer:new(self)
    self.command = Command:new(self)
end)

function Agent:on_ready()
    Event.execute_until(defines.events.on_tick, function()
        return not self.entity.valid
    end, function()
        self:destroy()
    end, function()
        self.steer:clear_force()
        self.command:execute_commands()
        self:perform_walk()
    end)
end


function Agent:on_destroy()
    self.command:destroy()
    self.steer:destroy()
    self.group:destroy()
end

function Agent:position()
    return self.entity.position
end

function Agent:perform_walk()
    local force = self.steer:get_force()
    --log("agent[".. self:id() .. "]: force: " .. force.x .. "," .. force.y)
    local direction = force:direction()
    --log("agent[" .. self:id() .. "]: direction: ", direction)
    self.entity.walking_state = {
        walking = direction ~= nil,
        direction = direction or self.entity.walking_state.direction
    }
end

LazyFunction.delegate_instance_method(Agent, "command", "add_command")
LazyFunction.delegate_instance_method(Agent, "group", "join_group")
LazyFunction.delegate_instance_method(Agent, "group", "leave_group")

return Agent