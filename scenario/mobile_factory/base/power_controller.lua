local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local Config = require 'scenario/mobile_factory/config'

local PowerController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'PowerController', function(self, base)
    self.base = base
    self.halt = false
end)

function PowerController:can_recharge_equipment_for_character()
    local base = self.base
    return base:can_update() and not base:is_heavy_damaged()
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
    if base:can_update() and not base:is_heavy_damaged() then
        recharge_equipment(base.hyper_accumulator, grid)
    end
end

function PowerController:update()
    self:update_generators()
    self:recharge_base_equipment()
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
    local generators = U.find_entities_in_base(self.base, {type = 'generator'})
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

return PowerController
