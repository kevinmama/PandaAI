local KC = require 'klib/container/container'
local Position = require 'klib/gmo/position'

local U = require 'scenario/mobile_factory/mobile_base_utils'

local MobileBasePolluter = KC.class("scenario.MobileFactory.MobileBasePolluter", function(self, base)
    self:set_base(base)
end)

MobileBasePolluter:reference_objects('base')

function MobileBasePolluter:run()
    self:spread_base_pollution()
end

function MobileBasePolluter:spread_base_pollution()
    local base = self:get_base()
    U.for_each_chunk_of_base(base, function(c_pos)
        local pos = Position.from_chunk_position(c_pos)
        local amount = base.surface.get_pollution(pos)
        base.surface.pollute(pos, -amount)
        base.surface.pollute(base.vehicle.position, amount)
    end)
end

return MobileBasePolluter
