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
