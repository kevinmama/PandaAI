local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Surface = require 'klib/gmo/surface'
local Entity = require 'klib/gmo/entity'
local Area = require 'klib/gmo/area'
local Position = require 'klib/gmo/position'
local Dimension = require 'klib/gmo/dimension'
local ColorList = require 'stdlib/utils/defines/color_list'


local Config = require 'scenario/mobile_factory/config'
local U = require 'scenario/mobile_factory/base/mobile_base_utils'

local BASE_VEHICLE_NAME = Config.BASE_VEHICLE_NAME
local CHUNK_SIZE = Config.CHUNK_SIZE

local VehicleController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'VehicleController', function(self, base, vehicle)
    self.base = base
end)

--- 生成基地载具
function VehicleController:create(vehicle_or_position)
    local base = self.base
    local team = base.team
    local surface = base.surface

    local position, vehicle
    if vehicle_or_position then
        if vehicle_or_position.object_name == 'LuaEntity' then
            vehicle = vehicle_or_position
        else
            position = vehicle_or_position
        end
    end

    if not vehicle then
        position = position or {x=math.random(-CHUNK_SIZE, CHUNK_SIZE), y=math.random(-CHUNK_SIZE, CHUNK_SIZE)}
        local safe_pos = surface.find_non_colliding_position(BASE_VEHICLE_NAME, position, 16, 1) or position
        vehicle = surface.create_entity({
            name = BASE_VEHICLE_NAME, position = safe_pos, force = team.force, raise_built = true
        })
    end
    vehicle.minable = false
    Entity.set_data(vehicle, {base_id = base:get_id()})
    self.base.vehicle = vehicle
    self:render_around_vehicle()
    return vehicle
end

function VehicleController:replace_vehicle(vehicle)
    local base = self.base
    local data = Entity.get_data(vehicle)
    Entity.set_data(vehicle)
    base.vehicle = vehicle.clone({
        position = vehicle.position,
        surface = vehicle.surface,
        force = vehicle.force
    })
    Entity.set_data(base.vehicle, data)
    self:render_around_vehicle()
end

function VehicleController:render_around_vehicle()
    self:render_base_name()
    self:render_state_text()
end

function VehicleController:render_selection_marker(player)
    local base = self.base
    local vehicle = base.vehicle
    if vehicle.valid then
        local box = vehicle.bounding_box
        local width = Area.width(box)
        --local height = Area.height(box)
        return rendering.draw_circle({
            color = ColorList.green,
            filled = false,
            target = vehicle,
            radius = width,
            width = 5,
            surface = self.base.surface,
            players = {player},
            visible = true,
            draw_on_ground = true,
        })
    end
end

function VehicleController:on_destroy()
    local vehicle = self.base.vehicle
    if vehicle then
        Entity.set_data(vehicle)
        if vehicle.valid then
            vehicle.die()
        end
    end
end

function VehicleController:update()
    --self:update_state_text()
end

function VehicleController:clear_deploy_area()
    local entities = U.find_entities_in_deploy_area(self.base, {
        type = {"simple-entity", "cliff", "tree"},
        force = "neutral"
    })
    local ground_entities = U.find_entities_in_deploy_area(self.base, {
        item = "item-on-ground"
    })
    for _, entity in pairs(Table.dictionary_combine(entities, ground_entities)) do
        if entity.valid then
            entity.order_deconstruction(self.base.force)
        end
    end
end

function VehicleController:clear_biters_in_deploy_area()
    local base = self.base
    local area = Area.expand(U.get_deploy_area(base), 64)
    Surface.clear_enemies_in_area(base.vehicle.surface, area)
    game.print({"mobile_factory.removed_deploy_area_enemies", base:get_name()})
end

--------------------------------------------------------------------------------
--- 显示
--------------------------------------------------------------------------------

function VehicleController:render_base_name()
    local base = self.base
    self.base_owner_text_id = rendering.draw_text {
        text = base.name,
        surface = base.vehicle.surface,
        target = base.vehicle,
        target_offset = {0, -8},
        color = { r = 0.6784, g = 0.8471, b = 0.9020, a = 1 },
        scale = 1.80,
        font = 'default-game',
        alignment = 'center',
        scale_with_zoom = false
    }
end

