-- 移动基地生成逻辑，主要参考 OARC 实现
-- 当玩家放下基地车时，如果没有对应移动基地，则创建之

local Area = require '__flib__/area'
local Position = require '__stdlib__/stdlib/area/position'
local Event = require 'klib/event/event'
local KC = require 'klib/container/container'

local CHUNK_SIZE = 32
local BASE_OUT_OF_MAP_Y = 500 * CHUNK_SIZE
local BASE_POSITION_Y = BASE_OUT_OF_MAP_Y + 100 * CHUNK_SIZE
-- 基地大小
local BASE_SIZE = {width = 6 * CHUNK_SIZE, height = 4 * CHUNK_SIZE}
-- 基地间隔
local GAP_DIST = 4 * CHUNK_SIZE
-- 基地地块
local BASE_TILE = 'refined-concrete'

local _L = {}

local MobileBaseManager = KC.singleton('MobileBaseManager', function(self)
    self.mobile_bases = {}
end)

MobileBaseManager:on(defines.events.on_built_entity, function(self, event)
    if event.created_entity.name == 'tank' then
        if not self.mobile_bases[event.player_index] then
            self:create_mobile_base(game.players[event.player_index], event.created_entity)
        end
    end
end)

-- stdlib 的事件系统无法使用官方的过滤器，会导致性能问题
MobileBaseManager:on(defines.events.on_entity_died, function(self, event)
    if event.entity.name == 'tank' then
        for player_index, base in pairs(self.mobile_bases) do
            if event.entity == base.vehicle then
                game.players[player_index].print("你的基地被摧毁了")
                _L.delete_base(base)
                self.mobile_bases[player_index] = nil
            end
        end
    end
end)

--- 填充基地空间间隙
MobileBaseManager:on(defines.events.on_chunk_generated, function(self, event)
    local surface = event.surface
    if event.area.right_bottom.y < BASE_OUT_OF_MAP_Y then return end
    local area = Area.load(event.area)
    local tiles = {}
    for pos in area:iterate() do
        table.insert(tiles, {name = 'out-of-map', position = pos})
    end
    surface.set_tiles(tiles)
end)

--- 传送玩家
MobileBaseManager:on(defines.events.on_player_driving_changed_state, function(self, event)
    local base = self.mobile_bases[event.player_index]
    if base then
        if self.teleporting then
            self.teleporting = false
        elseif base.generated and base.vehicle == event.entity then
            local player = game.players[event.player_index]
            player.driving = false
            local safe_pos = base.surface.find_non_colliding_position('character', base.left_exit_entity.position, 2, 1)
            player.teleport(safe_pos, base.surface)
        elseif base.left_exit_entity == event.entity or base.right_exit_entity == event.entity then
            local player = game.players[event.player_index]
            player.driving = false
            player.teleport(base.vehicle.position, base.vehicle.surface)
            player.driving = true
            self.teleporting = true
        end
    end
end)

--- 为玩家生成基地
function MobileBaseManager:create_mobile_base(player, base_vehicle)
    player.print("正在为你创建移动基地")
    -- 在很远的南方创建一块空间，并将其与基地载具关联起来
    base_vehicle.minable = false
    local base = {
        player = player,
        vehicle = base_vehicle,
        surface = base_vehicle.surface,
        generated = false
    }
    self.mobile_bases[player.index] = base
    self:alloc_base(player, base)
end

--- 分配基地空间
function MobileBaseManager:alloc_base(player, base)
    -- 计算创建基地的中心位置
    base.center = _L.to_base_center_pos(player.index)
    self:delay_generate_base(player, base)
end

