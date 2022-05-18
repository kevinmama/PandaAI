local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local LazyFunction = require 'klib/utils/lazy_function'

local Steer = require 'kai/agent/steer'
local BehaviorController = require 'kai/agent/behavior_controller'
local CommandController = require 'kai/agent/command_controller'

local Agent = KC.class('kai.agent.Agent', function(self)
    self.updated_at = game.tick
    self.group_id = nil
    self:set_steer(Steer:new(self))
    self:set_behavior_controller(BehaviorController:new(self))
    self:set_command_controller(CommandController:new(self))
end)

Agent:reference_objects('group', 'steer', 'behavior_controller', 'command_controller')

function Agent:equals(agent)
    return agent and self:get_id() == agent:get_id()
end

local SUBCLASS_SHOULD_IMPLEMENT_ERROR = "Subclass should implement this method"

function Agent:is_valid()
    error(SUBCLASS_SHOULD_IMPLEMENT_ERROR)
end

function Agent:is_unit()
    error(SUBCLASS_SHOULD_IMPLEMENT_ERROR)
end

function Agent:is_group()
    return not self:is_unit()
end

function Agent:get_surface()
    error(SUBCLASS_SHOULD_IMPLEMENT_ERROR)
end

function Agent:get_position()
    error(SUBCLASS_SHOULD_IMPLEMENT_ERROR)
end

function Agent:get_force()
    error(SUBCLASS_SHOULD_IMPLEMENT_ERROR)
end

function Agent:get_bounding_box()
    error(SUBCLASS_SHOULD_IMPLEMENT_ERROR)
end

function Agent:update_agent()
    error(SUBCLASS_SHOULD_IMPLEMENT_ERROR)
end

function Agent:on_destroy()
    self:get_command_controller():destroy()
    self:get_behavior_controller():destroy()
    self:get_steer():destroy()
    local group = self:get_group()
    if group then
        group:remove_member(self)
    end
end

--- 优先更新其群组，然后自身
function Agent:update()
    if self:is_valid() then
        if self.updated_at < game.tick then
            local group = self:get_group()
            if group then group:update() end
            self:update_agent()
            self.updated_at = game.tick
        end
    else
        self:destroy()
    end
end

Event.register(defines.events.on_tick, function()
    KC.for_each_object(Agent, function(agent)
        if not agent:is_valid()then
            agent:destroy()
        end
    end)
    KC.for_each_object(Agent, function(agent)
        agent:update()
    end)
end)

LazyFunction.delegate_instance_method(Agent, "behavior_controller", "add", "add_behavior")
LazyFunction.delegate_instance_method(Agent, "behavior_controller", "remove", "remove_behavior")
LazyFunction.delegate_instance_method(Agent, "behavior_controller", "clear", "clear_behavior")
LazyFunction.delegate_instance_method(Agent, "command_controller", "execute", "set_command")

return Agent