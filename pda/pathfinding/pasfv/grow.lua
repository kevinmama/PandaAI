local log = (require '__stdlib__/stdlib/misc/logger')('pasfv', DEBUG)
local Table = require '__stdlib__/stdlib/utils/table'
local Queue = require '__stdlib__/stdlib/misc/queue'

local C = require 'pda/pathfinding/pasfv/config'
local Region = require 'pda/pathfinding/pasfv/region'

local Grow = {}
local STEP = 1

function Grow.new(algorithm)
    return setmetatable({
        algorithm = algorithm,
        world = algorithm.world,
        low_priority_queue = Queue()
    }, {__index = Grow})
end

function Grow:grow()
    log("world bounding: " .. serpent.line(self.algorithm.bounding))
    local seed = self.algorithm.seed_queue()
    while seed ~= nil do
        self:grow_seed(seed)
        seed = self.algorithm.seed_queue()
    end

    local region = self.low_priority_queue()
    while region ~= nil do
        self:grow_low_priority_region(region)
        region = self.low_priority_queue()
    end
end

function Grow:grow_seed(seed)
    -- 1. skip collide region
    if self:is_seed_collide(seed) then
        log('skip seed: ' .. serpent.line(seed))
        return
    else
        log('growing seed: ' .. serpent.line(seed))
    end

    local region = Region.new(seed)
    local direction = region:next_grow_direction()
    while region.highPriority do
        self:grow_edge(region, direction, STEP)
        direction = region:next_grow_direction()
    end
    self.low_priority_queue(region)
    -- add region to world
    self.world:add(region, region.x, region.y, region.w, region.h)
    table.insert(self.algorithm.regions, region)
end

function Grow:grow_low_priority_region(region)
    log('growing low priority region: ' .. serpent.line({
        region = {region.x, region.y, region.w, region.h},
        directions = region.grow_directions
    }))
    local direction = region:next_grow_direction()
    while direction do
        self:grow_edge(region, direction, STEP)
        direction = region:next_grow_direction()
    end
    self.world:update(region, region.x, region.y, region.w, region.h)
end

function Grow:is_seed_collide(seed)
    local bounding = self.algorithm.bounding
    if seed.x + seed.w > bounding.right_bottom.x
        or seed.x < bounding.left_top.x
        or seed.y + seed.h > bounding.right_bottom.y
        or seed.y < bounding.left_top.y then
        return true
    end

    local items, len = self.world:queryRect(seed.x + C.EPS, seed.y + C.EPS, seed.w - 2*C.EPS, seed.h - 2*C.EPS)
    return len ~= 0
end

function Grow:grow_edge(region, direction, step)
    log('  growing edge: ' .. serpent.line({
        region = {region.x, region.y, region.w, region.h},
        direction = direction,
        step = step
    }))
    local claimRegion = region:generate_region_to_claim(direction, step, self.algorithm.bounding)
    --claimRegion = self:cut_region_by_world_bounding(claimRegion)
    if claimRegion.step < C.EPS then
        log("    ignore claim: " .. serpent.line(claimRegion))
        region:stop_grow(direction)
    else
        log("    about to claim: " .. serpent.line(claimRegion))
        local items, len = self.world:queryRect(claimRegion.x + C.EPS, claimRegion.y + C.EPS, claimRegion.w - 2*C.EPS, claimRegion.h - 2*C.EPS)
        if len == 0 then
            region:expand(direction, claimRegion.step)
            if claimRegion.stop then
                region:stop_grow(direction)
            end
        else
            local target, point = self:find_step_from_nearest_obstruction(items, len, direction)
            region:expand_to(direction, point)
            if target.type == C.OBJECT_TYPES.REGION then
                region:add_neighbour(target, direction)
            end
            region:stop_grow(direction)
            log("    expand to and stop grow: " .. serpent.line({
                direction = direction,
                point = point
            }))
        end
    end
end

function Grow:find_step_from_nearest_obstruction(items, len, direction)
    local target, target_value
    for i = 1, len do
        local item = items[i]
        --log("    block by: " .. serpent.line(item))
        local x,y,w,h = self.world:getRect(item)
        if direction == defines.direction.east then
            -- find min x
            if target_value == nil then
                target_value = x
                target = item
            elseif x < target_value then
                target_value = x
                target = item
            end
        elseif direction == defines.direction.west then
            -- find max x + w
            if target_value == nil then
                target_value = x + w
                target = item
            elseif x + w > target_value then
                target_value = x + w
                target = item
            end
        elseif direction == defines.direction.south then
            -- find min y
            if target_value == nil then
                target_value = y
                target = item
            elseif y < target_value then
                target_value = y
                target = item
            end
        else -- north
            -- find max y + h
            if target_value == nil then
                target_value = y + h
                target = item
            elseif y + h > target_value then
                target_value = y + h
                target = item
            end
        end
    end
    return target, target_value
end

return Grow
