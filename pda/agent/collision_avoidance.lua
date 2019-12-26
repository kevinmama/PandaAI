local dlog = require('klib/utils/dlog')
local Vector = require('klib/math/vector')
local Area = require('__stdlib__/stdlib/area/area')

local AVOID_SCALE = 0.5
local AHEAD_TICKS = 10
local AHEAD_STEP = 2

local CollisionAvoidance = {}
function CollisionAvoidance:new(agent, opts)
    local ins = {}
    ins.avoid_scale = opts.avoid_scale or AVOID_SCALE
    ins.ahead_ticks = opts.ahead_ticks or AHEAD_TICKS
    ins.ahead_step = opts.ahead_step or AHEAD_STEP
    ins.agent = agent
    ins.entity = agent.entity

    ins.speed = nil
    ins.ahead = nil
    ins.collision_object = nil
    ins.collision_position = nil

    return setmetatable(ins, {__index = self})
end

function CollisionAvoidance:get_avoidance_force(weight)
    -- 获得的力和速度正相关
    self:_init_speed()
    self:_init_ahead()
    self:_find_most_threatening_obstacle()
    return self:_compute_avoidance_force()
end

function CollisionAvoidance:_compute_avoidance_force()
    -- 应该施加一个垂直于前进方向的力
    if self.collision_object ~= nil then
        --local avoidance_force = self.collision_position - self.collision_object.position
        local avoidance_force = self:_orthogonal_collision_vector()
        avoidance_force = avoidance_force:normalized() * self.avoid_scale
        --dlog('avoidance_force of agent('.. self.agent:id() ..')', avoidance_force)
        return avoidance_force
    else
        return Vector.zero
    end
end

function CollisionAvoidance:_init_speed()
    self.speed = self.entity.prototype.running_speed
end

function CollisionAvoidance:_init_ahead()
    local force = self.agent.steer:get_force()
    self.ahead = force:normalized() * self.speed
end

function CollisionAvoidance:_find_most_threatening_obstacle()
    local entity = self.entity
    --dlog("agent (" .. self.agent:id() .. ") search ahead for collision: ", self.ahead)
    local i = self.ahead_step
    while i <= self.ahead_ticks do
        local offset = self.ahead * i
        local possible_collision_area = Area.offset(entity.bounding_box, offset)
        local possible_collision_object = self:_find_possible_collision(possible_collision_area)
        if nil ~= possible_collision_object then
            --dlog("found possible collision of agent(" .. self.agent:id() .. ')', {
            --    agent_position = self.entity.position,
            --    collision_area = possible_collision_area,
            --    collision_object_name = possible_collision_object.name,
            --    collision_object_position = possible_collision_object.position,
            --})
            self.collision_object = possible_collision_object
            self.collision_position = entity.position + offset
        end
        i = i + self.ahead_step
    end
end

function CollisionAvoidance:_find_possible_collision(area)
    local entity = self:_find_possible_collision_entity(area)
    if nil ~= entity then
        return entity
    end

    local tile = self:_find_possible_collision_tile(area)
    if nil ~= tile then
        return tile
    end
end

function CollisionAvoidance:_find_possible_collision_entity(area)
    local entities = self.entity.surface.find_entities_filtered({
        area = area,
        collision_mask = 'player-layer'
    })
    for _, entity in pairs(entities) do
        if entity ~= self.entity then
            --dlog("possible collision entity for agent(" .. self.agent:id() .. "): ", {
            --    area = area,
            --    name = entity.name,
            --    position = entity.position,
            --    bounding_box = entity.bounding_box
            --})
            return entity
        end
    end
end

function CollisionAvoidance:_find_possible_collision_tile(area)
    local tiles = self.entity.surface.find_tiles_filtered({
        area = area,
        collision_mask = "player-layer"
    })
    for _, tile in pairs(tiles) do
        --dlog("possible collision tile for agent(" .. self.agent:id() .. "): ", {
        --    area = area,
        --    name = tile.name,
        --    position = tile.position
        --})
        return tile
    end
end

function CollisionAvoidance:_orthogonal_collision_vector()
    -- a.b = 0
    -- ==> x1 + k1.ax = x2 + k2.bx
    --     y1 + k1.ay = y2 + k2.by
    -- ==> k1 = by(x2-x1) - bx(y2-y1) / (by.ax - bx.ay)
    --     k2 = ay(x2-x1) - ax(y2-y1) / (by.ax - bx.ay)
    -- ==> v = (k2.bx, k2.by)
    --     vx = bx.ay(x2-x1) - bx.ax(y2-y1) / (by.ax - bx.ay)
    --     vy = by.ay(x2-x1) - by.ax(y2-y1) / (by.ax - bx.ay)

    if self.collision_object ~= nil then
        local entity_position = self.entity.position
        local obstacle_position = self.collision_object.position
        local ahead = self.ahead
        local orthogonal = ahead:orthogonal()

        local x1,y1 = entity_position.x, entity_position.y
        local x2,y2 = obstacle_position.x, obstacle_position.y
        local ax,ay = ahead.x, ahead.y
        local bx,by = orthogonal.x, orthogonal.y

        local denominator = by*ax - bx*ay
        if denominator == 0 then
            -- ahead 直接通过碰撞物休的质心，直接使用 ahead 的垂线
            return orthogonal
        else
            local cx = ( bx*ay*(x2-x1) - bx*ax*(y2-y1) ) / denominator
            local cy = ( by*ay*(x2-x1) - by*ax*(y2-y1) ) / denominator
            return Vector(cx,cy)
        end
    end
end

return CollisionAvoidance
