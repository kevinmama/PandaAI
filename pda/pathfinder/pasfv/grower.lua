local log = (require '__stdlib__/stdlib/misc/logger')('pathfinder_grower', DEBUG)
local Direction = require '__stdlib__/stdlib/area/direction'
local KC = require 'klib/container/container'
local PriorityQueue = require 'klib/ds/priority_queue'
local Queue = require 'klib/ds/queue'
local Region = require 'pda/pathfinder/region'
local C = require 'pda/pathfinder/config'

local Grower = KC.class('pda.pathfinder.pasfv.Grower', function(self, mesh)
    self.mesh = mesh
    self.world = mesh.world
    self.seeds = PriorityQueue:new()
    self.low_priority_regions = Queue:new({
        auto_destroy_elements = true
    })
    self.low_priority_seeds = Queue:new({
        auto_destroy_elements = true
    })
end)

function Grower:on_destroy()
    self.seeds:destroy()
    self.low_priority_regions:destroy()
    self.step_in_tick = 0
end

function Grower:add_seeds(seeds)
    for _, seed in pairs(seeds) do
        self:add_seed(seed)
    end
end

function Grower:add_seed(seed)
    local cx, cy = seed.x + seed.w/2, seed.y + seed.h/2
    local priority = math.abs(cx) + math.abs(cy)
    self.seeds:push(priority, seed)
end

-- 处理的优先级:
--  初始块, 位置 映射到 0~1 之间，dist(chunk) / 1e5
--  生在块，300 - T，相当于给了5秒提前
--  种子    240 - T
--  次级区域  180 - T
--  次级种子  120 - T

function Grower:grow()
    self.step_in_tick = 1
    local updated_regions = {}

    while self.step_in_tick <= C.STEP_PER_TICK do
        local seed = self.seeds()
        if seed then
            log("growing new seed: " .. serpent.line(seed))
            local region = self:grow_seed(seed)
            table.insert(updated_regions, region)
        else
            break
        end
    end

    while self.step_in_tick <= C.STEP_PER_TICK do
        local region = self.low_priority_regions:pop()
        if region then
            log('growing low priority region: ' .. serpent.line({
                region = {region.x, region.y, region.w, region.h},
                directions = region.grow_directions
            }))
            self:grow_low_priority_region(region)
            table.insert(updated_regions, region)
        else
            break
        end
    end

    while self.step_in_tick <= C.STEP_PER_TICK do
        local seed = self.low_priority_seeds()
        if seed then
            log("growing low priority seed: " .. serpent.line(seed))
            local region = self:grow_seed(seed)
            table.insert(updated_regions, region)
        else
            break
        end
    end

    return updated_regions
end

function Grower:grow_seed(seed)
    -- 1. skip collide region
    if self:is_seed_collide(seed) then
        log('  skip seed: ' .. serpent.line(seed))
        return
    end

    local region = Region:new(seed)
    local direction = region:next_grow_direction()
    while region.high_priority do
        self:grow_edge(region, direction, C.GROW_STEP)
        direction = region:next_grow_direction()
    end
    self.low_priority_regions:push(region)
    -- add region to world
    self.world:add_rect(region, region)
    table.insert(self.mesh.regions, region)
    return region
end

function Grower:grow_low_priority_region(region)
    local direction = region:next_grow_direction()
    while direction do
        self:grow_edge(region, direction, C.GROW_STEP)
        direction = region:next_grow_direction()
    end
    self.world:update_rect(region, region)
end

function Grower:is_seed_collide(seed)
    local items, len
    -- 检测是否在块内
    items, len = self.mesh.chunk_world:query_rect(seed)
    if len == 0 then
        log("  skip seed since not in any chunks")
        return true
    end

    -- 检测是否和负空间冲突
    items, len = self.world:query_rect(seed)
    if len > 0 then
        log("  skip seed since collide with exists region")
        return true
    end
    return false
end

function Grower:grow_edge(region, direction, step)
    self.step_in_tick = self.step_in_tick + 1
    log('  growing edge: ' .. serpent.line({
        region = {region.x, region.y, region.w, region.h},
        direction = direction,
        step = step
    }))
    local claim_region = region:generate_region_to_claim(direction, step)
    -- 如果碰到边界就放弃
    if not self:is_region_in_world(claim_region) then
        region:stop_grow(direction)
        return
    end

    log("    about to claim: " .. serpent.line(claim_region))
    local items, len = self.world:query_rect(claim_region)
    if len == 0 then
        region:expand(direction, claim_region.step)
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

        self.mesh.seeder:seed_negative_space({
            region = region,
            direction = direction,
            items = items,
            len = len,
            on_new_seed = function(seed)
                self.low_priority_seeds:push(seed)
                self.mesh.display:display_seeds({seed})
            end
        })
    end
end


function Grower:is_region_in_world(region)
    for _, corner in pairs(Region.get_corners(region)) do
        local items, len = self.mesh.chunk_world:query_point(corner.x, corner.y)
        if len == 0 then
            return false
        end
    end
    return true
end

function Grower:find_step_from_nearest_obstruction(items, len, direction)
    local target, target_value
    for i = 1, len do
        local item = items[i]
        --log("    block by: " .. serpent.line(item))
        local x,y,w,h = self.world:get_rect(item)
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

return Grower

