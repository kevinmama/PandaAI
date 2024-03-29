local Table = require 'klib/utils/table'
local Time = require 'stdlib/utils/defines/time'
local Event = require 'klib/event/event'
local SelectionTool = require 'klib/gmo/selection_tool'

local C = {}

C.DEBUG = __DEBUG__

C.NORMAL_MODE = true
--C.COOP_MODE = true
-- 保卫战模式(Defend Mode)
--C.DEFEND_MODE = true
--C.FAST_MODE = true

C.JOIN_MAIN_TEAM_BY_DEFAULT = true
C.ALLOW_CREATE_TEAM = true
C.ALLOW_RESET = true
--C.SOFT_RESET = false
C.ROBOT_START = false
C.HEAVY_ARMORED = false

if C.TEAM_MODE then
    C.JOIN_MAIN_TEAM_BY_DEFAULT = false
    C.ALLOW_CREATE_TEAM = true
    C.ALLOW_RESET = true
    C.ROBOT_START = true
    C.HEAVY_ARMORED = true
    --C.SOFT_RESET = false
end

if C.DEFEND_MODE then
    C.JOIN_MAIN_TEAM_BY_DEFAULT = true
    C.ALLOW_CREATE_TEAM = false
    C.ALLOW_RESET = false
    C.ROBOT_START = false
    C.HEAVY_ARMORED = false
    --C.SOFT_RESET = true
end

if C.FAST_MODE then
    C.JOIN_MAIN_TEAM_BY_DEFAULT = true
    C.ALLOW_CREATE_TEAM = true
    C.ALLOW_RESET = true
    C.ROBOT_START = true
    C.HEAVY_ARMORED = true
end

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

if C.ROBOT_START or C.DEBUG then
    Table.added(C.PLAYER_INIT_ITEMS, {
        ["construction-robot"] = 40,
        ["modular-armor"] = 1,
        ["personal-roboport-equipment"] = 2,
        ["battery-mk2-equipment"] = 1,
        ["solar-panel-equipment"] = 15
    })
end

if C.HEAVY_ARMORED then
    Table.added(C.PLAYER_INIT_ITEMS, {
        ["discharge-defense-remote"] = 1,
    })
end

if C.FAST_MODE then
    Table.added(C.PLAYER_INIT_ITEMS, {
        ["small-electric-pole"] = 100,
        ["medium-electric-pole"] = 100,
        ["substation"] = 50,
        ["iron-plate"] = 400,
        ["copper-plate"] = 400,
        ["coal"] = 200,
        ["stone"] = 200,
        ["steel-plate"] = 200,
        ["electronic-circuit"] = 400
    })
end

C.SPIDER_INIT_ITEMS = {
    ["explosive-rocket"] = 100,
    ["repair-pack"] = 100,
    ["energy-shield-equipment"] = 2,
    ["personal-laser-defense-equipment"] = 2,
    ["battery-mk2-equipment"] = 2,
}

if C.HEAVY_ARMORED then
    Table.added(C.SPIDER_INIT_ITEMS, {
        ["discharge-defense-equipment"] = 1,
        ["energy-shield-equipment"] = 8,
    })
end

if C.ROBOT_START or C.DEBUG then
    Table.added(C.SPIDER_INIT_ITEMS, {
        ["construction-robot"] = 10,
        ["personal-roboport-equipment"] = 1,
    })
end

if C.DEBUG then
    Table.added(C.PLAYER_INIT_ITEMS, {
        ["rocket-launcher"] = 1,
        ["atomic-bomb"] = 10,
        ["nuclear-fuel"] = 3,
        ["spidertron"] = 5,
        ["electric-energy-interface"] = 2,
        ["infinity-pipe"] = 10,
        ["substation"] = 50,
        ["explosive-rocket"] = 200,
        ["cliff-explosives"] = 40,
        ["stone-brick"] = 100,
        ["red-wire"] = 200,
        ["green-wire"] = 200,
        ["rail"] = 100,
        ["locomotive"] = 5,
        ["cargo-wagon"] = 5,
        ["train-stop"] = 10,
        ["transport-belt"] = 100,
        ["underground-belt"] = 50,
    })

    Table.added(C.SPIDER_INIT_ITEMS, {
        ["explosive-rocket"] = 2000
    })
end

C.GAME_SURFACE_NAME = "nauvis"
C.ALT_SURFACE_NAME = "alt"

