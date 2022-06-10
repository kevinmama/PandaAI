local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'
local Surface = require 'klib/gmo/surface'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local WorkingState = require 'scenario/mobile_factory/base/working_state'

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
        if base.working_state.current ~= WorkingState.DEPLOYED then
            player.driving = false
            self:teleport_player_to_exit(player)
        end
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
    if Entity.safe_teleport(player, base.vehicle.position,base.vehicle.surface, 10, 1) then
        U.reset_player_bonus(player)
        U.set_player_visiting_base(player, nil)
        return true
    else
        return false
    end
end

--- 把玩家传送到基地中心
function Teleporter:teleport_player_to_center(player)
    local base = self.base
    if base.generated and Entity.safe_teleport(player, base.center,base.surface,GAP_DIST / 2, 1) then
        U.set_player_bonus(player)
        U.set_player_visiting_base(player, base)
        return true
    else
        return false
    end
end

--- 把玩家传送到基地出口
function Teleporter:teleport_player_to_exit(player)
    local base = self.base
    -- 部署状态下不能进基地
    if base.exit_entity and base.exit_entity.valid and base.working_state.current ~= WorkingState.DEPLOYED
        and Entity.safe_teleport(player, base.exit_entity.position, base.surface,  GAP_DIST/ 2, 1) then
        U.set_player_bonus(player)
        U.set_player_visiting_base(player, base)
        return true
    else
        return false
    end
end

function Teleporter:teleport_player_on_respawned(player)
    if self:teleport_player_to_exit(player) then
        return true
    else
        return self:teleport_player_to_vehicle(player)
    end
end

local function print_entity_type_info(entity)
    if entity.name == 'entity-ghost' then
        game.print(serpent.line({"teleport failed", name = entity.name, type = entity.type, ghost_name = entity.ghost_name, ghost_type = entity.ghost_type}))
    else
        game.print(serpent.line({"teleport failed", name = entity.name, type = entity.type}))
    end
end

function Teleporter:teleport_entities_to_world()
    local base = self.base
    local target_position = U.get_deploy_position(base)
    Entity.teleport_area({
        from_surface = base.surface,
        from_center = base.center,
        to_center = target_position,
        dimensions = base.dimensions,
        teleport_filter = function(entity)
            return entity ~= base.exit_entity and entity.type ~= 'spider-leg'
        end,
        on_cloned = function(entity, cloned)
            base.resource_warping_controller:on_entity_cloned(entity, cloned)
        end,
        on_teleported = function(entity)
            if entity.valid and entity.type == 'character' and entity.player then
                    U.reset_player_bonus(entity.player)
                    U.set_player_visiting_base(entity.player, nil)
            end
        end,
        on_failed = print_entity_type_info
    })
    base.resource_warping_controller:update_resources_position(base.center, target_position)
end

function Teleporter:swap_tiles()
    local base = self.base
    local base_area = U.get_base_area(base)
    local deploy_area = U.get_deploy_area(base)
    Surface.swap_tiles({
        area1= deploy_area,
        surface1= base.surface,
        area2= base_area,
        surface2= base.surface,
        swap_area= base_area,
        swap_surface= U.get_alt_surface(),
    })
end


function Teleporter:teleport_entities_to_base()
    local base = self.base
    local source_position = U.get_deploy_position(base)
    Entity.teleport_area({
        from_surface = base.surface,
        from_center = source_position,
        to_center = base.center,
        dimensions = base.dimensions,
        inside = true,
        entities_finder = function(area)
            local force_entities = base.surface.find_entities_filtered({
                area = area,
                force = base.force
            })
            local ground_entities = base.surface.find_entities_filtered({
                name = "item-on-ground",
                area = area,
            })
            local resource_entities = base.resource_warping_controller:get_valid_output_resources()
            return Table.array_combine(force_entities, ground_entities, resource_entities)
        end,
        teleport_filter = function(entity)
            return entity.type ~= 'spider-leg'
                    and not (entity.name == Config.BASE_VEHICLE_NAME and U.get_base_by_vehicle(entity))
                    and not (entity.type == 'linked-belt' and not base.resource_warping_controller:is_my_io_belt(entity))
        end,
        on_cloned = function(entity, cloned)
            base.resource_warping_controller:on_entity_cloned(entity, cloned)
        end,
        on_teleported = function(entity)
            if entity.valid and entity.type == 'character' and entity.player then
                U.set_player_bonus(entity.player)
                U.set_player_visiting_base(entity.player, base)
            end
        end,
        on_failed = print_entity_type_info
    })
    base.resource_warping_controller:update_resources_position(source_position, base.center)
end

local DEPLOY_MARKERS = {
    ["left_top"] = "refined-hazard-concrete-left",
    ["left_bottom"] = "refined-hazard-concrete-right",
    ["right_top"] = "refined-hazard-concrete-right",
    ["right_bottom"] = "refined-hazard-concrete-left",
}

function Teleporter:create_deploy_markers()
    local area = Area.corners(U.get_deploy_area(self.base, true))
    local tiles = {}
    for corner_name, tile_name in pairs(DEPLOY_MARKERS) do
        Table.insert(tiles, {position = area[corner_name], name = tile_name})
    end
    self.base.surface.set_tiles(tiles)
    for corner_name, tile_name in pairs(DEPLOY_MARKERS) do
        self.base.surface.set_hidden_tile(area[corner_name], tile_name)
    end
end

function Teleporter:remove_deploy_markers()
    local area = Area.corners(U.get_deploy_area(self.base, true))
    for corner_name, _ in pairs(DEPLOY_MARKERS) do
        self.base.surface.set_hidden_tile(area[corner_name], nil)
    end
end

function Teleporter:deploy_base()
    self.base.deploy_position = Position.round(self.base.vehicle.position)
    self:teleport_entities_to_world()
    self:swap_tiles()
    self:create_deploy_markers()
end

function Teleporter:undeploy_base()
    self:teleport_entities_to_base()
    self:remove_deploy_markers()
    self:swap_tiles()
    self.base.deploy_position = nil
end

function Teleporter:on_destroy()
    if self.base.working_state.current == WorkingState.DEPLOYED then
        self:undeploy_base()
    end
    self:teleport_out_all_characters()
end

return Teleporter
