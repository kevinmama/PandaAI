local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local String = require 'klib/utils/string'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Position = require 'klib/gmo/position'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local Config = require 'scenario/mobile_factory/config'

local PowerController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'PowerController', function(self, base)
    self.base = base
    self.halt = false
    self.deploy_substation = nil
end)

function PowerController:get_energy()
    return self.base.hyper_accumulator.energy
end

function PowerController:get_electric_buffer_size()
    return self.base.hyper_accumulator.electric_buffer_size
end

function PowerController:can_recharge_equipment_for_character()
    local base = self.base
    return base:is_active() and not base:is_heavy_damaged()
end

local function recharge_equipment(energy_source, grid)
    for _, equipment in pairs(grid.equipment) do
        if equipment.energy < equipment.max_energy then
            local require_energy = equipment.max_energy - equipment.energy
            if energy_source.energy >= require_energy then
                equipment.energy = equipment.max_energy
                energy_source.energy = energy_source.energy - require_energy
            else
                equipment.energy = equipment.energy + energy_source.energy
                energy_source.energy = 0
            end
        end
    end
end

function PowerController:recharge_equipment_for_character(character)
    local grid = character and character.valid and character.grid
    if not grid then return end
    local base = self.base
    if base:is_active() and not base:is_heavy_damaged() then
        recharge_equipment(base.hyper_accumulator, grid)
    end
end

function PowerController:update()
    self:update_generators()
    self:recharge_base_equipment()
    self:update_hyper_combinator()
    self:update_deploy_substation()
end

function PowerController:recharge_base_equipment()
    local base = self.base
    if not base:is_heavy_damaged() then
        local grid = base.vehicle.grid
        if grid then
            recharge_equipment(base.hyper_accumulator, grid)
        end
        self:recharge_equipment_for_character(base.vehicle.get_driver())
    end
end

function PowerController:set_halt(halt)
    self.halt = halt
    local generators = U.find_entities_in_base(self.base, true, {type = 'generator'})
    Table.each(generators, function(generator) generator.active = not halt end)
end

function PowerController:update_generators()
    local base = self.base
    if base:is_heavy_damaged() then
        self:set_halt(true)
    elseif self.halt then
        self:set_halt(false)
    end
end

function PowerController:update_hyper_combinator()
    local behavior = self.base.hyper_combinator.get_control_behavior()
    local energy_in_millions = math.floor(self.base.hyper_accumulator.energy / 1000000)
    behavior.set_signal(1, {
        signal = {type = "virtual", name = "signal-M"},
        count = energy_in_millions
    })
end

function PowerController:create_deploy_substation()
    if (not self.deploy_substation or not self.deploy_substation.valid)
            and self.base:is_active() and not self.base:is_heavy_damaged() and self.base.sitting then
        self.deploy_substation = self.base.surface.create_entity({
            name = 'substation',
            position = U.get_deploy_position(self.base),
            force = self.base.force
        })
        if self.deploy_substation then
            self.deploy_substation.minable = false
            self.deploy_substation_position = self.deploy_substation.position
            Entity.connect_neighbour(self.deploy_substation, self.base.hyper_substation, "all")
            return true
        end
    end
    return false
end

function PowerController:update_deploy_substation()
    if self.deploy_substation and self.deploy_substation.valid then
        if self.base.moving or not Position.equals(self.deploy_substation.position, self.deploy_substation_position) then
            self.deploy_substation.die()
            self.deploy_substation = nil
        end
    end
end

return PowerController
