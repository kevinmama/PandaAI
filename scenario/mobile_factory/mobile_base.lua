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
    self.generated = false
    self.destroyed = false
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

    team.base_id = self:get_id()
    generator:generate()
    self:render_base_status()
    Event.raise_event(Config.ON_MOBILE_BASE_CREATED_EVENT, {
        base_id = self:get_id(),
        team_id = self.team_id
    })
end)

MobileBase:refs("team", "generator", "resource_warper", "teleporter", "polluter", "power_controller")

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

function MobileBase:update_heavy_damaged()
    local health_ratio = self.vehicle.get_health_ratio()
    if health_ratio > Config.BASE_RECOVER_THRESHOLD then
        if self.heavy_damaged then
            self.heavy_damaged = false
            self.recovering = true
            rendering.set_visible(self.status_text_id, false)
        else
            self.recovering = false
        end
    elseif health_ratio < Config.BASE_HEAVY_DAMAGED_THRESHOLD then
        self.heavy_damaged = true
        self.recovering = false
        rendering.set_visible(self.status_text_id, true)
    end
end

function MobileBase:render_base_status()
    local base = self

    self.status_text_id = rendering.draw_text {
        text = {"mobile_factory.mobile_base_heavy_damaged"},
        surface = base.vehicle.surface,
        target = base.vehicle,
        target_offset = {0, -2.25},
        color = ColorList.red,
        scale = 1,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false,
        visible = false
    }
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
    return self.generated and self:get_team():is_online()
end

function MobileBase:run()
    if self:can_run() then
        self:update_heavy_damaged()
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

--- 基地不会死亡，但重伤后不能移动
-- FIXME 性能会很差，以后想办法改，或者改成死亡后换一只蜘蛛，避免每次被攻击都要判断
Event.register(defines.events.on_entity_damaged, function(event)
    local entity = event.entity
    if entity.name == Config.BASE_VEHICLE_NAME then
        local entity_data = Entity.get_data(entity)
        if entity_data and entity_data.base_id then
            if entity.get_health_ratio() < Config.BASE_MINIMAL_HEALTH_RATE then
                entity.health = event.final_health + event.final_damage_amount
                Entity.set_frozen(entity, true)
                entity.operable = true
            end
        end
    end
end)

--- 下线保护
Event.register(defines.events.on_player_left_game, function(event)
    local protected = 0 == #game.get_player(event.player_index).force.connected_players
    if protected then
        local base = MobileBase.get_by_player_index(event.player_index)
        if base and base.vehicle then
            base.vehicle.destructible = false
        end
    end
end)

Event.register(defines.events.on_player_joined_game, function(event)
    local base = MobileBase.get_by_player_index(event.player_index)
    if base and base.vehicle then
        base.vehicle.destructible = true
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

--- 清理基地
function MobileBase:on_destroy()
    self.destroyed = true
    self:get_teleporter():destroy()
    self:get_resource_warper():destroy()
    self:get_generator():destroy()
end

return MobileBase
