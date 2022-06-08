local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Chunk = require 'klib/gmo/chunk'
local Dimension = require 'klib/gmo/dimension'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'
local Tasks = require 'klib/task/tasks'

local Config = require 'scenario/mobile_factory/config'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local ChunkKeeper = require 'scenario/mobile_factory/mf_chunk_keeper'

local BASE_POSITION_Y, BASE_MAXIMAL_DIMENSIONS, GAP_DIST = Config.BASE_POSITION_Y, Config.BASE_MAXIMAL_DIMENSIONS, Config.GAP_DIST
local BASE_VEHICLE_NAME, BASE_TILE = Config.BASE_VEHICLE_NAME, Config.BASE_TILE

local Generator = KC.class(Config.PACKAGE_BASE_PREFIX .. 'Generator', function(self, base)
    self.base = base
    self.base_position_index = base.team_center:alloc_base_position_index()
end)

--- 通过 id 计算基地中心位置，返回 pos
function Generator:compute_base_center()
    local team_position_index = self.base.team_center.team_position_index
    local base_position_index = self.base_position_index

    -- 距离中心等距，奇左偶右
    local offset_x = (team_position_index / 2)
    if team_position_index % 2 == 0 then
        offset_x = offset_x + 0.5
    else
        offset_x = - offset_x - 0.5
    end

    return Position.round({
        x = (GAP_DIST + BASE_MAXIMAL_DIMENSIONS.width) * offset_x,
        y = BASE_POSITION_Y + (GAP_DIST + BASE_MAXIMAL_DIMENSIONS.height) * (base_position_index + 0.5)
    })
end


-- 为了处理块生成事件中，基地生成执行先于黑块生成的问题，延迟 1 tick 执行基地生成
local DelayGenerateTask = Tasks.register_scheduled_task(
        Generator:get_class_name() .. '$DelayGenerateTask', 1, function(self)
            self.generator:on_base_chunks_generated()
        end
)

local GenerateTask = Tasks.register_event_task(
        Generator:get_class_name() .. '$GenerateTask',
        defines.events.on_chunk_generated, function(self, event)
            local generator = self.generator
            local base = generator.base
            if base.destroyed then
                game.print({"mobile_factory.base_destroyed_before_created", base:get_name()})
                self:destroy()
            elseif generator:is_base_chunks_generated() then
                local task = DelayGenerateTask:new_local()
                task.generator = generator
                self:destroy()
            end
end)

-- 生成基地
function Generator:generate()
    local base = self.base
    local area = U.get_base_area(base, true)
    Chunk.request_to_generate_chunks(base.surface, area)
    if ChunkKeeper then KC.singleton(ChunkKeeper):register_permanent_area(Area.expand(area, 16)) end
    local task = GenerateTask:new_local()
    task.generator = self

    base.team.force.print({"mobile_factory.creating_base", base:get_name()})
end

--- 当基地块生成完成后，继续生成基地地板和实体
function Generator:on_base_chunks_generated()
    local base = self.base
    if not base.destroyed then
        self:generate_base_tiles()
        self:generate_base_entities()
        local area = U.get_base_area(base, true)
        base.force.chart(base.surface, area)
        base.generated = true
        base:for_each_components(function(component)
            if component.on_base_generated then
                component:on_base_generated()
            end
        end)
        base.force.print({"mobile_factory.base_created", base:get_name()})
    else
        game.print({"mobile_factory.base_destroyed_before_created", base:get_name()})
    end
end

--- 检查给定中心的块是否已经生成完成
function Generator:is_base_chunks_generated()
    return not U.find_chunk_of_base(self.base, function(c_pos)
        return not self.base.surface.is_chunk_generated(c_pos)
    end)
end

--- 生成地基
function Generator:generate_base_tiles()
    local base = self.base
    local tiles = {}

    local area = U.get_base_area(base, true)
    for pos in area:iterate(true, true) do
        Table.insert(tiles, { name = BASE_TILE, position = pos})
    end
    base.surface.set_tiles(tiles)
end

--- 生成出口，基地内建筑
function Generator:generate_base_entities()
    self:create_exit_entity()
    self:generate_hyper_space_power_connection()
end

function Generator:create_exit_entity()
    local base = self.base
    local exit_point = base.center
    local exit_entity = base.surface.create_entity({
        name = BASE_VEHICLE_NAME, position = exit_point, force = base.force
    })
    exit_entity.minable = false
    exit_entity.destructible = false
    --exit_entity.active = false
    Entity.set_data(exit_entity, {base_id = base:get_id()})
    base.exit_entity = exit_entity
end

--- 超空间电力传输
function Generator:generate_hyper_space_power_connection()
    local base = self.base
    local substation_position = Position(base.exit_entity.position)
    local power_surface = game.surfaces[Config.POWER_SURFACE_NAME]

    -- 空间电站
    base.hyper_substation = power_surface.create_entity({name="substation", position = substation_position, force = base.force})
    Entity.set_indestructible(base.hyper_substation, true)

    -- 空间电力接口
    base.hyper_accumulator = power_surface.create_entity({
        name = "electric-energy-interface",
        position = substation_position + {0,2},
        force = base.force
    })
    Entity.set_indestructible(base.hyper_accumulator, true)
    base.hyper_accumulator.electric_buffer_size = Config.BASE_ELECTRIC_BUFFER_SIZE
    base.hyper_accumulator.power_production = Config.BASE_POWER_PRODUCTION
    base.hyper_accumulator.power_usage = 0

    -- 基地信息输出
    base.hyper_combinator = power_surface.create_entity({
        name="constant-combinator",
        position = substation_position + {0, -2},
        force = base.force
    })
    Entity.set_indestructible(base.hyper_combinator, true)
    Entity.connect_neighbour(base.hyper_combinator, base.hyper_substation, "green")
    base.hyper_combinator.get_or_create_control_behavior()

    -- 基地电站
    base.base_substation = U.create_system_entity(base, "substation", base.center)
    base.base_substation.operable = false
    Entity.connect_neighbour(base.base_substation, base.hyper_substation, "all")
end

--- 填充基地空间间隙
local function fill_out_of_map_tiles(surface, area)
    if area.right_bottom.y < Config.BASE_OUT_OF_MAP_Y then return end
    local tiles = {}
    for pos in Area(area):iterate(true, true) do
    --for pos in Area(area):iterate(true, false) do
        Table.insert(tiles, {name = 'out-of-map', position = pos})
    end
    surface.set_tiles(tiles)
end

function Generator:on_destroy()
    local base = self.base
    base.team_center:free_base_position_index(self.base_position_index)

    -- 消除基地数据
    if base.exit_entity then
        Entity.set_data(base.exit_entity)
    end
    -- 删除基地块
    local area = Area.expand(U.get_base_area(base, true), 16)
    local power_surface = game.surfaces[Config.POWER_SURFACE_NAME]
    Chunk.each_from_area(area, true, function(c_pos)
        base.surface.delete_chunk(c_pos)
        power_surface.delete_chunk(c_pos)
    end)
end

Event.register(defines.events.on_chunk_generated, function(event)
    -- 如果有多表面，需要判断是不是大地图表面
    if event.surface == game.surfaces[Config.GAME_SURFACE_NAME] then
        fill_out_of_map_tiles(event.surface, event.area)
    end
end)

Event.on_init(function()
    local surface = game.create_surface(Config.POWER_SURFACE_NAME)
    surface.generate_with_lab_tiles = true
    surface.always_day = true
end)

return Generator
