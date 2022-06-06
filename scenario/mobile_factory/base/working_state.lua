local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'
local StateMachine = require 'klib/classes/state_machine'
local Config = require 'scenario/mobile_factory/config'
local U = require 'scenario/mobile_factory/base/mobile_base_utils'

local MOVING = "moving"
local TRAINING = "training"
local DEPLOYED = "deployed"

local WorkingState = KC.class(Config.PACKAGE_BASE_PREFIX .. 'WorkingState', StateMachine, function(self, base)
    self.base = base
    self.print_warning = true
    StateMachine(self)
end)

WorkingState:create(MOVING, {
    { name = "set_moving", from = { TRAINING, DEPLOYED }, to = MOVING},
    { name = "set_training", from = { MOVING, DEPLOYED }, to = TRAINING},
    {name = "deploy", from = {MOVING, TRAINING}, to = DEPLOYED }
})

WorkingState.MOVING = MOVING
WorkingState.TRAINING = TRAINING
WorkingState.DEPLOYED = DEPLOYED

function WorkingState:can_set()
    local base = self.base
    return base.generated and base.online and not base.heavy_damaged
end

function WorkingState:on_event_call(event, from, to)
    local can = self:can_set()
    if not can and self.print_warning then
        self.base.force.print({"mobile_factory.cannot_set_working_state"})
    end
    return can
end

function WorkingState:on_state_change(event, from, to)
    Event.raise_event(Config.ON_BASE_CHANGED_WORKING_STATE, {
        base_id = self.base:get_id(),
        event = event,
        from = from,
        to = to
    })
end

function WorkingState:on_before_set_training()
    if self.print_warning then
        self.base.force.print("training mobile base is not support currently")
    end
    return false
end

local function is_empty_around_base_vehicle(vehicle, dim, collision_mask)
    local deploy_position = Position.round(vehicle.position)
    local entities = vehicle.surface.find_entities_filtered({
        area = Area.from_dimensions(dim, deploy_position),
        collision_mask = collision_mask
    })
    local can = not Table.find(entities, function(entity)
        return entity.type ~= 'spider-leg'
    end)
    if can then
        local tiles1 = vehicle.surface.find_tiles_filtered({
            name = {"refined-hazard-concrete-left","refined-hazard-concrete-right"},
            area = Area.from_dimensions(dim, deploy_position),
            limit = 1
        })
        local tiles2 = vehicle.surface.find_tiles_filtered({
            area = Area.from_dimensions(dim, deploy_position),
            collision_mask = collision_mask,
            limit = 1
        })
        return Table.is_empty(tiles1) and Table.is_empty(tiles2)
    end
    return false
end

function WorkingState:on_before_deploy()
    local dim = self.base.dimensions
    local is_free = is_empty_around_base_vehicle(self.base.vehicle, dim,
        {"item-layer", "object-layer", "player-layer", "water-tile", "ghost-layer"})
    if not is_free and self.print_warning then
        self.base.force.print({"mobile_factory.cannot_set_working_state_deployed", dim.width .. 'x' .. dim.height})
    end
    return is_free
end

function WorkingState:on_leave_deployed()
    self.base.teleporter:undeploy_base()
end

function WorkingState:on_enter_deployed()
    self.base.teleporter:deploy_base()
end

function WorkingState:toggle()
    if not self:can_set() then return end
    self.print_warning = false
    if self.current == WorkingState.MOVING then
        if self:set_training() then return end
        self.print_warning = true
        if self:deploy() then return end
    elseif self.current == WorkingState.TRAINING then
    elseif self.current == WorkingState.DEPLOYED then
        if self:set_training() then return end
        self.print_warning = true
        if self:set_moving() then return end
    end
end

function WorkingState:is_deployed()
    return self.current == WorkingState.DEPLOYED
end

return WorkingState