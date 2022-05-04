-- 移动基地生成逻辑，主要参考 OARC 实现
-- 当玩家放下基地车时，如果没有对应移动基地，则创建之
-- FIXME:
-- 1. 玩家只能进入自己的基地车，玩家重生，如果有基地，则重生到基地边。

local table = require 'stdlib/utils/table'
local Event = require 'klib/event/event'
local KC = require 'klib/container/container'
local Entity = require 'klib/gmo/entity'
local Area = require 'klib/gmo/area'

local CHUNK_SIZE = 32
local BASE_OUT_OF_MAP_Y = 500 * CHUNK_SIZE
local BASE_POSITION_Y = BASE_OUT_OF_MAP_Y + 100 * CHUNK_SIZE
-- 基地载具
local BASE_VEHICLE_NAME = "spidertron"
-- 基地大小
local BASE_SIZE = {width = 14 * CHUNK_SIZE, height = 8 * CHUNK_SIZE}
-- 基地间隔
local GAP_DIST = 4 * CHUNK_SIZE
-- 基地地块
local BASE_TILE = 'refined-concrete'
-- 基地建筑
local BASE_ENTITIES_BP = require 'scenario/mobile_factory/mobile_base_entity_blueprint_string'
-- 折跃资源频率
local RESOURCE_WARP_INTERVAL = 300
-- 折跃资源处理组数
local RESOURCE_WARP_SLOTS = 10
-- 资源折跃半径
local RESOURCE_WARP_LENGTH = CHUNK_SIZE / 2
-- 吸取率
local RESOURCE_WARP_RATE = 25
-- 资源名称
local IRON_ORE = "iron-ore"
local COPPER_ORE = "copper-ore"
local COAL = "coal"
local STONE = "stone"
local URANIUM_ORE = "uranium-ore"
local CRUDE_OIL = "crude-oil"
local RESOURCE_PATCH_LENGTH = 2 * CHUNK_SIZE
local RESOURCE_PATCH_SIZE = 4 * CHUNK_SIZE * CHUNK_SIZE

local _L = {}

local MobileBaseManager = KC.singleton('MobileBaseManager', function(self)
    self.mobile_bases = {}
    self.next_id = 1
    self.current_warp_slot = 1
end)

MobileBaseManager:on(defines.events.on_built_entity, function(self, event)
    if event.created_entity.name == BASE_VEHICLE_NAME then
        if event.created_entity.position.y < BASE_OUT_OF_MAP_Y then
            local player = game.players[event.player_index]
            --self:create_mobile_base(self.next_id, player.force, event.created_entity)
            --self.next_id = self.next_id + 1
            -- 没做队伍之前，玩家只有一个基地车
            if not self.mobile_bases[player.index] then
                self:create_mobile_base(player.index, player.force, event.created_entity)
            end
        end
    end
end)

--- 只能控制自己的蜘蛛或无主的蜘蛛
MobileBaseManager:on(defines.events.on_player_configured_spider_remote, function(self, event)
    local entity_data = Entity.get_data(event.vehicle)
    if not entity_data or not entity_data.base_id then return end
    local base = self.mobile_bases[entity_data.base_id]
    local player = game.players[event.player_index]
    if base.id ~= player.index then
        player.print({"mobile_base.cannot_control_others_base"})
        player.cursor_stack.connected_entity = nil
    end
end)

