local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'

local U = require 'scenario/mobile_factory/mobile_base_utils'

local MobileBasePowerController = KC.class('scenario.MobileFactory.MobileBaseDamageController', function(self, base)
    self:set_base(base)
end)

MobileBasePowerController:reference_objects("base")

function MobileBasePowerController:update_power_connection()
    local base = self:get_base()

    local base_poles = base.vehicle.surface.find_entities_filtered({
        type = 'electric-pole',
        position = base.vehicle.position,
        radius = 16,
        force = base.force
    })

    local world_poles = base.exit_entity.surface.find_entities_filtered({
        type = 'electric-pole',
        position = base.exit_entity.position,
        radius = 8,
        force = base.force
    })

    if next(base_poles) and next(world_poles) then
        base_poles[1].connect_neighbour({
            target_entity = world_poles[1],
            wire = defines.wire_type.copper
        })
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
