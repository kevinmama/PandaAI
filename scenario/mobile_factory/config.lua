local Table = require 'klib/utils/table'
local Time = require 'stdlib/utils/defines/time'
local Event = require 'klib/event/event'

local C = {}

C.DEBUG = __DEBUG__

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
    ["construction-robot"] = 40,
    ["spidertron-remote"] = 1,
    ["discharge-defense-remote"] = 1,
}

C.Player_INIT_GRID_ITEMS = {
    ["modular-armor"] = 1,
    ["personal-roboport-equipment"] = 2,
    ["battery-mk2-equipment"] = 1,
    ["solar-panel-equipment"] = 15
}

C.SPIDER_INIT_AMMO = {
    ["explosive-rocket"] = 100
}

C.SPIDER_INIT_ITEMS = {
    ["repair-pack"] = 100,
    --["roboport"] = 1,
    ["construction-robot"] = 10,
    --["logistic-robot"] = 10,
}

C.SPIDER_INIT_GRID_ITEMS = {
    ["personal-roboport-equipment"] = 1,
    ["personal-laser-defense-equipment"] = 2,
    ["discharge-defense-equipment"] = 1,
    ["battery-mk2-equipment"] = 2,
    ["energy-shield-equipment"] = 10,
    --["solar-panel-equipment"] = 20
}

C.DEBUG_INIT_ITEMS = {
    ["rocket-launcher"] = 1,
    ["atomic-bomb"] = 10,
    ["nuclear-fuel"] = 3,
    ["spidertron"] = 5,
    ["electric-energy-interface"] = 2,
    ["infinity-pipe"] = 10,
    ["substation"] = 50,
    ["explosive-rocket"] = 2000,
    ["cliff-explosives"] = 40,
    ["stone-brick"] = 100,
    ["red-wire"] = 200,
    ["green-wire"] = 200,
}

if C.DEBUG then
    Table.merge(C.PLAYER_INIT_ITEMS, C.DEBUG_INIT_ITEMS)
end

C.GAME_SURFACE_NAME = "nauvis"
C.POWER_SURFACE_NAME = "power"

local CHUNK_SIZE = 32
C.CHUNK_SIZE = CHUNK_SIZE
local STARTING_AREA_RADIUS = 6
C.STARTING_AREA = {
    left_top = { x = STARTING_AREA_RADIUS * CHUNK_SIZE, y = STARTING_AREA_RADIUS * CHUNK_SIZE },
    right_bottom = { x = STARTING_AREA_RADIUS * CHUNK_SIZE, y = STARTING_AREA_RADIUS * CHUNK_SIZE }
}
C.BASE_VEHICLE_NAME = "spidertron"
-- 虚空区域分界线
C.BASE_OUT_OF_MAP_Y = 500 * CHUNK_SIZE
-- 基地区域分界线
C.BASE_POSITION_Y = C.BASE_OUT_OF_MAP_Y + 100 * CHUNK_SIZE
-- 基地最大尺寸
C.BASE_MAXIMAL_DIMENSIONS = { width = 5 * CHUNK_SIZE, height = 5 * CHUNK_SIZE}
-- 基地原始大小
C.BASE_DEFAULT_DIMENSIONS = { width = 2 * CHUNK_SIZE, height = 2 * CHUNK_SIZE}
-- 基地间隔
C.GAP_DIST = 4 * CHUNK_SIZE
-- 基地地块
C.BASE_TILE = 'refined-concrete'
-- 基地运行间隔
C.BASE_UPDATE_INTERVAL = 300
-- 基地运行组数
C.BASE_UPDATE_SLOT = 10
-- 资源折跃开始时间
C.RESOURCE_WARPING_BOOT_TIME = 10 * Time.second
-- 资源折跃半径
C.RESOURCE_WARPING_DIMENSIONS = {width=CHUNK_SIZE, height=CHUNK_SIZE}
-- 资源折跃率表
C.RESOURCE_WARP_RATE_TABLE = {2,5,10}
-- 资源折跃无限科技乘数
C.RESOURCE_WARP_RATE_MULTIPLIER = 10
-- 资源折跃污染乘数
C.RESOURCE_WARP_POLLUTION_MULTIPLIER = 0.25
-- 创建资源点最小数量
C.RESOURCE_WARP_OUT_MIN_AMOUNT = 1000
-- 资源点
C.RESOURCE_WARP_OUT_POINT_LIMIT = 250
-- 初始资源
C.BASE_INIT_RESOURCE_AMOUNT = {
    ["iron-ore"] = 200000,
    --["iron-ore"] = 1001,
    ["copper-ore"] = 100000,
    ["coal"] = 100000,
    ["stone"] = 100000,
    ["uranium-ore"] = 0,
    ["crude-oil"] = 0,
}

