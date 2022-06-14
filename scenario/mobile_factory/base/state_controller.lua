local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Position = require 'klib/gmo/position'

local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player/player'
local Team = require 'scenario/mobile_factory/player/team'
local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local TeamCenterRegistry = require 'scenario/mobile_factory/base/team_center_registry'

local StateController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'MobileBaseStateController', function(self, base)
    self.base = base
    self:update_online_state()
end)

--------------------------------------------------------------------------------
--- 定时更新状态
--------------------------------------------------------------------------------

function StateController:update()
    self:update_heavy_damaged()
    self:update_moving_state()
end

function StateController:on_base_vehicle_died()
    self:update()
end

function StateController:update_state_text()
    self.base.vehicle_controller:update_state_text()
end

function StateController:update_moving_state()
    local base = self.base
    local vehicle_position = base.vehicle.position
    local moving = not Position.equals(vehicle_position, base.last_vehicle_position)
    if moving then
        base.last_vehicle_position = vehicle_position
        base.sitting = false
    elseif not base.sitting and game.tick >= base.moving_tick + Config.BASE_SITTING_DELAY then
        base.sitting = true
    end
    if moving ~= base.moving then
        base.moving = moving
        base.moving_tick = game.tick
    end
end

function StateController:update_vehicle_active()
    local base = self.base
    base.vehicle.active = base.online and not base.heavy_damaged
end

function StateController:update_heavy_damaged()
    local base = self.base
    local ratio = base.vehicle.get_health_ratio()
    if base.heavy_damaged and ratio == 1 then
        base.heavy_damaged = false
        self:update_vehicle_active()
        self:update_state_text()
    elseif base.vehicle.health == 0 then
        if not base.heavy_damaged then
            base.heavy_damaged_tick = game.tick
            base.vehicle.destructible = false
        end
        base.heavy_damaged = true
        self:update_vehicle_active()
        self:update_state_text()
    else
        base.vehicle.destructible = base.online
    end
end

function StateController:update_online_state()
    local base = self.base
    base.online = base.team:is_online()
    if base.vehicle and base.vehicle.valid then
        -- 下线保护
        if base.vehicle.health > 0 then
            base.vehicle.destructible = base.online
        end
        base.vehicle.operable = base.online
        self:update_vehicle_active()
        self:update_state_text()
    end
end

Event.register({ Config.ON_TEAM_ONLINE, Config.ON_TEAM_OFFLINE }, function(event)
    local team_center = TeamCenterRegistry.get_by_team_id(event.team_id)
    if team_center then
        local active_offline_protection = event.last_online and (game.tick - event.last_online) >= Config.ACTIVE_OFFLINE_PROTECTION_TIME
        for _, base in pairs(team_center.bases) do
            base.state_controller:update_online_state()
            if active_offline_protection then
                base.vehicle_controller:clear_biters_in_deploy_area()
            end
        end
    end
end)


return StateController