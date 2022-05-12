local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Chunk = require 'klib/gmo/chunk'
local Dimension = require 'klib/gmo/dimension'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'
local Config = require 'scenario/mobile_factory/config'
local RegrowthMap = require 'modules/regrowth_map_nauvis'

local CHUNK_SIZE = 32
local BASE_POSITION_Y, BASE_SIZE, GAP_DIST = Config.BASE_POSITION_Y, Config.BASE_SIZE, Config.GAP_DIST
local BASE_VEHICLE_NAME, BASE_TILE = Config.BASE_VEHICLE_NAME, Config.BASE_TILE
local RESOURCE_PATCH_LENGTH, CRUDE_OIL = Config.RESOURCE_PATCH_LENGTH, Config.CRUDE_OIL

local MobileBaseGenerator = KC.class('scenario.MobileFactory.MobileBaseGenerator', {
    -- 正在生成的基地列表，以 generator_id 作键
    generating_list = {}
},function(self, base)
    self:set_base(base)
end)

MobileBaseGenerator:reference_objects("base")

--- 通过 id 计算基地中心位置
function MobileBaseGenerator:compute_base_center()
    local index = self:get_base().index
    -- 距离中心等距，奇左偶右
    local offset_x = (index / 2)
    if index % 2 == 0 then
        offset_x = offset_x + 0.5
    else
        offset_x = - offset_x - 0.5
    end
    return {
        x = (GAP_DIST + BASE_SIZE.width) * offset_x,
        y = BASE_POSITION_Y + GAP_DIST / 2 + BASE_SIZE.height / 2
    }
end

--- 生成基地载具
function MobileBaseGenerator:create_base_vehicle()
    local base = self:get_base()
    local team = base:get_team()

    local surface = base.surface
    local position = {x=math.random(-CHUNK_SIZE, CHUNK_SIZE), y=math.random(-CHUNK_SIZE, CHUNK_SIZE)}
    local safe_pos = surface.find_non_colliding_position(BASE_VEHICLE_NAME, position, 32, 1) or position
    local vehicle = surface.create_entity({
        name = BASE_VEHICLE_NAME, position = safe_pos, force = team.force, raise_built = true
    })
    Entity.set_data(vehicle, {base_id = base:get_id()})
    return vehicle
end


-- 生成基地
function MobileBaseGenerator:generate()
    self:render_base_owner()

    local base = self:get_base()
    local area = Area.from_dimensions(Dimension({GAP_DIST, GAP_DIST}) + BASE_SIZE, base.center)
    -- 可以换成块请求，但 request_to_generate_chunks 只支持半径
    base.force.chart(base.surface, area)
    Table.insert(MobileBaseGenerator:get_generating_list(), self:get_id())
    base:get_team().force.print({"mobile_factory.creating_base", base:get_name()})
end

function MobileBaseGenerator:render_base_owner()
    local base = self:get_base()
    local team = base:get_team()

    rendering.draw_text {
        text = {"mobile_factory.mobile_base_caption", team:get_name()},
        surface = base.vehicle.surface,
        target = base.vehicle,
        target_offset = {0, -8},
        color = { r = 0.6784, g = 0.8471, b = 0.9020, a = 1 },
        scale = 1.80,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }
end


--- 当基地块生成完成后，继续生成基地地板和实体
function MobileBaseGenerator:on_base_chunks_generated()
    local base = self:get_base()
    if base.destroyed then
        game.print({"mobile_factory.base_destroyed_before_created", base:name()})
        return true
    end

    if self:is_base_chunks_generated() then
        self:generate_base_tiles()
        self:generate_base_entities()
        base:get_resource_warper():warp_ores_to_base()
        KC.singleton(RegrowthMap):regrowth_off_limits_of_center(base.center, Dimension.expand(BASE_SIZE, CHUNK_SIZE))
        local area = Area.from_dimensions({width = BASE_SIZE.width+GAP_DIST, height = BASE_SIZE.width+GAP_DIST}, base.center)
        base.force.chart(base.surface, area)
        base.generated = true
        base.force.print({"mobile_factory.base_created", base:get_name()})
        return true
    else
        return false
    end
end

--- 检查给定中心的块是否已经生成完成
function MobileBaseGenerator:is_base_chunks_generated()
    local base = self:get_base()
    return not Chunk.find_from_dimensions(Dimension.expand(BASE_SIZE, CHUNK_SIZE), base.center, function(c_pos)
        return not base.surface.is_chunk_generated(c_pos)
    end)
end

--- 生成地基
function MobileBaseGenerator:generate_base_tiles()
    local base = self:get_base()
    local tiles = {}

    local area = Area.from_dimensions(BASE_SIZE, base.center)
    for pos in area:iterate(true) do
        Table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    -- 上方出口地基
    local bounding_box = base.vehicle.bounding_box
    area = Area.center_on(bounding_box, {x=base.center.x, y=base.center.y - BASE_SIZE.height/2})
    for pos in area:iterate(true) do
        Table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    -- 下方水池
    area = Area.from_dimensions(
            {width = CHUNK_SIZE, height = CHUNK_SIZE},
            {x = base.center.x, y = base.center.y + BASE_SIZE.height/2 - CHUNK_SIZE}
    )
    for pos in area:iterate(true) do
        Table.insert(tiles, { name = 'water', position = pos})
    end
    base.vehicle.surface.set_tiles(tiles)
end

--- 生成出口，基地内建筑
function MobileBaseGenerator:generate_base_entities()
    local base = self:get_base()
    local center = base.center
    local create_exit_entity = function(exit_point)
        local exit_entity = base.surface.create_entity({
            name = BASE_VEHICLE_NAME, position = exit_point, force = base.force
        })
        exit_entity.minable = false
        exit_entity.destructible = false
        --exit_entity.active = false
        Entity.set_data(exit_entity, {base_id = base:get_id()})
        return exit_entity
    end
    base.exit_entity = create_exit_entity({x=center.x,y=center.y-BASE_SIZE.height/2})

    -- 创建资源围墙
    Entity.build_blueprint_from_string(Config.BASE_ENTITIES_BP, base.surface,
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

--- 填充基地空间间隙
local function fill_out_of_map_tiles(surface, area)
    if area.right_bottom.y < Config.BASE_OUT_OF_MAP_Y then return end
    local tiles = {}
    for pos in Area(area):iterate(true) do
        Table.insert(tiles, {name = 'out-of-map', position = pos})
    end
    surface.set_tiles(tiles)
end

function MobileBaseGenerator:on_destroy()
    local base = self:get_base()
    -- 消除基地数据
    Entity.set_data(base.vehicle)
    if base.exit_entity then
        Entity.set_data(base.exit_entity)
    end
    if base.vehicle.valid then
        base.vehicle.die()
    end
    -- 删除基地块
    Chunk.each_from_dimensions(Dimension.expand(BASE_SIZE, CHUNK_SIZE), base.center, function(c_pos)
        KC.singleton(RegrowthMap):regrowth_force_refresh_chunk({x=c_pos.x*CHUNK_SIZE, y=c_pos.y*CHUNK_SIZE}, 0)
        base.surface.delete_chunk(c_pos)
    end)
end

Event.register(defines.events.on_chunk_generated, function(event)
    -- 如果有多表面，需要判断是不是大地图表面
    fill_out_of_map_tiles(event.surface, event.area)

    local list = MobileBaseGenerator:get_generating_list()
    Table.array_each_inverse(list, function(generator_id, index)
        local generator = KC.get(generator_id)
        if not generator or generator:on_base_chunks_generated() then
            Table.remove(list, index)
        end
    end)
end)

return MobileBaseGenerator
