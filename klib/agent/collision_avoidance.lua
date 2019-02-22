local dlog = require('klib/utils/dlog')
local Vector = require('klib/math/vector')
local Area = require('stdlib/area/area')

local MAX_AVOID_FORCE = 50

local CollisionAvoidance = {}
function CollisionAvoidance:new(agent)
    return setmetatable({
        agent = agent,
        entity = agent.entity
    }, {__index = self})
end

function CollisionAvoidance:get_avoidance_force(weight)
    local weight = weight or MAX_AVOID_FORCE
    local ahead = self:_get_ahead_vector()
    local obstacle, collision_position = self:_find_most_threatening_obstacle(ahead)
    if obstacle ~= nil then
        local avoidance_force = Vector(collision_position.x - obstacle.position.x, collision_position.y - obstacle.position.y)
        avoidance_force = avoidance_force:normalized() * weight
        dlog('avoidance_force of agent('.. self.agent:id() ..')', avoidance_force)
        return avoidance_force
    else
        return Vector.zero
    end
end

function CollisionAvoidance:_get_ahead_vector()
    local running_speed = self.entity.prototype.running_speed
    local force = self.agent.steer:get_force()
    return force:normalized() * running_speed * 10 --- plan for next second
end

function CollisionAvoidance:_find_most_threatening_obstacle(ahead)
    local collision_position = self:_find_collision_position(ahead)
    if nil ~= collision_position then
        dlog('possible collision of agent(' .. self.agent:id() .. ') occur: ', collision_position)
        local entity = self.entity
        local collision_area = Area.offset(entity.bounding_box, collision_position)
        local collision_entities = entity.surface.find_entities(collision_area)
        if #collision_entities > 0 then
            dlog('try to avoid collision of agent('.. self.agent:id() ..')', {
                agent_position = self.entity.position,
                agent_collision_box = entity.bounding_box,
                collision_position = collision_position,
                agent_collision_area = collision_area,
                collision_entity = collision_entities[1].name,
                collision_entity_position = collision_entities[1].position,
            })
            return collision_entities[1], collision_position
        end
    end
end

function CollisionAvoidance:_find_collision_position(ahead)
    local entity = self.entity
    local surface = entity.surface
    local step = ahead:normalized()
    local length = ahead:len()
    local i = 0.2
    while i < length do
        local position = entity.position + step * i
        local can = surface.can_place_entity({
            name = entity.name,
            position = position,
            direction = entity.direction,
            force = entity.force
        })
        if not can then
            if not surface.find_entity(entity.name, position) then
                return position
            end
        end
        i = i + 0.2
    end
    return nil
end

return CollisionAvoidance
