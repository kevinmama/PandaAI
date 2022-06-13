local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Position = require 'klib/gmo/position'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'
local Config = require 'scenario/mobile_factory/config'

local PollutionController = KC.class(Config.PACKAGE_BASE_PREFIX .. "PollutionController", function(self, base)
    self.base = base
end)

function PollutionController:update()
    self:spread_debug_pollution()
    self:spread_base_pollution()
end

function PollutionController:spread_debug_pollution()
    if Config.DEBUG then
        self.base.surface.pollute(self.base.vehicle.position, 10000)
    end
end

function PollutionController:spread_base_pollution()
    local base = self.base
    U.each_chunk_of_base(base, function(c_pos)
        local pos = Position.from_chunk_position(c_pos)
        local amount = base.surface.get_pollution(pos)
        base.surface.pollute(pos, -amount)
        base.surface.pollute(base.vehicle.position, amount)
    end)
end

function PollutionController:spread_warped_resources_pollution(amount)
    local base = self.base
    -- 每点资源 1 污染，每 3000 点油 1 污染
    local pollution_amount  = Table.reduce(amount, function(sum, value, resource_name)
        if Entity.is_fluid_resource(resource_name) then
            return sum + value / 30.0
        else
            return sum + value
        end
    end, 0) * Config.RESOURCE_WARP_POLLUTION_MULTIPLIER
    base.vehicle.surface.pollute(base.vehicle.position, pollution_amount)
    return pollution_amount
end

return PollutionController
