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
    self.seeder = mesh.seeder
    self.display = mesh.display
    self.spaces = PriorityQueue:new()
    self:init()
end)

function Grower:init()
    -- 初始化网格生成时存在的块
    for chunk in self.mesh.surface.get_chunks() do
        local distance = (math.abs(chunk.x) + math.abs(chunk.y))
        if distance < 4 then
            local priority_position = distance * 32
            local priority = game.tick - (C.SPACE_PRIORITY.CHUNK - priority_position)
            self:add_chunk(chunk.area, priority)
        end
    end
end

function Grower:on_destroy()
    self.spaces:destroy()
end

-- 处理的优先级:
--  初始块, 位置 映射到 0~1 之间，dist(chunk) / 1e5
--  生在块，T - 300，相当于给了5秒提前
--  种子    T - 240
--  次级区域  T - 180
--  次级种子  T - 120

function Grower:grow()
    self.step_in_tick = 1

    while self.step_in_tick <= C.STEP_PER_TICK do
        local space, priority = self.spaces:pop()
        if space == nil then
            break
        end

        if space.space_type == C.SPACE_TYPE.CHUNK then
            local chunk = space
            log(priority .. ": growing chunk " .. serpent.line(chunk.area))
            self.mesh.chunk_world:add_area({}, chunk.area)
            local seeds = self.seeder:seed_chunk(chunk.area)
            self:add_seeds(seeds)
            self.display:display_world(chunk.area)
            self.display:display_seeds(seeds)
            self.step_in_tick = self.step_in_tick + 1
        elseif space.space_type == C.SPACE_TYPE.SEED then
            local seed = space
            log(priority .. ": growing new seed: " .. serpent.line(seed))
            local region = self:grow_seed(seed)
            self.display:display_region(region)
        elseif space.space_type == C.SPACE_TYPE.REGION then
            local region = space
            log(priority .. ' growing low priority region: ' .. serpent.line({
                region = { region.x, region.y, region.w, region.h },
                directions = region.grow_directions
            }))
            self:grow_low_priority_region(region)
            self.display:display_region(region)
        end
    end
end

function Grower:add_chunk(chunk_area, priority)
    if not priority then
        priority = game.tick - C.SPACE_PRIORITY.CHUNK
    end
    self.spaces:push(priority, {
        space_type = C.SPACE_TYPE.CHUNK,
        area = chunk_area
    })
end

function Grower:add_seeds(seeds)
    for _, seed in pairs(seeds) do
        self:add_seed(seed)
    end
end

function Grower:add_seed(seed, space_priority)
    space_priority = space_priority or C.SPACE_PRIORITY.SEED
    local priority = game.tick - space_priority
    seed.space_type = C.SPACE_TYPE.SEED
    self.spaces:push(priority, seed)
end

function Grower:add_region_space(region)
    region.space_type = C.SPACE_TYPE.REGION
    local priority = game.tick - C.SPACE_PRIORITY.LOW_PRIORITY_REGION
    self.spaces:push(priority, region)
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
    self:add_region_space(region)
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
        region = { region.x, region.y, region.w, region.h },
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
        -- FIXME
        -- 问题应该出在这里，向西扩展，但最终值变成比原来大
        -- 要传入当前 region 来防止缩减，从而丢弃异常值
        -- 也可以引入区域距离来防止误检测碰撞
        local target, point = self:find_step_from_nearest_obstruction(region, items, len, direction)
        if target ~= nil then
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
                    self:add_seed(seed, C.SPACE_PRIORITY.LOW_PRIORITY_SEED)
                    self.mesh.display:display_seed(seed)
                end
            })
        else
            -- 出错了，检测到障碍物，但障碍物和原区域有交集，输出来看情况
            log("    error: region collide with obstruction: " .. serpent.block({
                region = {region.x, region.y, region:east_axis(), region:south_axis()},
                direction = direction,
                claim_region = claim_region,
                items = items
            }))
            region:expand(direction, claim_region.step)
        end
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

local SMALL = 10e-8

function Grower:find_step_from_nearest_obstruction(region, items, len, direction)
    local target, target_value
    local bounding = region:axis_by_direction(direction)
    for i = 1, len do
        local item = items[i]
        --log("    block by: " .. serpent.line(item))
        local x, y, w, h = self.world:get_rect(item)
        if direction == defines.direction.east then
            -- find min x
            if x > bounding - SMALL then
                if target_value == nil then
                    target_value = x
                    target = item
                elseif x < target_value then
                    target_value = x
                    target = item
                end
            else
                self:log_region_collide_error(region, direction, item, x , bounding)
            end
        elseif direction == defines.direction.west then
            -- find max x + w
            if x + w < bounding + SMALL then
                if target_value == nil then
                    target_value = x + w
                    target = item
                elseif x + w > target_value then
                    target_value = x + w
                    target = item
                end
            else
                self:log_region_collide_error(region, direction, item, x + w, bounding)
            end
        elseif direction == defines.direction.south then
            -- find min y
            if y > bounding - SMALL then
                if target_value == nil then
                    target_value = y
                    target = item
                elseif y < target_value then
                    target_value = y
                    target = item
                end
            else
                self:log_region_collide_error(region, direction, item, y, bounding)
            end
        else
            -- north
            -- find max y + h
            if y + h < bounding + SMALL then
                if target_value == nil then
                    target_value = y + h
                    target = item
                elseif y + h > target_value then
                    target_value = y + h
                    target = item
                end
            else
                self:log_region_collide_error(region, direction, item, y + h , bounding)
            end
        end
    end
    return target, target_value
end

function Grower:log_region_collide_error(region, direction, item, propose_target_value, bounding)
    local x, y, w, h = self.world:get_rect(item)
    log("    error: region collide with obstruction item: " .. serpent.block({
        region = {W = region.x, N = region.y, E = region:east_axis(), S = region:south_axis()},
        direction = direction,
        item = {type = item.type, W = x, N = y, E = x + w, S = y + h},
        propose_target_value = propose_target_value,
        bounding = bounding
    }))
end

return Grower

