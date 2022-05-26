local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local ColorList = require 'stdlib/utils/defines/color_list'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'

local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player'
local Team = require 'scenario/mobile_factory/team'
local U = require 'scenario/mobile_factory/mobile_base_utils'

local MobileBaseStateController = KC.class('scenario.MobileFactory.MobileBaseStateController', function(self, base)
    self:set_base(base)
    self:render_state_text()
    self:update_online_state()
end)

MobileBaseStateController:reference_objects('base')

--------------------------------------------------------------------------------
--- 更新状态文本
--------------------------------------------------------------------------------

function MobileBaseStateController:render_state_text()
    local base = self:get_base()
    self.red_state_text_id = U.draw_state_text(base, {
        target_offset = {0, -6},
        color = ColorList.red,
    })
    self.yellow_state_text_id = U.draw_state_text(base,{
        target_offset = {0, -5},
        color = ColorList.yellow,
    })
    self.green_state_text_id = U.draw_state_text(base,{
        target_offset = {0, -4},
        color = ColorList.green,
    })
end

function MobileBaseStateController:update_state_text()
    local base = self:get_base()
    U.update_state_text(self.red_state_text_id, {
        {base.heavy_damaged, {"mobile_factory.state_text_heavy_damaged"}}
    })
    U.update_state_text(self.yellow_state_text_id, {
        {not base.online, {"mobile_factory.state_text_offline"}}
    })
    U.update_state_text(self.green_state_text_id, {
        {base.working_state == Config.BASE_WORKING_STATE_STATION, {"mobile_factory.state_text_station"}},
        {base.working_state == Config.BASE_WORKING_STATE_MOVING, {"mobile_factory.state_text_moving"}},
        {base.working_state == Config.BASE_WORKING_STATE_TRAIN, {"mobile_factory.state_text_train"}}
    })
end

--------------------------------------------------------------------------------
--- 工作状态转换
--------------------------------------------------------------------------------

function MobileBaseStateController:toggle_working_state()
    local base = self:get_base()
    if not self:can_set_working_state() then
        self:get_base().force.print({"mobile_factory.base_working_state_locked"})
        return
    end
    local state = base.working_state
    if state == Config.BASE_WORKING_STATE_TRAIN then
        self:_set_working_state_moving()
    elseif state == Config.BASE_WORKING_STATE_MOVING then
        if self:_can_set_working_state_train() then
            self:_set_working_state_train()
        elseif self:_can_set_working_state_station() then
            self:_set_working_state_station()
        else
            base.force.print({"mobile_factory.cannot_toggle_base_working_state"})
        end
    elseif state == Config.BASE_WORKING_STATE_STATION then
        self:_set_working_state_moving()
    end
    self:update_state_text()
end


function MobileBaseStateController:set_working_state(state)
    if not self:can_set_working_state() then
        self:get_base().force.print({"mobile_factory.base_working_state_locked"})
        return
    end
    if state == Config.BASE_WORKING_STATE_STATION then
        if self:_can_set_working_state_station() then
            self:_set_working_state_station()
        end
    elseif state == Config.BASE_WORKING_STATE_MOVING then
        self:_set_working_state_moving()
    elseif state == Config.BASE_WORKING_STATE_TRAIN then
        if self:_can_set_working_state_train() then
            self:_set_working_state_train()
        end
    end
    self:update_state_text()
end

function MobileBaseStateController:can_set_working_state()
    local base = self:get_base()
    return base.generated and base.online and not base.heavy_damaged
end

function MobileBaseStateController:_can_set_working_state_station()
    -- 周围有 16*16 的空间
    local base = self:get_base()
    local entities = base.vehicle.surface.find_entities_filtered({
        position = base.vehicle.position,
        radius = Config.BASE_STATION_RADIUS,
        collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile"}
    })
    local can = not Table.find(entities, function(entity)
        return entity.type ~= 'spider-leg'
    end)
    if can then
        local tiles = base.vehicle.surface.find_tiles_filtered({
            position = base.vehicle.position,
            radius = Config.BASE_STATION_RADIUS,
            collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile"}
        })
        return Table.is_empty(tiles)
    else
        return false
    end
end

function MobileBaseStateController:_set_working_state_station()
    local base = self:get_base()
    base.working_state = Config.BASE_WORKING_STATE_STATION
    base.station_position = base.vehicle.position
    Event.raise_event(Config.ON_BASE_CHANGED_WORKING_STATE, {
        base_id = base:get_id()
    })
end

function MobileBaseStateController:_set_working_state_moving()
    local base = self:get_base()
    base.working_state = Config.BASE_WORKING_STATE_MOVING
    Event.raise_event(Config.ON_BASE_CHANGED_WORKING_STATE, {
        base_id = base:get_id()
    })
end

function MobileBaseStateController:_can_set_working_state_train()
    return false
end

function MobileBaseStateController:_set_working_state_train()
    local base = self:get_base()
    base.working_state = Config.BASE_WORKING_STATE_TRAIN
    self:get_base().force.print("training mobile base is not support currently")
end

function MobileBaseStateController:update_vehicle_active()
    local base = self:get_base()
    base.vehicle.active = base.online and not base.heavy_damaged
end

--------------------------------------------------------------------------------
--- 定时更新状态
--------------------------------------------------------------------------------

function MobileBaseStateController:run()
    self:update_heavy_damaged()
end

function MobileBaseStateController:update_heavy_damaged()
    local base = self:get_base()
    local health_ratio = base.vehicle.get_health_ratio()
    if health_ratio >= Config.BASE_RECOVER_THRESHOLD then
        if base.heavy_damaged then
            base.heavy_damaged = false
            base.recovering = true
            self:update_vehicle_active()
            self:update_state_text()
        else
            base.recovering = false
        end
    elseif health_ratio <= Config.BASE_HEAVY_DAMAGED_THRESHOLD then
        base.heavy_damaged = true
        base.recovering = false
        self:update_vehicle_active()
        self:update_state_text()
    end
end

function MobileBaseStateController:update_online_state()
    local base = self:get_base()
    base.online = base:get_team():is_online()
    if base.vehicle and base.vehicle.valid then
        -- 下线保护
        base.vehicle.destructible = base.online
        self:update_vehicle_active()
    end
    self:update_state_text()
end

Event.register(defines.events.on_player_left_game, function(event)
    local protected = 0 == #game.get_player(event.player_index).force.connected_players
    if protected then
        local base = Player.get(event.player_index):get_base()
        if base then
            base:get_state_controller():update_online_state()
        end
    end
end)

Event.register(defines.events.on_player_joined_game, function(event)
    local base = Player.get(event.player_index):get_base()
    if base then
        base:get_state_controller():update_online_state()
    end
end)

Event.register(Config.ON_PLAYER_JOINED_TEAM, function(event)
    local team = KC.get(event.team_id)
    local base = team:get_base()
    if base then
        base:get_state_controller():update_online_state()
    end
end)

Event.register(Config.ON_PLAYER_LEFT_TEAM, function(event)
    local team = KC.get(event.team_id)
    local base = team:get_base()
    if base then
        base:get_state_controller():update_online_state()
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
                local base = KC.get(entity_data.base_id)
                if not base:is_heavy_damaged() then
                    base:get_state_controller():update_heavy_damaged()
                end
                entity.health = entity.prototype.max_health * Config.BASE_MINIMAL_HEALTH_RATE
            end
        end
    end
end)

return MobileBaseStateController