local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Config = require 'scenario/mobile_factory/config'
local IndexAllocator = require 'scenario/mobile_factory/utils/index_allocator'

local Team = require 'scenario/mobile_factory/player/team'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local Generator = require 'scenario/mobile_factory/base/generator'
local VehicleController = require 'scenario/mobile_factory/base/vehicle_controller'
local Teleporter = require 'scenario/mobile_factory/base/teleporter'
local WorkingState = require 'scenario/mobile_factory/base/working_state'
local StateController = require 'scenario/mobile_factory/base/state_controller'
local MovementController = require 'scenario/mobile_factory/base/movement_controller'
local ResourceWarpingController = require 'scenario/mobile_factory/base/resource_warping_controller'
local PollutionController = require 'scenario/mobile_factory/base/pollution_controller'
local PowerController = require 'scenario/mobile_factory/base/power_controller'

local MobileBase = KC.class(Config.PACKAGE_BASE_PREFIX .. 'MobileBase', {
    next_slot = 0,
    "slot_allocator", function()
        return {
            slot_allocator = IndexAllocator:new_local()
        }
    end
},function(self, team_center, vehicle_or_position)
    self.team_center = team_center
    self.team = team_center.team
    self.surface = game.surfaces[Config.GAME_SURFACE_NAME]
    self.force = self.team.force

    self.slot_index = self:get_slot_allocator():alloc()
    self.slot = self.slot_index % Config.BASE_UPDATE_SLOT

    -- 基地状态
    self.generated = false
    self.online = true
    self.heavy_damaged = false
    self.recovering = false
    self.working_state = WorkingState:new_local(self)

    self.moving = false
    -- 此状态开始时的游戏时间
    self.moving_tick = game.tick

    self.resource_amount = Table.deep_copy(Config.BASE_INIT_RESOURCE_AMOUNT)

    self.dimensions = Config.BASE_DEFAULT_DIMENSIONS
    self.generator = Generator:new_local(self)
    self.center = self.generator:compute_base_center()
    self.name = {"mobile_factory.base_name", self.team:get_name(), self.generator.base_position_index}

    self.vehicle_controller = VehicleController:new_local(self)
    self.vehicle = self.vehicle_controller:create(vehicle_or_position)
    -- 上次更新时车的位置
    self.last_vehicle_position = self.vehicle.position
    self.deploy_position = nil

    self.state_controller = StateController:new_local(self)
    self.movement_controller = MovementController:new_local(self)
    self.resource_warping_controller = ResourceWarpingController:new_local(self)
    self.pollution_controller = PollutionController:new_local(self)
    self.power_controller = PowerController:new_local(self)
    self.teleporter = Teleporter:new_local(self)

    self.generator:generate()
    -- 只有第一个基地给初始物品
    if not team_center.bases then
        U.give_base_initial_items(self)
    end
    Event.raise_event(Config.ON_BASE_CREATED, {
        base_id = self:get_id(),
        team_id = self.team:get_id()
    })
end)

MobileBase:delegate_method("working_state", "toggle", "toggle_working_state")
MobileBase:delegate_method("vehicle_controller", {
    "toggle_display_warp_resource_area",
    "toggle_display_deploy_area",
    "clear_deploy_area",
    "render_selection_marker"
})
MobileBase:delegate_method("power_controller", "recharge_equipment_for_character")
MobileBase:delegate_method("resource_warping_controller", {
    "create_output_resources",
    "remove_output_resources",
    "create_well_pump",
    "toggle_warping_in_resources",
    "is_enable_warping_in_resources",
    "is_warping_in_resources",
    "get_output_resources_count",
})

MobileBase:delegate_method("teleporter", {
    "teleport_player_to_vehicle",
    "teleport_player_to_center",
    "teleport_player_to_exit",
    "teleport_player_on_respawned",
})
MobileBase:delegate_method("movement_controller", {
    "move_to_position",
    "follow_target"
})

function MobileBase:get_components()
    return {
        self.generator, self.state_controller, self.working_state, self.vehicle_controller,
        self.movement_controller, self.resource_warping_controller, self.power_controller,
        self.pollution_controller, self.teleporter
    }
end

function MobileBase:for_each_components(func, reverse)
    if not reverse then
        Table.each(self:get_components(), func)
    else
        Table.array_each_reverse(self:get_components(), func)
    end
end

--- 清理基地
function MobileBase:on_destroy()
    Event.raise_event(Config.ON_PRE_BASE_DESTROYED, {
        base_id = self:get_id()
    })
    ---- TODO 清除 TeamCenter 实例
    self:get_slot_allocator():free(self.slot_index)
    self:for_each_components(function(component)
        component:destroy()
    end, true)

    -- 用来测试哪个组件注销时会出错
    --local components = { self.generator, self.state_controller, self.working_state, self.vehicle_controller, self.movement_controller,
    --    self.resource_warping_controller, self.power_controller, self.pollution_controller, self.teleporter }
    --for i = #components, 1, -1 do components[i]:destroy() end
end

MobileBase.get_by_vehicle = U.get_base_by_vehicle
MobileBase.get_by_controller = U.get_controlling_base_by_player
MobileBase.get_by_visitor = U.get_visiting_base_by_player
MobileBase.find_bases_in_area = U.find_bases_in_area

function MobileBase:get_name()
    return self.name
end

function MobileBase:set_name(name)
    self.name = name
    self.vehicle_controller:update_base_name()
end

function MobileBase:can_rename(player)
    -- 主队任何人可改，私有团队仅团长可改
    if self.team.captain == player then
        return true
    elseif self.team:is_main_team() then
        return Team.get_id_by_player_index(player.index) == self.team:get_id()
    else
        return false
    end
end

function MobileBase:get_working_state_label()
    return {"mobile_factory.working_state_text_" .. self.working_state.current}
end

function MobileBase:is_heavy_damaged()
    return self.heavy_damaged
end

function MobileBase:is_recovering()
    return self.recovering
end

--- 已生成且成员在线
function MobileBase:can_update()
    return self.generated and self.online
end

function MobileBase:is_online()
    return self.online
end

function MobileBase:update()
    if self:can_update() then
        self:for_each_components(function(component)
            if component.update then
                component:update()
            end
        end)
    end
end

--- 运行各子模块
--- 为性能考虑，一次只处理少量基地
Event.on_nth_tick(Config.BASE_UPDATE_INTERVAL / Config.BASE_UPDATE_SLOT, function()
    local next_slot = MobileBase:get_next_slot()
    KC.for_each_object(MobileBase, function(base)
        if base.slot == next_slot then
            base:update()
        end
    end)
    next_slot = next_slot + 1
    if next_slot >= Config.BASE_UPDATE_SLOT then
        next_slot = next_slot % Config.BASE_UPDATE_SLOT
    end
    MobileBase:set_next_slot(next_slot)
end)

MobileBase:on(defines.events.on_tick, function(self)
    self.movement_controller:update_movement()
end)

-- 不同团队的蜘蛛不能互相控制，个人蜘蛛？
--- 只能控制自己的蜘蛛或无主的蜘蛛
--Event.register(defines.events.on_player_configured_spider_remote, function(event)
--    local base = MobileBase.get_by_vehicle(event.vehicle)
--    if not base then return end
--    local player = game.players[event.player_index]
--    if base.team.id ~= Player.get(event.player_index).team.id then
--        player.print({"mobile_factory.cannot_control_others_base"})
--        player.cursor_stack.connected_entity = nil
--    end
--end)

return MobileBase
