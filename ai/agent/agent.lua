local LazyFunction = require 'klib/utils/lazy_function'
local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Steer = require 'ai/agent/Steer'
local BehaviorController = require 'ai/agent/behavior_controller'
local CommandController = require 'ai/agent/command_controller'

local Agent = KC.class('ai.agent.Agent', function(self, entity)
    self.entity = entity
    self:set_steer(Steer:new(self))
    self:set_behavior_controller(BehaviorController:new(self))
    self:set_command_controller(CommandController:new(self))
end)

Agent:reference_objects("steer", "behavior_controller", "command_controller")

function Agent:is_valid()
    return self.entity.valid
end

function Agent:update()
    local steer = self:get_steer()
    steer:reset()
    self:get_behavior_controller():update()
    steer:avoid_collision()
    steer:display()
    self:perform_walk()
end

Event.register(defines.events.on_tick, function()
    KC.for_each_object(Agent, function(agent)
        if agent:is_valid() then
            agent:update()
        else
            agent:destroy()
        end
    end)
end)

function Agent:on_destroy()
    self:get_command_controller():destroy()
    self:get_behavior_controller():destroy()
    self:get_steer():destroy()
end

function Agent:get_position()
    return self.entity.position
end

function Agent:perform_walk()
    local force = self:get_steer():get_force()
    --log("agent[".. self:id() .. "]: force: " .. force.x .. "," .. force.y)
    local direction = force:direction()
    --log("agent[" .. self:id() .. "]: direction: ", direction)
    self.entity.walking_state = {
        walking = direction ~= nil,
        direction = direction or self.entity.walking_state.direction
    }
end

LazyFunction.delegate_instance_method(Agent, "behavior_controller", "add", "add_behavior")
LazyFunction.delegate_instance_method(Agent, "behavior_controller", "remove", "remove_behavior")
LazyFunction.delegate_instance_method(Agent, "behavior_controller", "clear", "clear_behavior")
LazyFunction.delegate_instance_method(Agent, "command_controller", "execute", "set_command")

return Agent
