local Table = require 'klib/utils/table'
local Time = require 'stdlib/utils/defines/time'
local Event = require 'klib/event/event'

local C = {}

--C.DEBUG = true

-- 秒退时间
C.RESET_TICKS_LIMIT = C.DEBUG and 15 * Time.second or 15 * Time.minute

C.PLAYER_INIT_ITEMS = {
    ["submachine-gun"] = 1 ,
    ["firearm-magazine"] = 100,
    ["small-electric-pole"] = 50,
    ["iron-plate"] = 100,
    ["copper-plate"] = 100,
    ["coal"] = 50,
    ["stone"] = 50,
    ["spidertron-remote"] = 1,
}

C.SPIDER_INIT_AMMO = {
    ["explosive-rocket"] = 100
}

C.SPIDER_INIT_ITEMS = {
    ["repair-pack"] = 100,
    ["roboport"] = 1,
    ["construction-robot"] = 10,
    ["logistic-robot"] = 10,
    ["discharge-defense-remote"] = 1
}

C.SPIDER_INIT_GRID_ITEMS = {
    ["personal-roboport-equipment"] = 1,
    ["personal-laser-defense-equipment"] = 2,
    ["discharge-defense-equipment"] = 1,
    ["battery-mk2-equipment"] = 2,
    ["energy-shield-equipment"] = 5,
    ["solar-panel-equipment"] = 20
}

C.DEBUG_INIT_ITEMS = {
    ["rocket-launcher"] = 1,
    ["atomic-bomb"] = 10,
    ["nuclear-fuel"] = 3,
    ["spidertron"] = 1,
    ["electric-energy-interface"] = 2,
    ["infinity-pipe"] = 10,
    ["substation"] = 50,
    ["explosive-rocket"] = 2000
}

if C.DEBUG then
    Table.merge(C.PLAYER_INIT_ITEMS, C.DEBUG_INIT_ITEMS)
end

C.GAME_SURFACE_NAME = "nauvis"
C.POWER_SURFACE_NAME = "power"

local CHUNK_SIZE = 32
C.CHUNK_SIZE = CHUNK_SIZE
C.BASE_VEHICLE_NAME = "spidertron"
-- 虚空区域分界线
C.BASE_OUT_OF_MAP_Y = 500 * CHUNK_SIZE
-- 基地区域分界线
C.BASE_POSITION_Y = C.BASE_OUT_OF_MAP_Y + 100 * CHUNK_SIZE
-- 基地大小
C.BASE_SIZE = {width = 14 * CHUNK_SIZE, height = 8 * CHUNK_SIZE}
-- 基地间隔
C.GAP_DIST = 4 * CHUNK_SIZE
-- 基地地块
C.BASE_TILE = 'refined-concrete'
-- 基地建筑
C.BASE_ENTITIES_BP = require 'scenario/mobile_factory/mobile_base_entity_blueprint_string'
-- 基地运行间隔
C.BASE_RUNNING_INTERVAL = 300
-- 基地运行组数
C.BASE_RUNNING_SLOT = 10
-- 资源折跃半径
C.RESOURCE_WARP_LENGTH = CHUNK_SIZE / 2
-- 吸取率
--C.RESOURCE_WARP_RATE = 25
C.RESOURCE_WARP_RATE_MULTIPLIER = 5
-- 资源名称
C.IRON_ORE = "iron-ore"
C.COPPER_ORE = "copper-ore"
C.COAL = "coal"
C.STONE = "stone"
C.URANIUM_ORE = "uranium-ore"
C.CRUDE_OIL = "crude-oil"
-- 资源大小
C.RESOURCE_PATCH_LENGTH = 2 * CHUNK_SIZE
C.RESOURCE_PATCH_SIZE = 4 * CHUNK_SIZE * CHUNK_SIZE
-- 初始资源
C.BASE_INIT_RESOURCE_AMOUNT = {
    [C.IRON_ORE] = 200000,
    [C.COPPER_ORE] = 100000,
    [C.COAL] = 100000,
    [C.STONE] = 100000,
    [C.URANIUM_ORE] = 0,
    [C.CRUDE_OIL] = 0
}

-- 基地内属性加成
C.BASE_RUNNING_SPEED_MODIFIER = 2
C.BASE_REACH_DISTANCE_BONUS = C.GAP_DIST
C.BASE_BUILD_DISTANCE_BONUS = C.GAP_DIST

-- 最小生命值
C.BASE_MINIMAL_HEALTH_RATE = 0.1
-- 重伤阀值
C.BASE_HEAVY_DAMAGED_THRESHOLD = 0.2
-- 恢复阀值
C.BASE_RECOVER_THRESHOLD = 0.8

-- 基地模式空间半径
C.BASE_STATION_RADIUS = 8
-- 基地发电量
C.BASE_POWER_PRODUCTION = 1000000/60
-- 基地电容量
C.BASE_ELECTRIC_BUFFER_SIZE = 1000000000
-- 玩家充电距离
C.PLAYER_RECHARGE_DISTANCE = 8

--------------------------------------------------------------------------------
--- 常用类名
--------------------------------------------------------------------------------
C.CLASS_NAME_MOBILE_BASE = "scenario.MobileFactory.MobileBase"
C.CLASS_NAME_MAIN_TEAM = "scenario.MobileFactory.MainTeam"

C.ON_MOBILE_BASE_CREATED_EVENT = Event.generate_event_name("on_mobile_base_created")
C.ON_PLAYER_JOINED_TEAM_EVENT = Event.generate_event_name("on_player_join_team")
C.ON_PLAYER_LEFT_TEAM_EVENT = Event.generate_event_name("on_player_left_team")
C.ON_BASE_CHANGED_WORKING_STATE = Event.generate_event_name("on_base_changed_working_state")
C.ON_BASE_WARPED_RESOURCES = Event.generate_event_name("on_base_warped_resource")

C.BASE_WORKING_STATE_STATION = 1
C.BASE_WORKING_STATE_MOVING = 2
C.BASE_WORKING_STATE_TRAIN = 3
C.BASE_WORKING_STATES = { C.BASE_WORKING_STATE_STATION, C.BASE_WORKING_STATE_MOVING, C.BASE_WORKING_STATE_TRAIN}


return C