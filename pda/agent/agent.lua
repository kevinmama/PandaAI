local LazyFunction = require 'klib/utils/lazy_function'
local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Steer = require 'pda/agent/Steer'
local Group = require 'pda/agent/group'
local Behavior = require 'pda/agent/behavior'
local Command = require 'pda/agent/command'

local Agent = KC.class('pda.agent.Agent', function(self, entity)
    self.entity = entity
    self.group = Group:new(self)
    self.steer = Steer:new(self)
    self.behavior = Behavior:new(self)
    self.command = Command:new(self)
end)

function Agent:on_ready()
    Event.execute_until(defines.events.on_tick, function()
        return not self.entity.valid
    end, function()
        self:destroy()
    end, function()
        self.steer:reset()
        self.behavior:update()
        self.steer:avoid_collision()
        self.steer:display()
        self:perform_walk()
    end)
end

function Agent:on_destroy()
    self.behavior:destroy()
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

LazyFunction.delegate_instance_method(Agent, "group", "join_group")
LazyFunction.delegate_instance_method(Agent, "group", "leave_group")
LazyFunction.delegate_instance_method(Agent, "behavior", "add", "add_behavior")
LazyFunction.delegate_instance_method(Agent, "behavior", "remove", "remove_behavior")
LazyFunction.delegate_instance_method(Agent, "behavior", "clear", "clear_behavior")
LazyFunction.delegate_instance_method(Agent, "command", "execute", "execute_command")

return Agent