--- 检查块是否已经生成完成，完成后再实际进行分配空间
function MobileBaseManager:delay_generate_base(player, base)
    local area = Area.from_dimensions({width = BASE_SIZE.width+GAP_DIST, height = BASE_SIZE.width+GAP_DIST}, base.center)
    --surface.request_to_generate_chunks(base_center, BASE_SIZE/2/CHUNK_SIZE)
    player.force.chart(base.surface, area)

    Event.execute_until(defines.events.on_chunk_generated, function()
        return _L.is_base_chunks_generated(base.center, base.surface)
    end, function()
        _L.generate_base_tiles(base)
        _L.generate_base_entities(base)
        player.force.chart(base.surface, area)
        self.mobile_bases[player.index].generated = true
        base.player.print("移动基地创建完成")
    end, function()  end)
end

--- id 转换成中心位置
function _L.to_base_center_pos(id)
    -- 距离中心等距，奇左偶右
    local offset_x = (id / 2)
    if id % 2 == 0 then
        offset_x = offset_x + 0.5
    else
        offset_x = - offset_x - 0.5
    end
    return {
        x = (GAP_DIST + BASE_SIZE.width) * offset_x,
        y = BASE_POSITION_Y + GAP_DIST / 2 + BASE_SIZE.height / 2
    }
end

--- 对基地区块迭代
function _L.iterate_base_chunks(center, surface, handler)
    for offset_x = -BASE_SIZE.width/2 - CHUNK_SIZE/2, BASE_SIZE.width/2 + CHUNK_SIZE/2, CHUNK_SIZE do
        for offset_y = -BASE_SIZE.height/2 - CHUNK_SIZE/2, BASE_SIZE.height/2 + CHUNK_SIZE/2, CHUNK_SIZE do
            local pos = { x = (center.x + offset_x)/32, y = (center.y + offset_y)/32}
            if not handler(pos) then return false end
        end
    end
    return true
end

--- 检查给定中心的块是否已经生成完成
function _L.is_base_chunks_generated(center_position, surface)
    return _L.iterate_base_chunks(center_position, surface, function(pos)
        return surface.is_chunk_generated(pos)
    end)
end

---- 删除基地
function _L.delete_base(base)
    _L.iterate_base_chunks(base.center, base.surface, function(pos)
        base.surface.delete_chunk(pos)
        return true
    end)
    local area = Area.from_dimensions(BASE_SIZE, base.center)
    area = Area.load(area:expand(GAP_DIST/2))
    if area:contains_position(base.player.position) then
        local safe_pos = base.surface.find_non_colliding_position('character', base.vehicle.position, 10, 1)
        base.player.teleport(safe_pos, base.surface)
    end
end

--- 生成地基
function _L.generate_base_tiles(base)
    local area = Area.from_dimensions(BASE_SIZE, base.center)
    local tiles = {}
    for pos in area:iterate() do
        table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    -- 左右出口的地基
    local bounding_box = base.vehicle.bounding_box
    area = Area.center_on(bounding_box, {x=base.center.x - BASE_SIZE.width/2, y=base.center.y})
    for pos in Area.load(area):iterate() do
        table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    area = Area.center_on(bounding_box, {x=base.center.x + BASE_SIZE.width/2, y=base.center.y})
    for pos in Area.load(area):iterate() do
        table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    -- 上方水
    area = Area.from_dimensions({width = BASE_SIZE.width, height = 2}, {x = base.center.x, y = base.center.y - BASE_SIZE.height/2 + 1})
    for pos in area:iterate() do
        table.insert(tiles, { name = 'water', position = pos})
    end
    base.vehicle.surface.set_tiles(tiles)
end

--- 生成出口
function _L.generate_base_entities(base)
    local center = base.center
    local left_exit_point = Position.subtract(center, {x = BASE_SIZE.width/2, y=0})
    local right_exit_point = Position.add(center, {x = BASE_SIZE.width/2, y=0})
    local create_exit_entity = function(exit_point)
        local exit_entity = base.surface.create_entity({
            name = 'tank', position = exit_point, force = base.vehicle.force
        })
        exit_entity.minable = false
        exit_entity.destructible = false
        return exit_entity
    end
    base.left_exit_entity = create_exit_entity(left_exit_point)
    base.right_exit_entity = create_exit_entity(right_exit_point)
end

return MobileBaseManager