-- 基地内属性加成
C.BASE_RUNNING_SPEED_MODIFIER = 2
C.BASE_REACH_DISTANCE_BONUS = C.GAP_DIST
C.BASE_BUILD_DISTANCE_BONUS = C.GAP_DIST

-- 基地发电量
C.BASE_POWER_PRODUCTION = 1000000/60
-- 基地电容量
C.BASE_ELECTRIC_BUFFER_SIZE = 1000000000
-- 玩家充电距离
C.PLAYER_RECHARGE_DISTANCE = 8
-- 基础机器人加速
C.WORKER_ROBOTS_SPEED_MODIFIER = 4
-- 激进离线保护启动时间
C.ACTIVE_OFFLINE_PROTECTION_TIME = 30 * Time.minute

--------------------------------------------------------------------------------
--- 注册表
--------------------------------------------------------------------------------

C.REG_PLAYER = "players"
C.REG_TEAM = "teams"
C.REG_TEAM_CENTER = "team_centers"

--------------------------------------------------------------------------------
--- 载具命令列表
--------------------------------------------------------------------------------
C.ORDER_MOVE = 1
C.ORDER_FOLLOW = 2

--------------------------------------------------------------------------------
--- 常用类名
--------------------------------------------------------------------------------

C.PACKAGE_PREFIX = 'scenario.MobileFactory.'
C.PACKAGE_PLAYER_PREFIX = C.PACKAGE_PREFIX .. 'player.'
C.PACKAGE_BASE_PREFIX = C.PACKAGE_PREFIX .. 'base.'
C.PACKAGE_BASE_GUI_PREFIX = C.PACKAGE_PREFIX .. 'base_gui.'

--------------------------------------------------------------------------------
--- 选择工具类型
--------------------------------------------------------------------------------
C.SELECTION_TYPE_CREATE_OUTPUT_RESOURCES = 1
C.SELECTION_TYPE_REMOVE_OUTPUT_RESOURCES = 2
C.SELECTION_TYPE_CREATE_WELL_PUMP = 3
C.SELECTION_TYPE_SELECT_BASE = 4

--------------------------------------------------------------------------------
--- 事件
--------------------------------------------------------------------------------

C.ON_PLAYER_JOINED_TEAM = Event.generate_event_name("on_player_join_team")
C.ON_PLAYER_LEFT_TEAM = Event.generate_event_name("on_player_left_team")
C.ON_PLAYER_ENTER_BASE = Event.generate_event_name("on_player_enter_base")
C.ON_PLAYER_LEFT_BASE = Event.generate_event_name("on_player_left_base")

C.ON_TEAM_CREATED = Event.generate_event_name("on_team_created")
C.ON_PRE_TEAM_DESTROYED = Event.generate_event_name("on_pre_team_destroyed")
C.ON_TEAM_DESTROYED = Event.generate_event_name("on_team_destroyed")
C.ON_TEAM_ONLINE = Event.generate_event_name("on_team_online")
C.ON_TEAM_OFFLINE = Event.generate_event_name("on_team_offline")

C.ON_BASE_CREATED = Event.generate_event_name("on_mobile_base_created")
C.ON_PRE_BASE_DESTROYED = Event.generate_event_name("on_pre_mobile_base_destroyed")
C.ON_BASE_CHANGED_WORKING_STATE = Event.generate_event_name("on_base_changed_working_state")
--C.ON_BASE_CHANGED_MOVING_STATE = Event.generate_event_name("on_base_moving_state_changed")
--C.ON_BASE_WARPED_RESOURCES = Event.generate_event_name("on_base_warped_resource")

return C