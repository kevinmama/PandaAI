local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'

local U = require 'scenario/mobile_factory/mobile_base_utils'
local Config = require 'scenario/mobile_factory/config'

local MobileBasePowerController = KC.class('scenario.MobileFactory.MobileBaseDamageController', function(self, base)
    self:set_base(base)
end)

MobileBasePowerController:reference_objects("base")

function MobileBasePowerController:can_recharge_equipment_for_character()
    local base = self:get_base()
    return base:can_run() and not base:is_heavy_damaged()
end

function MobileBasePowerController:recharge_equipment_for_character(character)
    local grid = character and character.valid and character.grid
    if not grid then return end
    local base = self:get_base()
    if base:can_run() and not base:is_heavy_damaged() then
        local hyper_accumulator = base.hyper_accumulator
        for _, equipment in pairs(grid.equipment) do
            if equipment.energy < equipment.max_energy then
                local require_energy = equipment.max_energy - equipment.energy
                if hyper_accumulator.energy >= require_energy then
                    equipment.energy = equipment.max_energy
                    hyper_accumulator.energy = hyper_accumulator.energy - require_energy
                else
                    equipment.energy = equipment.energy + hyper_accumulator.energy
                    hyper_accumulator.energy = 0
                end
            end
        end
    end
end

function MobileBasePowerController:run()
    self:update_generators()
end

function MobileBasePowerController:update_generators()
    local base = self:get_base()
    if base:is_heavy_damaged() or base:is_recovering() then
        local generators = U.find_entities_in_base(base, {type = 'generator'})
        Table.each(generators, function(generator)
            if base:is_heavy_damaged() then
                generator.active = false
            else
                generator.active = base:is_recovering()
            end
        end)
    end
end

return MobileBasePowerController
