local log = (require '__stdlib__/stdlib/misc/logger')('pathfinder_seeder', DEBUG)
local Area = require '__stdlib__/stdlib/area/area'
local Position = require '__stdlib__/stdlib/area/position'
local KC = require 'klib/container/container'
local C = require 'pda/pathfinder/config'
local Tiles = require 'pda/pathfinder/pasfv/tiles'

local Seeder = KC.class("pda.pathfinder.pasfv.Seeder", function(self, mesh)
    self.mesh = mesh
    self.world = mesh.world
end)

function Seeder:seed_chunk(area)
    log(string.format("seeding chunk %s", serpent.line(area)))
    self:_add_position_spaces(area)
    return self:_new_seeds(area)
end

function Seeder:seed_negative_space(args)
    local region = args.region
    local direction = args.direction
    local items = args.items
    local len = args.len
    local on_new_seed = args.on_new_seed or function() end

    -- 区域无法扩展时，尝试添加种子
    local claim_region = region:generate_region_to_claim(direction, C.UNIT_SIZE)
    -- 障碍物变化时，更新种子
    if items and len then
        self:_seed_edge_with_items(claim_region.x, claim_region.y, claim_region.w, claim_region.h, items, len, on_new_seed)
    else
        self:_seed_edge(claim_region.x, claim_region.y, claim_region.w, claim_region.h, on_new_seed)
    end
end

--------------------------------------------------------------------------------
--- 初始化正区间
--------------------------------------------------------------------------------

function Seeder:_add_position_spaces(area)
    self:_add_entities(area)
    self:_add_tiles(area)
end

function Seeder:_add_entities(area)
    local entities = self.mesh.surface.find_entities_filtered({
        area = area,
        collision_mask = self.mesh.collision_mask
    })
    for _, entity in pairs(entities) do
        if entity.name ~= 'character' then
            self:_add_entity(entity)
        end
    end
end

function Seeder:_add_entity(entity)
    local item = {
        name = entity.name,
        type = C.OBJECT_TYPES.ENTITY
    }
    self.world:add(
            item,
            entity.bounding_box.left_top.x,
            entity.bounding_box.left_top.y,
            entity.bounding_box.right_bottom.x - entity.bounding_box.left_top.x,
            entity.bounding_box.right_bottom.y - entity.bounding_box.left_top.y
    )
end

function Seeder:_add_tiles(area)
    local tiles = self.mesh.surface.find_tiles_filtered({
        area = area,
        collision_mask = self.mesh.collision_mask
    })
    tiles = Tiles.merge_tiles(tiles)
    for _, tile in pairs(tiles) do
        self:_add_tile(tile)
    end
end

function Seeder:_add_tile(tile)
    local item = {
        name = tile.name,
        type = C.OBJECT_TYPES.TILE
    }
    self.world:add(
            item,
            tile.left_top.x,
            tile.left_top.y,
            tile.right_bottom.x - tile.left_top.x,
            tile.right_bottom.y - tile.left_top.y
    )
    --self.world:add(item, tile.position.x - 0.5, tile.position.y - 0.5, 1,1)
end

--------------------------------------------------------------------------------
--- 添加种子
--------------------------------------------------------------------------------

function Seeder:_new_seeds(area)
    -- TODO: 如果没有障碍物，如何处理边界
    local seeds = {}
    local on_new_seed = function(seed)
        table.insert(seeds, seed)
    end

    local items, len = self.world:query_area(area)
    if len == 0 then
        local seed = self:_new_seed(Position.unpack(Area.center(area)))
        table.insert(seeds, seed)
    else
        for i=1, len do
            local item = items[i]
            local x,y,w,h = self.world:get_rect(item)
            -- 对每条边缘添加种子，如果边缘被隔开，每个分开的部分都添加一个种子

            -- 用 x,y,w,h 来表示矩形
            -- e-l: x-(w+u)/2, y, u, h
            -- e-r: x+(w+u)/2, y, u, h
            -- e-t: x, y-(h+u)/2, w, u
            -- e-b: x, y+(h+u)/2, w, u
            self:_seed_edge(x - C.UNIT_SIZE, y, C.UNIT_SIZE, h, on_new_seed)
            self:_seed_edge(x + w, y, C.UNIT_SIZE, h, on_new_seed)
            self:_seed_edge(x, y - C.UNIT_SIZE, w, C.UNIT_SIZE, on_new_seed)
            self:_seed_edge(x, y + h, w, C.UNIT_SIZE, on_new_seed)
        end
    end
    return seeds
end

function Seeder:_seed_edge(x, y, w, h, on_new_seed)
    --self:_renderRect({x = x, y = y, w = w, h = h, color = ColorList.lightblue})
    local items, len = self.world:query_rect(x, y, w, h)
    self:_seed_edge_with_items(x, y, w, h ,items, len, on_new_seed)
end

function Seeder:_seed_edge_with_items(x, y, w ,h, items, len, on_new_seed)
    if len == 0 then
        local seed = self:_new_seed(x, y)
        if on_new_seed then on_new_seed(seed) end
    else
        -- 边上有障碍物，故需要添加多个
        if w > h then -- 横向的
            -- 以 x 排序，计算出每一段负向区域
            self:_x_add_region_if_gap_greater_than_unit(x, y, w, h, items, len, on_new_seed)
        else    -- 竖向的
            self:_y_add_region_if_gap_greater_than_unit(x, y, w, h, items, len, on_new_seed)
        end
    end
end

function Seeder:_new_seed(x,y)
    return {
        x = x,
        y = y,
        w = C.UNIT_SIZE,
        h = C.UNIT_SIZE
    }
end

function Seeder:_x_add_region_if_gap_greater_than_unit(x, y, w, h, items, len, on_new_seed)
    local segments = {}
    for i = 1, len do
        local x,y,w,h = self.world:get_rect(items[i])
        table.insert(segments, {point=x, len=w})
    end
    self:_add_region_if_gap_greater_than_unit(x, x+w, segments, len, function(point)
        local seed = self:_new_seed(point, y)
        if on_new_seed then on_new_seed(seed) end
    end)
end

function Seeder:_y_add_region_if_gap_greater_than_unit(x,y,w,h,items, len, on_new_seed)
    local segments = {}
    for i = 1, len do
        local x,y,w,h = self.world:get_rect(items[i])
        table.insert(segments, {point=y, len=h})
    end
    self:_add_region_if_gap_greater_than_unit(y, y+h, segments, len, function(point)
        local seed = self:_new_seed(x, point)
        if on_new_seed then on_new_seed(seed) end
    end)
end

function Seeder:_add_region_if_gap_greater_than_unit(start_point, end_point, segments, len, callback)
    table.sort(segments, function(a,b)
        return a.point < b.point
    end)
    local cur = start_point
    for i = 1, len do
        local seg = segments[i]
        if seg.point - cur >= C.UNIT_SIZE then
            callback(cur)
        end
        cur = seg.point + seg.len
    end
    if end_point - cur >= C.UNIT_SIZE then
        callback(cur)
    end
end

return Seeder
