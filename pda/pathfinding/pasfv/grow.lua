local log = (require '__stdlib__/stdlib/misc/logger')('pasfv', DEBUG)
local Table = require '__stdlib__/stdlib/utils/table'
local Region = require 'pda/pathfinding/pasfv/region'

local C = require 'pda/pathfinding/pasfv/config'

local Grow = {}
local STEP = 1

function Grow.new(algorithm)
    return setmetatable({
        algorithm = algorithm,
        world = algorithm.world
    }, {__index = Grow})
end

function Grow:grow()
    log("world bounding: " .. serpent.line(self.algorithm.bounding))
    local seed = self.algorithm.seedQueue()
    while seed ~= nil do
        self:grow_seed(seed)
        seed = self.algorithm.seedQueue()
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
    while direction ~= nil do
        self:grow_edge(region, direction, STEP)
        direction = region:next_grow_direction()
    end
    -- add region to world
    self.world:add({
        type = C.OBJECT_TYPES.REGION,
    }, region.x, region.y, region.w, region.h)
end

function Grow:is_seed_collide(seed)
    local bounding = self.algorithm.bounding
    if seed.x + seed.w > bounding.right_bottom.x
        or seed.x < bounding.left_top.x
        or seed.y + seed.h > bounding.right_bottom.y
        or seed.y < bounding.left_top.y then
        return true
    end

    local items, len = self.world:queryRect(seed.x, seed.y, seed.w, seed.h)
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
    log("    about to claim: " .. serpent.line(claimRegion))
    local items, len = self.world:queryRect(claimRegion.x, claimRegion.y, claimRegion.w, claimRegion.h)
    if len == 0 then
        region:expand(direction, claimRegion.step)
        if claimRegion.stop then
            region:stop_grow(direction)
        end
    else
        local point = self:find_step_from_nearest_obstruction(items, len, direction)
        region:expand_to(direction, point)
        region:stop_grow(direction)
        log("    expand to and stop grow: " .. serpent.line({
            direction = direction,
            point = point
        }))
    end
end

function Grow:find_step_from_nearest_obstruction(items, len, direction)
    local target_value
    for i = 1, len do
        local x,y,w,h = self.world:getRect(items[i])
        if direction == defines.direction.east then
            -- find min x
            if target_value == nil then
                target_value = x
            elseif x < target_value then
                target_value = x
            end
        elseif direction == defines.direction.west then
            -- find max x + w
            if target_value == nil then
                target_value = x + w
            elseif x + w > target_value then
                target_value = x + w
            end
        elseif direction == defines.direction.south then
            -- find min y
            if target_value == nil then
                target_value = y
            elseif y < target_value then
                target_value = y
            end
        else -- north
            -- find max y + h
            if target_value == nil then
                target_value = y + h
            elseif y + h > target_value then
                target_value = y + h
            end
        end
    end
    return target_value
end

return Grow