local CHUNK_SIZE = 32
C.CHUNK_SIZE = CHUNK_SIZE
C.STARTING_AREA_DIMENSIONS = {width=8*32, height=8*32}
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
C.BASE_UPDATE_SLOT = 60
-- 基地重伤传送延迟
C.BASE_UNSTUCK_DELAY = 10 * Time.minute
-- 进入坐下状态时间（可折跃矿石或交换资源）
C.BASE_SITTING_DELAY = 10 * Time.second
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
-- 创建液体最小数量
C.FLUID_RESOURCE_WARP_OUT_MIN_AMOUNT_MULTIPLIER = 0.2
-- 资源点
C.RESOURCE_WARP_OUT_POINT_LIMIT = 250
-- 初始资源
C.BASE_INIT_RESOURCE_AMOUNT = {
    ["iron-ore"] = 200000,
    ["copper-ore"] = 100000,
    ["coal"] = 100000,
    ["stone"] = 100000,
    ["uranium-ore"] = 0,
    ["crude-oil"] = 200 * 3000
}

if C.FAST_MODE then
    Table.added(C.BASE_INIT_RESOURCE_AMOUNT, {
        ["iron-ore"] = 2000000,
        ["copper-ore"] = 1000000,
        ["coal"] = 1000000,
        ["stone"] = 1000000,
        ["uranium-ore"] = 1000000,
        ["crude-oil"] = 4800 * 3000
    })
end

-- 固体资源交换速度
C.SOLID_RESOURCE_EXCHANGE_RATE = 100000
-- 液体资源交换速度
C.FLUID_RESOURCE_EXCHANGE_RATE = 300000
-- 能量交换速度
C.POWER_EXCHANGE_RATE = 2500000000
-- 最大连接带数
C.MAXIMAL_LINKED_BELT_PAIRS = 15

-- 基地内属性加成
C.BASE_RUNNING_SPEED_MODIFIER = 2
C.BASE_REACH_DISTANCE_BONUS = C.GAP_DIST
C.BASE_BUILD_DISTANCE_BONUS = C.GAP_DIST

-- 基地发电量
C.BASE_POWER_PRODUCTION = 1000000/60
-- 基地电容量
C.BASE_ELECTRIC_BUFFER_SIZE = 10000000000
-- 玩家充电距离
C.PLAYER_RECHARGE_DISTANCE = 8
-- 附近基地范围
C.PLAYER_NEAR_BASE_DISTANCE = 32
-- 基础机器人加速
C.WORKER_ROBOTS_SPEED_MODIFIER = 4
-- 激进离线保护启动时间
C.ACTIVE_OFFLINE_PROTECTION_TIME = 30 * Time.minute
-- 玩家角色存放点
C.CHARACTER_PRESERVING_SURFACE_NAME = C.ALT_SURFACE_NAME
C.CHARACTER_PRESERVING_POSITION = {x=0, y=0}
C.CHARACTER_PRESERVING_RADIUS = 4 * CHUNK_SIZE

C.get_spawn_position = function()
    return {x=math.random(-CHUNK_SIZE, CHUNK_SIZE), y=math.random(-CHUNK_SIZE, CHUNK_SIZE)}
end

C.EXTRA_BASES = 0
C.MAIN_TEAM_EXTRA_BASES = 2

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
C.PACKAGE_PLAYER_GUI_PREFIX = C.PACKAGE_PLAYER_PREFIX .. 'player_gui.'
C.PACKAGE_BASE_PREFIX = C.PACKAGE_PREFIX .. 'base.'
C.PACKAGE_BASE_GUI_PREFIX = C.PACKAGE_PREFIX .. 'base_gui.'

--------------------------------------------------------------------------------
--- 选择工具类型
--------------------------------------------------------------------------------
C.SELECTION_TYPE_CREATE_OUTPUT_RESOURCES = SelectionTool.generate_type_id()
C.SELECTION_TYPE_REMOVE_OUTPUT_RESOURCES = SelectionTool.generate_type_id()
C.SELECTION_TYPE_CREATE_WELL_PUMP = SelectionTool.generate_type_id()
C.SELECTION_TYPE_SELECT_BASE = SelectionTool.generate_type_id()
C.SELECTION_TYPE_TELEPORT_BASE = SelectionTool.generate_type_id()
C.SELECTION_TYPE_BUILD_LINKED_BELT = SelectionTool.generate_type_id()
C.SELECTION_TYPE_REMOVE_LINKED_BELT = SelectionTool.generate_type_id()

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
C.ON_BASE_CHANGED_WORKING_STATE = Event.generate_event_name("on_mobile_base_changed_working_state")
--C.ON_BASE_CHANGED_MOVING_STATE = Event.generate_event_name("on_base_moving_state_changed")
--C.ON_BASE_WARPED_RESOURCES = Event.generate_event_name("on_base_warped_resource")
C.ON_BASE_VEHICLE_DIED = Event.generate_event_name("on_mobile_base_vehicle_died")

return C