local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Position = require 'klib/gmo/position'

local U = require 'scenario/mobile_factory/mobile_base_utils'
local Config = require 'scenario/mobile_factory/config'

local MobileBasePolluter = KC.class("scenario.MobileFactory.MobileBasePolluter", function(self, base)
    self:set_base(base)
end)

MobileBasePolluter:reference_objects('base')

function MobileBasePolluter:run()
    self:spread_debug_pollution()
    self:spread_base_pollution()
end

function MobileBasePolluter:spread_debug_pollution()
    if Config.DEBUG then
        local base = self:get_base()
        base.surface.pollute(base.vehicle.position, 1000)
    end
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

function MobileBasePolluter:spread_warped_resources_pollution(amount)
    local base = self:get_base()
    -- 每点资源 1 污染，每 3000 点油 1 污染
    local pollution_amount  = Table.reduce(amount, function(sum, value, resource_name)
        if resource_name == Config.CRUDE_OIL then
            return sum + value / 30.0
        else
            return sum + value
        end
    end, 0)
    base.vehicle.surface.pollute(base.vehicle.position, pollution_amount)
    return pollution_amount
end

--Event.register(Config.ON_BASE_WARPED_RESOURCES, function(event)
--    local base = KC.get(event.base_id)
--    base:get_polluter():spread_warped_resources_pollution(event.amount)
--end)


return MobileBasePolluter
