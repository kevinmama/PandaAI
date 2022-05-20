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

function Unit:get_direction()
    if self.entity.object_name == 'LuaPlayer' then
        return self.entity.character and self.entity.character.direction or defines.direction.north
    else
        return self.entity.direction
    end
end

function Unit:get_force()
    return self.entity.force
end

function Unit:get_bounding_box()
    return self.entity.bounding_box
end

function Unit:update_agent()
    if self.autonomous and not self.stand then
        local steer = self:get_steer()
        steer:reset()
        self:update_formation()
        self:get_behavior_controller():update()
        steer:avoid_collision()
        if _DISPLAY_STEER__ then
            steer:display()
        else
            steer:destroy_display()
        end
        self:perform_walk()
    elseif self.stand then
        self.entity.walking_state = {walking = false}
    end
end

function Unit:update_formation()
    local group = self:get_group()
    if group then
        local steer = self:get_steer()
        steer:force(group:get_steer():get_force())
        if self.formation_force then
           steer:force(self.formation_force)
        end
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
