local KC = require 'klib/container/container'
local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'
local Entity = require 'klib/gmo/entity'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'

local GAP_DIST = Config.GAP_DIST

local Teleporter = KC.class(Config.PACKAGE_BASE_PREFIX .. 'Teleporter', function(self, base)
    self.base = base
end)

--- 传送玩家
Event.register(defines.events.on_player_driving_changed_state, function(event)
    -- 仅检查上车
    local player = game.players[event.player_index]
    if not player.driving then return end
    -- 检查上了哪辆基地车
    local base = U.get_base_by_vehicle(event.entity)
    if base then
        local team = Team.get_by_player_index(player.index)
        -- 只能进入自己团队的基地
        if base.team:get_id() == team:get_id() then
            base.teleporter:teleport_in_or_out(player, event.entity)
        else
            player.print({"mobile_factory.cannot_enter_others_base"})
            player.driving = false
        end
    end
end)

--- 进入或离开基地
function Teleporter:teleport_in_or_out(player, entity)
    local base = self.base
    if self.teleporting then
        self.teleporting = false
    elseif base.generated and base.vehicle == entity then
        player.driving = false
        self:teleport_player_to_exit(player)
    elseif base.exit_entity == entity then
        player.driving = false
        self:teleport_player_to_vehicle(player)
        self.teleporting = true
        player.driving = true
    end
end

--- 把所有基地内的玩家传送出去
function Teleporter:teleport_out_all_characters()
    local base = self.base
    local characters = base.surface.find_entities_filtered({name='character', area = U.get_base_area(base, false)})
    if not Table.is_empty(characters) then
        for _, character in ipairs(characters) do
            self:teleport_player_to_vehicle(character)
        end
    end
end

--- 把玩家传送到基地车
function Teleporter:teleport_player_to_vehicle(player)
    local base = self.base
    Entity.safe_teleport(player, base.vehicle.surface, base.vehicle.position, 10, 1)
    U.reset_player_bonus(player)
    U.set_player_visiting_base(player, nil)
end

--- 把玩家传送到基地中心
function Teleporter:teleport_player_to_center(player)
    local base = self.base
    Entity.safe_teleport(player, base.surface, base.center, GAP_DIST / 2, 1)
    U.set_player_bonus(player)
    U.set_player_visiting_base(player, base)
end

--- 把玩家传送到基地出口
function Teleporter:teleport_player_to_exit(player)
    local base = self.base
    Entity.safe_teleport(player, base.surface, base.exit_entity.position, GAP_DIST/ 2, 1)
    U.set_player_bonus(player)
    U.set_player_visiting_base(player, base)
end

function Teleporter:teleport_entities_to_world()
    local base = self.base
    local entities = U.find_entities_in_base(base)

    local v_pos = Position(base.vehicle.position)
    local c_pos = Position(base.center)
    for _, entity in pairs(entities) do
        if entity.valid and entity ~= base.exit_entity then
            local pos = v_pos + entity.position - c_pos
            entity.teleport(pos)
            if entity.type == 'character' then
                U.set_player_visiting_base(entity.player, nil)
            end
        end
    end
    base.deploy_position = v_pos
end

function Teleporter:teleport_entities_to_base()
    local base = self.base
    local entities = U.find_entities_in_deploy_area(base, {
        force = base.force
    })

    local v_pos = Position(base.deploy_position) or Position(base.vehicle.position)
    local c_pos = Position(base.center)
    for _, entity in pairs(entities) do
        if entity.valid and not (entity.name == Config.BASE_VEHICLE_NAME and U.get_base_by_vehicle(entity)) then
            local pos = c_pos + entity.position - v_pos
            entity.teleport(pos)
            if entity.type == 'character' then
                U.set_player_visiting_base(entity.player, self.base)
            end
        end
    end
    for _, resources in pairs(base.resource_warping_controller.output_resources) do
        for _, entity in pairs(resources) do
            if entity.valid then
                local pos = c_pos + entity.position - v_pos
                entity.teleport(pos)
            end
        end
    end
    base.deploy_position = nil
end

function Teleporter:on_destroy()
    self:teleport_out_all_characters()
end

return Teleporter