-- stdlib 的事件系统无法使用官方的过滤器，会导致性能问题
MobileBaseManager:on(defines.events.on_entity_died, function(self, event)
    if event.entity.name == BASE_VEHICLE_NAME then
        local entity_data = Entity.get_data(event.entity)
        if entity_data and entity_data.base_id then
           local base = self.mobile_bases[entity_data.base_id]
           base.force.print({"mobile_base.base_destroyed", base.id})
            _L.delete_base(base)
            self.mobile_bases[entity_data.base_id] = nil
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

--- 下线保护
MobileBaseManager:on(defines.events.on_player_left_game, function(self, event)
    local base = self.mobile_bases[event.player_index]
    if base and base.vehicle then
        base.vehicle.destructible = false
    end
end)

MobileBaseManager:on(defines.events.on_player_joined_game, function(self, event)
    local base = self.mobile_bases[event.player_index]
    if base and base.vehicle then
        base.vehicle.destructible = true
    end
end)

--- 传送玩家
MobileBaseManager:on(defines.events.on_player_driving_changed_state, function(self, event)
    -- 仅检查上车
    local player = game.players[event.player_index]
    if not player.driving then return end
    -- 检查上了哪辆基地车
    local entity_data = Entity.get_data(event.entity)
    if not entity_data or not entity_data.base_id then return end
    local base = self.mobile_bases[entity_data.base_id]
    if base then
        -- 只能进入自己的基地
        if base.id ~= player.index then
            player.print({"mobile_base.cannot_enter_others_base"})
            player.driving = false
            return
        end

        if self.teleporting then
            self.teleporting = false
        elseif base.generated and base.vehicle == event.entity then
            player.driving = false
            local safe_pos = base.surface.find_non_colliding_position('character', base.exit_entity.position, 2, 1)
            if not safe_pos then safe_pos = base.exit_entity.position end
            player.teleport(safe_pos, base.surface)
            -- 如果可以，做成可自行调节
            player.character_running_speed_modifier = 5
            player.character_reach_distance_bonus = GAP_DIST
            player.character_build_distance_bonus = GAP_DIST
        elseif base.exit_entity == event.entity then
            player.driving = false
            local safe_pos = base.surface.find_non_colliding_position('character', base.vehicle.position, 2, 1)
            if not safe_pos then safe_pos = base.vehicle.position end
            player.teleport(safe_pos, base.vehicle.surface)
            self.teleporting = true -- 因为是单线程执行，所有玩家可以共享一个检查位
            player.driving = true
            player.character_running_speed_modifier = 0
            player.character_reach_distance_bonus = 0
            player.character_build_distance_bonus = 0
        end
    end
end)

--- 玩家死亡后，如果有基地则传送到基地
MobileBaseManager:on(defines.events.on_player_respawned, function(self, event)
    local player = game.players[event.player_index]
    local base = self.mobile_bases[player.index]
    if base then
        local safe_pos = base.surface.find_non_colliding_position('character', base.vehicle.position, 2, 1)
        if not safe_pos then safe_pos = base.vehicle.position end
        player.teleport(safe_pos, base.vehicle.surface)
    end
end)

--- 为玩家生成基地
function MobileBaseManager:create_mobile_base(id, force, base_vehicle)
    force.print({"mobile_base.creating_base", id})
    -- 在很远的南方创建一块空间，并将其与基地载具关联起来
    base_vehicle.minable = false
    local base = {
        id = id,
        center = _L.to_base_center_pos(id),
        vehicle = base_vehicle,
        surface = base_vehicle.surface,
        force = force,
        generated = false,
        resource_amount = { [IRON_ORE] = 200000, [COPPER_ORE] = 100000, [COAL] = 100000, [STONE] = 100000, [URANIUM_ORE] = 0, [CRUDE_OIL] = 0},
        last_warp_resource_tick = 0
    }
    _L.assign_resource_locations(base)
    self.mobile_bases[id] = base
    Entity.set_data(base_vehicle, {base_id = id})
    self:delay_generate_base(base)
end

--- 检查块是否已经生成完成，完成后再实际进行分配空间
function MobileBaseManager:delay_generate_base(base)
    local area = Area.from_dimensions({width = BASE_SIZE.width+GAP_DIST, height = BASE_SIZE.width+GAP_DIST}, base.center)
    --surface.request_to_generate_chunks(base_center, BASE_SIZE/2/CHUNK_SIZE)
    base.force.chart(base.surface, area)

    Event.execute_until(defines.events.on_chunk_generated, function()
        return _L.is_base_chunks_generated(base.center, base.surface)
    end, function()
        if base.destroyed then
            base.force.print({"mobile_base.base_destroyed_before_created", base.id})
            return
        end
        _L.generate_base_tiles(base)
        _L.generate_base_entities(base)
        _L.warp_ores_to_base(base)
        base.force.chart(base.surface, area)
        base.generated = true
        base.force.print({"mobile_base.base_created", base.id})
    end, function()  end)
end

--- 处理资源折跃
--- 为性能考虑，一次只处理少量基地，增加每次处理的速率
MobileBaseManager:on_nth_tick(RESOURCE_WARP_INTERVAL/RESOURCE_WARP_SLOTS, function(self, event)
    -- 检查坦克周围有没有资源，如果有，把范围内的资源传送到对应资源的位置
    -- 这里是主要性能瓶颈
    for _, base in pairs(self.mobile_bases) do
        if base.generated and (base.id % RESOURCE_WARP_SLOTS) == self.current_warp_slot then
            local resources = base.surface.find_entities_filtered({
                area = Area.expand(base.vehicle.bounding_box, RESOURCE_WARP_LENGTH),
                name = { IRON_ORE, COPPER_ORE, COAL, STONE, URANIUM_ORE, CRUDE_OIL }
            })
            if not table.is_empty(resources) then
                _L.warp_resources_to_base(resources, base)
            end
            _L.warp_inventory(base)
        end
    end
    self.current_warp_slot = self.current_warp_slot + 1
    if self.current_warp_slot == RESOURCE_WARP_SLOTS then
        self.current_warp_slot = 0
    end
end)

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
    base.destroyed = true
    -- 消除基地数据
    Entity.set_data(base.vehicle)
    if base.exit_entity then
        Entity.set_data(base.exit_entity)
    end
    -- 消除基地块
    _L.iterate_base_chunks(base.center, base.surface, function(pos)
        base.surface.delete_chunk(pos)
        return true
    end)
    -- 把基地内所有玩家传送走
    local area = Area.from_dimensions(BASE_SIZE, base.center)
    area = Area.load(area:expand(GAP_DIST/2))
    local characters = base.surface.find_entities_filtered({name='character', area = area})
    if not table.is_empty(characters) then
        for _, character in ipairs(characters) do
            local player = character.player
            if player then
                local safe_pos = base.surface.find_non_colliding_position('character', base.vehicle.position, 10, 1)
                if not safe_pos then safe_pos = base.vehicle.position end
                player.teleport(safe_pos, base.surface)
                player.character_running_speed_modifier = 0
                player.character_reach_distance_bonus = 0
                player.character_build_distance_bonus = 0
            end
        end
    end
end

--- 生成地基
function _L.generate_base_tiles(base)
    local area = Area.from_dimensions(BASE_SIZE, base.center)
    local tiles = {}
    for pos in area:iterate() do
        table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    -- 上方出口地基
    local bounding_box = base.vehicle.bounding_box
    area = Area.center_on(bounding_box, {x=base.center.x, y=base.center.y - BASE_SIZE.height/2})
    for pos in Area.load(area):iterate() do
        table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    -- 下方水池
    area = Area.from_dimensions({width = CHUNK_SIZE, height = CHUNK_SIZE}, {x = base.center.x, y = base.center.y + BASE_SIZE.height/2 - CHUNK_SIZE})
    for pos in area:iterate() do
        table.insert(tiles, { name = 'water', position = pos})
    end
    base.vehicle.surface.set_tiles(tiles)
end

--- 生成出口，基地内建筑
function _L.generate_base_entities(base)
    local center = base.center
    local create_exit_entity = function(exit_point)
        local exit_entity = base.surface.create_entity({
            name = BASE_VEHICLE_NAME, position = exit_point, force = base.vehicle.force
        })
        exit_entity.minable = false
        exit_entity.destructible = false
        Entity.set_data(exit_entity, {base_id = base.id})
        return exit_entity
    end
    base.exit_entity = create_exit_entity({x=center.x,y=center.y-BASE_SIZE.height/2})

    -- 创建资源围墙
    Entity.build_blueprint_from_string(BASE_ENTITIES_BP, base.surface,
            {x = base.center.x - BASE_SIZE.width/2, y = base.center.y + BASE_SIZE.height/2 - 2*CHUNK_SIZE}, base.force,
            {minable = false, destructible = false}
    )

    -- 创建原油
    for offset_x = -RESOURCE_PATCH_LENGTH/4, RESOURCE_PATCH_LENGTH/4, RESOURCE_PATCH_LENGTH/4 do
        for offset_y = -RESOURCE_PATCH_LENGTH/4, RESOURCE_PATCH_LENGTH/4, RESOURCE_PATCH_LENGTH/4 do
            local oil_resource = base.surface.create_entity({
                name=CRUDE_OIL, amount = 300,
                position = {base.resource_locations[CRUDE_OIL].x+offset_x, base.resource_locations[CRUDE_OIL].y+offset_y}
            })
            oil_resource.initial_amount = 300
        end
    end
end

--- 计算资源位置
function _L.assign_resource_locations(base)
    base.resource_locations = {}
    local location_y = base.center.y + BASE_SIZE.height /2 - CHUNK_SIZE
    base.resource_locations[IRON_ORE] = {x = base.center.x - BASE_SIZE.width /2 + CHUNK_SIZE, y = location_y}
    base.resource_locations[COPPER_ORE] = {x = base.center.x + BASE_SIZE.width /2 - CHUNK_SIZE, y = location_y}
    base.resource_locations[COAL] = {x = base.center.x - BASE_SIZE.width /2 + 3*CHUNK_SIZE, y = location_y}
    base.resource_locations[STONE] = {x = base.center.x + BASE_SIZE.width /2 - 3*CHUNK_SIZE, y = location_y}
    base.resource_locations[CRUDE_OIL] = {x = base.center.x - BASE_SIZE.width /2 + 5*CHUNK_SIZE, y = location_y}
    base.resource_locations[URANIUM_ORE] = {x = base.center.x + BASE_SIZE.width /2 - 5*CHUNK_SIZE, y = location_y}
end

--- 折跃资源到基地内
function _L.warp_resources_to_base(resources, base)
    _L.warp_to_base_storage(resources, base)
    _L.warp_oil_to_base(base)
    _L.warp_ores_to_base(base)
end

--- 添加到基地资源计数
function _L.warp_to_base_storage(resources, base)
    for _, resource in ipairs(resources) do
        local delta, rate
        if resource.name == CRUDE_OIL then
            rate = RESOURCE_WARP_RATE * 3000
        else
            rate = RESOURCE_WARP_RATE
        end
        if resource.amount > rate then
            delta = rate
            resource.amount = resource.amount - delta
            base.resource_amount[resource.name] = base.resource_amount[resource.name] + delta
        else
            delta = resource.amount
            base.resource_amount[resource.name] = base.resource_amount[resource.name] + delta
            resource.destroy()
        end
    end
    --game.print(serpent.line(base.resource_amount))
end

--- 折跃原油
function _L.warp_oil_to_base(base)
    local amount = base.resource_amount[CRUDE_OIL]
    local num_crude_oil = 9
    if amount >= num_crude_oil * 30000 then
        local delta = amount / num_crude_oil
        base.resource_amount[CRUDE_OIL] = amount % num_crude_oil
        local entities = base.surface.find_entities_filtered({
            name = CRUDE_OIL,
            area = Area.from_dimensions({width=RESOURCE_PATCH_LENGTH,height=RESOURCE_PATCH_LENGTH}, base.resource_locations[CRUDE_OIL])
        })
        for _, e in ipairs(entities) do
            e.amount = e.amount + delta
        end
    end
end

--- 折跃矿石
function _L.warp_ores_to_base(base)
    for _, name in ipairs({IRON_ORE, COPPER_ORE, COAL, STONE, URANIUM_ORE}) do
        local amount = base.resource_amount[name]
        local c = base.resource_locations[name]
        if amount >= RESOURCE_PATCH_SIZE*10 then
            local exist_resources = base.surface.find_entities_filtered({
                name=name,
                area = Area.from_dimensions({width=RESOURCE_PATCH_LENGTH,height=RESOURCE_PATCH_LENGTH},c)
            })
            local exist_amount = 0
            for _, res in ipairs(exist_resources) do
                exist_amount = exist_amount + res.amount
                res.destroy()
            end
            local new_amount = (amount + exist_amount) / RESOURCE_PATCH_SIZE
            local remain_amount = (amount + exist_amount) % RESOURCE_PATCH_SIZE
            base.resource_amount[name] = remain_amount

            for offset_x = - RESOURCE_PATCH_LENGTH/2, RESOURCE_PATCH_LENGTH/2-1 do
                for offset_y = - RESOURCE_PATCH_LENGTH/2, RESOURCE_PATCH_LENGTH/2-1 do
                    local position = { x=c.x+offset_x, y=c.y+offset_y}
                    base.surface.create_entity({ name = name, position = position, amount = new_amount})
                end
            end
        end
    end
end

--- 同步基地出口车与基地车的物品栏
--- 设置了过滤器的做输出，没设置的做输入
function _L.warp_inventory(base)
    -- 目前这种实现只能处理简单的整堆传送
    local inv1 = base.vehicle.get_inventory(defines.inventory.car_trunk)
    local inv2 = base.exit_entity.get_inventory(defines.inventory.car_trunk)
    local providedItemStack1 = {}
    local requestItemStack1 = {}
    for i=1, #inv1 do
        local filter_name = inv1.get_filter(i)
        if filter_name then
            -- 统计需要的物品
            local stack = inv1[i]
            if stack.count == 0 then
                table.insert(requestItemStack1, {name=filter_name, stack=stack})
            end
        else
            -- 统计可提供物品
            local stack = inv1[i]
            if stack.valid_for_read then
                local pl = providedItemStack1[stack.name]
                if not pl then
                    pl = {}
                    providedItemStack1[stack.name] = pl
                end
                table.insert(pl, stack)
            end
        end
    end

    local providedItemStack2 = {}
    local requestItemStack2 = {}
    for i=1, #inv2 do
        local filter_name = inv2.get_filter(i)
        if filter_name then
            -- 统计需要的物品
            local stack = inv2[i]
            if stack.count == 0 then
                table.insert(requestItemStack2, {name=filter_name, stack=stack})
            end
        else
            -- 统计可提供物品
            local stack = inv2[i]
            if stack.valid_for_read then
                local pl = providedItemStack2[stack.name]
                if not pl then
                    pl = {}
                    providedItemStack2[stack.name] = pl
                end
                table.insert(pl, stack)
            end
        end
    end

    -- transfer item stack
    for _, t in ipairs(requestItemStack1) do
        local name, stack = t.name, t.stack
        local stack_list = providedItemStack2[name]
        if stack_list and not table.is_empty(stack_list) then
            local p_stack = table.remove(stack_list)
            stack.transfer_stack(p_stack)
        end
    end

    for _, t in pairs(requestItemStack2) do
        local name, stack = t.name, t.stack
        local stack_list = providedItemStack1[name]
        if stack_list and not table.is_empty(stack_list) then
            local p_stack = table.remove(stack_list)
            stack.transfer_stack(p_stack)
        end
    end
end

return MobileBaseManager