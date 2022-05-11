local KC = require 'klib/container/container'
local Dimension = require 'klib/gmo/dimension'
local Entity = require 'klib/gmo/entity'
local Area = require 'klib/gmo/area'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local ColorList = require 'stdlib/utils/defines/color_list'

local Config = require 'scenario/mobile_factory/config'
local MobileBaseGenerator = require 'scenario/mobile_factory/mobile_base_generator'
local MobileBaseResourceWarper = require 'scenario/mobile_factory/mobile_base_resource_warper'
local MobileBaseTeleporter = require 'scenario/mobile_factory/mobile_base_teleporter'
local MobileBasePolluter = require 'scenario/mobile_factory/mobile_base_polluter'
local MobileBasePowerController = require 'scenario/mobile_factory/mobile_base_power_controller'
local MobileBaseStateController = require 'scenario/mobile_factory/mobile_base_state_controller'
local Team = require 'scenario/mobile_factory/team'
local Player = require 'scenario/mobile_factory/player'

local MobileBase = KC.class(Config.CLASS_NAME_MOBILE_BASE, {
    next_index = 0,
    next_slot = 0
},function(self, team)
    self.index = self:get_next_index()
    self:set_next_index(self.index + 1)
    self.slot = self.index % Config.BASE_RUNNING_SLOT

    self:set_team(team)
    self.surface = game.surfaces[Config.GAME_SURFACE_NAME]
    self.force = team.force

    -- 基地状态
    self.generated = false
    self.destroyed = false
    self.online = true
    self.heavy_damaged = false
    self.recovering = false

    self.resource_amount = Table.deep_copy(Config.BASE_INIT_RESOURCE_AMOUNT)

    local generator = MobileBaseGenerator:new(self)
    self:set_generator(generator)
    self.center = generator:compute_base_center()
    self.vehicle = generator:create_base_vehicle()

    local resource_warper = MobileBaseResourceWarper:new(self)
    self:set_resource_warper(resource_warper)
    self.resource_locations = resource_warper:compute_resource_locations()

    self:set_teleporter(MobileBaseTeleporter:new(self))
    self:set_polluter(MobileBasePolluter:new(self))
    self:set_power_controller(MobileBasePowerController:new(self))
    self:set_state_controller(MobileBaseStateController:new(self))

    team.base_id = self:get_id()
    generator:generate()
    Event.raise_event(Config.ON_MOBILE_BASE_CREATED_EVENT, {
        base_id = self:get_id(),
        team_id = self.team_id
    })
end)

MobileBase:refs("team", "generator", "resource_warper", "teleporter", "polluter", "power_controller", 'state_controller')

--- 清理基地
function MobileBase:on_destroy()
    self.destroyed = true
    self:get_teleporter():destroy()
    self:get_power_controller():destroy()
    self:get_resource_warper():destroy()
    self:get_state_controller():destroy()
    self:get_generator():destroy()
end

function MobileBase.get_by_player_index(player_index)
    local team = Team.get_by_player_index(player_index)
    return team and team:get_base()
end

function MobileBase:get_name()
    return {"mobile_factory.base_name", self:get_team():get_name()}
end

function MobileBase:is_heavy_damaged()
    return self.heavy_damaged
end

function MobileBase:is_recovering()
    return self.recovering
end

function MobileBase:teleport_player_to_vehicle(player)
    self:get_teleporter():teleport_player_to_vehicle(player)
end

function MobileBase:teleport_player_to_base(player)
    self:get_teleporter():teleport_player_to_base(player)
end

function MobileBase:teleport_player_to_exit(player)
    self:get_teleporter():teleport_player_to_exit(player)
end

--- 已生成且成员在线
function MobileBase:can_run()
    return self.generated and self.online
end

function MobileBase:is_online()
    return self.online
end

function MobileBase:run()
    if self:can_run() then
        self:get_state_controller():run()
        self:get_resource_warper():run()
        self:get_polluter():run()
        self:get_power_controller():run()
    end
end

--- 运行各子模块
--- 为性能考虑，一次只处理少量基地
Event.on_nth_tick(Config.BASE_RUNNING_INTERVAL / Config.BASE_RUNNING_SLOT, function()
    local next_slot = MobileBase:get_next_slot()
    KC.for_each_object(MobileBase, function(base)
        if base.slot == next_slot then
            base:run()
        end
    end)
    next_slot = next_slot + 1
    if next_slot >= Config.BASE_RUNNING_SLOT then
        next_slot = next_slot % Config.BASE_RUNNING_SLOT
    end
    MobileBase:set_next_slot(next_slot)
end)

--- 只能控制自己的蜘蛛或无主的蜘蛛
Event.register(defines.events.on_player_configured_spider_remote, function(event)
    local entity_data = Entity.get_data(event.vehicle)
    local base = entity_data and KC.get(entity_data.base_id)
    if not base then return end
    local player = game.players[event.player_index]
    if base.team_id ~= Player.get(event.player_index).team_id then
        player.print({"mobile_factory.cannot_control_others_base"})
        player.cursor_stack.connected_entity = nil
    end
end)


function MobileBase:set_player_bonus(player)
    player.character_running_speed_modifier = Config.BASE_RUNNING_SPEED_MODIFIER
    player.character_reach_distance_bonus = Config.BASE_REACH_DISTANCE_BONUS
    player.character_build_distance_bonus = Config.BASE_BUILD_DISTANCE_BONUS
end

function MobileBase:reset_player_bonus(player)
    player.character_running_speed_modifier = 0
    player.character_reach_distance_bonus = 0
    player.character_build_distance_bonus = 0
end

return MobileBase
