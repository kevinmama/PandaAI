local KC = require 'klib/container/container'
local Agent = require 'kai/agent/agent'

local Unit = KC.class('kai.agent.Unit', Agent, function(self, entity, autonomous)
    self.entity = entity
    self.autonomous = (autonomous == nil) and true or autonomous
    Agent(self)
end)

function Unit:equals(agent)
    return KC.is_object(agent, Unit) and self:get_id() == agent:get_id() or self.entity == agent
end

function Unit:is_valid()
    return self.entity.valid
end

function Unit:is_unit()
    return true
end

function Unit:is_group()
    return false
end

function Unit:get_surface()
    return self.entity.surface
end

function Unit:get_position()
    return self.entity.position
end

function Unit:get_force()
    return self.entity.force
end

function Unit:get_bounding_box()
    return self.entity.bounding_box
end

function Unit:update_agent()
    if self.autonomous then
        local steer = self:get_steer()
        steer:reset()
        self:get_behavior_controller():update()
        --steer:avoid_collision()
        --steer:display()
        self:perform_walk()
    end
end

function Unit:perform_walk()
    local force = self:get_steer():get_force()
    --log("agent[".. self:get_id() .. "]: force: " .. force.x .. "," .. force.y)
    if force:len() > 1 then
        local direction = force:direction()
        --log("agent[" .. self:get_id() .. "]: direction: " .. direction)
        self.entity.walking_state = {
            walking = direction ~= nil,
            direction = direction or self.entity.walking_state.direction
        }
    else
        self.entity.walking_state = {
            walking = false
        }
    end
end

return Unit
