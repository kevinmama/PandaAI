local KC = require 'klib/container/container'
local Area = require 'klib/gmo/area'
local Entity = require 'klib/gmo/entity'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/team'
local Player = require 'scenario/mobile_factory/player'

local BASE_SIZE, GAP_DIST = Config.BASE_SIZE, Config.GAP_DIST

local MobileBaseTeleporter = KC.class('scenario.MobileFactory.MobileBaseTeleporter', function(self, base)
    self:set_base(base)
end)

MobileBaseTeleporter:reference_objects('base')

--- 传送玩家
Event.register(defines.events.on_player_driving_changed_state, function(event)
    -- 仅检查上车
    local player = game.players[event.player_index]
    if not player.driving then return end
    -- 检查上了哪辆基地车
    local entity_data = Entity.get_data(event.entity)
    if not entity_data or not entity_data.base_id then return end
    local base = KC.get(entity_data.base_id)
    if base then
        local team = Team.get_by_player_index(player.index)
        local my_base = team and team:get_base()
        -- 只能进入自己的基地
        if my_base and base:get_id() == my_base:get_id() then
            local teleporter = base:get_teleporter()
            teleporter:teleport_in_or_out(player, event.entity)
        else
            player.print({"mobile_factory.cannot_enter_others_base"})
            player.driving = false
        end
    end
end)

--- 进入或离开基地
function MobileBaseTeleporter:teleport_in_or_out(player, entity)
    local base = self:get_base()
    if self.teleporting then
        self.teleporting = false
    elseif base.generated and base.vehicle == entity then
        player.driving = false
        Entity.safe_teleport(player, base.surface, base.exit_entity.position, 2, 1)
        base:set_player_bonus(player)
    elseif base.exit_entity == entity then
        player.driving = false
        Entity.safe_teleport(player, base.surface, base.vehicle.position, 2, 1)
        self.teleporting = true
        player.driving = true
        base:reset_player_bonus(player)
    end
end

--- 玩家死亡后，如果有基地则传送到基地
Event.register(defines.events.on_player_respawned, function(event)
    local player = game.players[event.player_index]
    local base = Player.get(event.player_index):get_base()
    if base then
        base:teleport_player_to_exit(player)
    end
end)

--- 把所有基地内的玩家传送出去
function MobileBaseTeleporter:teleport_out_all_characters()
    local base = self:get_base()
    local area = Area.from_dimensions(BASE_SIZE, base.center):expand(GAP_DIST/2)
    local characters = base.surface.find_entities_filtered({name='character', area = area})
    if not Table.is_empty(characters) then
        for _, character in ipairs(characters) do
            self:teleport_player_to_vehicle(character)
        end
    end
end

--- 把玩家传送到基地车
function MobileBaseTeleporter:teleport_player_to_vehicle(player)
    local base = self:get_base()
    Entity.safe_teleport(player, base.vehicle.surface, base.vehicle.position, 10, 1)
    base:reset_player_bonus(player)
end

--- 把玩家传送到基地中心
function MobileBaseTeleporter:teleport_player_to_base(player)
    local base = self:get_base()
    Entity.safe_teleport(player, base.surface, base.center, BASE_SIZE.width / 2, 1)
    base:set_player_bonus(player)
end

--- 把玩家传送到基地出口
function MobileBaseTeleporter:teleport_player_to_exit(player)
    local base = self:get_base()
    Entity.safe_teleport(player, base.surface, base.exit_entity.position, GAP_DIST/ 2, 1)
    base:set_player_bonus(player)
end

function MobileBaseTeleporter:on_destroy()
    self:teleport_out_all_characters()
end

return MobileBaseTeleporter
