local KC = require 'klib/container/container'
local ColorList = require 'stdlib/utils/defines/color_list'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'

local Config = require 'scenario/mobile_factory/config'
local Player = require 'scenario/mobile_factory/player'
local Team = require 'scenario/mobile_factory/team'

local MobileBaseStateController = KC.class('scenario.MobileFactory.MobileBaseStateController', function(self, base)
    self:set_base(base)
    self:render_base_state_text()
    self:update_online_state()
end)

MobileBaseStateController:refs('base')

function MobileBaseStateController:render_base_state_text()
    local base = self:get_base()
    self.red_state_text_id = rendering.draw_text {
        text = {"mobile_factory.state_text_offline"},
        surface = base.vehicle.surface,
        target = base.vehicle,
        target_offset = {0, -6},
        color = ColorList.red,
        scale = 1,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false,
        visible = false
    }
    self.yellow_state_text_id = rendering.draw_text {
        text = {"mobile_factory.state_text_heavy_damaged"},
        surface = base.vehicle.surface,
        target = base.vehicle,
        target_offset = {0, -5},
        color = ColorList.yellow,
        scale = 1,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false,
        visible = false
    }
end

function MobileBaseStateController:update_base_state_text()
    local base = self:get_base()
    local red_text = {""}
    if base.heavy_damaged then
        table.insert(red_text, '[')
        table.insert(red_text, {"mobile_factory.state_text_heavy_damaged"})
        table.insert(red_text, ']')
    end
    if next(red_text) then
        rendering.set_text(self.red_state_text_id, red_text)
        rendering.set_visible(self.red_state_text_id, true)
    else
        rendering.set_visible(self.red_state_text_id, false)
    end

    local yellow_text = {""}
    if not base.online then
        table.insert(yellow_text, '[')
        table.insert(yellow_text, {"mobile_factory.state_text_offline"})
        table.insert(yellow_text, ']')
    end
    if next(yellow_text) then
        rendering.set_text(self.yellow_state_text_id, yellow_text)
        rendering.set_visible(self.yellow_state_text_id, true)
    else
        rendering.set_visible(self.yellow_state_text_id, false)
    end
end

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
            self:update_base_state_text()
        else
            base.recovering = false
        end
    elseif health_ratio <= Config.BASE_HEAVY_DAMAGED_THRESHOLD then
        base.heavy_damaged = true
        base.recovering = false
        Entity.set_frozen(base.vehicle, true)
        base.vehicle.operable = true
        self:update_base_state_text()
    end
end

function MobileBaseStateController:update_online_state()
    local base = self:get_base()
    base.online = base:get_team():is_online()
    if base.vehicle then
        -- 下线保护
        base.vehicle.destructible = base.online
    end
    self:update_base_state_text()
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

Event.register(Config.ON_PLAYER_JOINED_TEAM_EVENT, function(event)
    local team = KC.get(event.team_id)
    local base = team:get_base()
    if base then
        base:get_state_controller():update_online_state()
    end
end)

Event.register(Config.ON_PLAYER_LEFT_TEAM_EVENT, function(event)
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