function VehicleController:update_base_name()
    if self.base_owner_text_id and rendering.is_valid(self.base_owner_text_id) then
        rendering.set_text(self.base_owner_text_id, self.base.name)
    end
end

function VehicleController:render_state_text()
    local base = self.base
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

function VehicleController:update_state_text()
    local base = self.base
    U.update_state_text(self.red_state_text_id, {
        {base.heavy_damaged, {"mobile_factory.state_text_heavy_damaged"}}
    })
    U.update_state_text(self.yellow_state_text_id, {
        {not base.online, {"mobile_factory.state_text_offline"}}
    })
    U.update_state_text(self.green_state_text_id, {
        {true, base:get_working_state_label()}
    })
end

function VehicleController:toggle_display_deploy_area()
    if not self:destroy_deploy_area() then
        self:render_deploy_area()
    end
end

function VehicleController:toggle_display_warp_resource_area()
    if not self:destroy_warp_resource_area() then
        self:render_warp_resource_area()
    end
end

function VehicleController:toggle_display_io_area()
    if not self:destroy_io_area() then
        self:render_io_area()
    end
end

function VehicleController:render_warp_resource_area()
    local dim = Config.RESOURCE_WARPING_DIMENSIONS
    self.warp_resource_rect_id = rendering.draw_rectangle({
        color = { r = 0.4, g = 0.4, b = 0.0000, a = 0.2 },
        filled = true,
        left_top = self.base.vehicle,
        left_top_offset = {-dim.width/2,-dim.height/2},
        right_bottom = self.base.vehicle,
        right_bottom_offset = {dim.width/2,dim.height/2},
        surface = self.base.surface,
        forces = {self.base.force},
        visible = true,
        draw_on_ground = true,
        only_in_alt_mode = true
    })
end

function VehicleController:render_deploy_area()
    local dim = self.base.dimensions
    self.deploy_rect_id = rendering.draw_rectangle({
        color = {r=0.2,g=0.4,b=0.2,a=0.2},
        filled = true,
        left_top = self.base.vehicle,
        left_top_offset = {-dim.width/2,-dim.height/2},
        right_bottom = self.base.vehicle,
        right_bottom_offset = {dim.width/2,dim.height/2},
        surface = self.base.surface,
        forces = {self.base.force},
        visible = true,
        draw_on_ground = true,
        only_in_alt_mode = true
    })
end

function VehicleController:render_io_area()
    local dim = Dimension.CHUNK_UNIT
    self.io_rect_id = rendering.draw_rectangle({
        color = {r=0.2,g=0.2,b=0.5,a=0.2},
        filled = true,
        left_top = self.base.vehicle,
        left_top_offset = {-dim.width/2,-dim.height/2},
        right_bottom = self.base.vehicle,
        right_bottom_offset = {dim.width/2,dim.height/2},
        surface = self.base.surface,
        forces = {self.base.force},
        visible = true,
        draw_on_ground = true,
        only_in_alt_mode = true
    })
end

function VehicleController:destroy_warp_resource_area()
    if self.warp_resource_rect_id and rendering.is_valid(self.warp_resource_rect_id) then
        rendering.destroy(self.warp_resource_rect_id)
        self.warp_resource_rect_id = nil
        return true
    else
        return false
    end
end

function VehicleController:destroy_deploy_area()
    if self.deploy_rect_id and rendering.is_valid(self.deploy_rect_id) then
        rendering.destroy(self.deploy_rect_id)
        self.deploy_rect_id = nil
        return true
    else
        return false
    end
end

function VehicleController:destroy_io_area()
    if self.io_rect_id and rendering.is_valid(self.io_rect_id) then
        rendering.destroy(self.io_rect_id)
        self.io_rect_id = nil
        return true
    else
        return false
    end
end

Event.on_entity_died(function(event)
    local entity = event.entity
    local base = U.get_base_by_vehicle(entity)
    if base then
        base.vehicle_controller:replace_vehicle(entity)
        base:for_each_components(function(component)
            if component.on_base_vehicle_died then
                component:on_base_vehicle_died(event)
            end
        end)
        base.vehicle_controller:update_state_text()
    end
end)

Event.register(Config.ON_BASE_CHANGED_WORKING_STATE, function(event)
    KC.get(event.base_id).vehicle_controller:update_state_text()
end)

return VehicleController