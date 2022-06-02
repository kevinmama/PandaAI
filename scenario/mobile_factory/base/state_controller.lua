local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'

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
end

function StateController:on_base_vehicle_died()
    self:update()
end

function StateController:update_state_text()
    self.base.vehicle_controller:update_state_text()
end

function StateController:update_vehicle_active()
    local base = self.base
    base.vehicle.active = base.online and not base.heavy_damaged
end

function StateController:update_heavy_damaged()
    local base = self.base
    local ratio = base.vehicle.get_health_ratio()
    if ratio == 1 then
        base.heavy_damaged = false
        self:update_vehicle_active()
        self:update_state_text()
    elseif base.vehicle.health == 0 then
        base.heavy_damaged = true
        self:update_vehicle_active()
        self:update_state_text()
    end
end

function StateController:update_online_state()
    local base = self.base
    base.online = base.team:is_online()
    if base.vehicle and base.vehicle.valid then
        -- 下线保护
        base.vehicle.destructible = base.online
        base.vehicle.operable = base.online
        self:update_vehicle_active()
        self:update_state_text()
    end
end

Event.register({ Config.ON_TEAM_ONLINE, Config.ON_TEAM_OFFLINE }, function(event)
    local team_center = TeamCenterRegistry.get_by_team_id(event.team_id)
    if team_center then
        for _, base in pairs(team_center.bases) do
            base.state_controller:update_online_state()
        end
    end
end)


return StateController