local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local String = require 'klib/utils/string'
local ColorList = require 'stdlib/utils/defines/color_list'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario/mobile_factory/config'

local U = require 'scenario/mobile_factory/base/mobile_base_utils'

local ResourceExchangeController = KC.class(Config.PACKAGE_BASE_PREFIX .. 'ResourceExchangeController', function(self, base)
    self.base = base
    self.always_update = true
    self.exchanging = false
    self.exchanging_bases = {}
    self.resource_exchange_schema = self:create_resource_exchange_schema()
    self.power_exchange_schema = {request = 8000000000, reserve = 2000000000}
end)

function ResourceExchangeController:on_destroy()
    self:stop_exchange()
end

function ResourceExchangeController:update()
    if self.base:is_heavy_damaged() then return end
    self:update_exchanging_base()
end

function ResourceExchangeController:update_exchanging_base()
    local base = self.base
    if base.sitting then
        if not self.exchanging then
            self:start_exchange()
        end
        self:update_exchange()
    else
        self:stop_exchange()
    end
end

function ResourceExchangeController:start_exchange()
    local base = self.base
    local bases = U.find_bases_in_area(U.get_io_area(base, true), base.team:get_id())
    for _, other in pairs(bases) do
        if other:get_id() ~= base:get_id() and other.sitting then
            self:add_exchanging_base(other)
        end
    end
    self.exchanging = true
end

function ResourceExchangeController:stop_exchange()
    if self.exchanging then
        for _, other in pairs(self.exchanging_bases) do
            self:remove_exchanging_base(other)
        end
        self.exchanging = false
    end
end

function ResourceExchangeController:add_exchanging_base(other)
    self.exchanging_bases[other:get_id()] = other
    other.resource_exchange_controller.exchanging_bases[self.base:get_id()] = self.base
end

function ResourceExchangeController:remove_exchanging_base(other)
    self.exchanging_bases[other:get_id()] = nil
    other.resource_exchange_controller.exchanging_bases[self.base:get_id()] = nil
end

function ResourceExchangeController:update_exchange()
    local result_table = {}
    for _, other in pairs(self.exchanging_bases) do
        if other.destroyed or not other.sitting then
            self:remove_exchanging_base(other)
        elseif other:is_active() and not other:is_heavy_damaged() then
            local part_result_table = self:do_exchange_resource(other)
            for name, amount in pairs(part_result_table) do
                result_table[name] = (result_table[name] or 0) + amount
            end
            result_table.power = (result_table.power or 0) + self:do_exchange_power(other)
        end
    end
    self:render_exchange_result(result_table)
end

--------------------------------------------------------------------------------
--- 资源
--------------------------------------------------------------------------------

function ResourceExchangeController:do_exchange_resource(other)
    local result_table = {}
    local other_schema = other.resource_exchange_controller.resource_exchange_schema
    for resource_name, record in pairs(self.resource_exchange_schema) do
        local request_amount = record.request - self.base.resource_amount[resource_name]
        if request_amount > 0 then
            local provide_amount = other.resource_amount[resource_name] - other_schema[resource_name].reserve
            if provide_amount > 0 then
                local delta = self:do_transfer_resource(other, resource_name, request_amount, provide_amount)
                result_table[resource_name] = delta
            end
        end
    end
    return result_table
end

function ResourceExchangeController:do_exchange_power(other)
    local base = self.base
    local request_amount = self.power_exchange_schema.request - base:get_energy()
    if request_amount > 0 then
        local provide_amount = other:get_energy() - other.resource_exchange_controller.power_exchange_schema.reserve
        if provide_amount > 0 then
            return self:do_transfer_power(other, request_amount, provide_amount)
        end
    end
    return 0
end

function ResourceExchangeController:do_transfer_resource(other, resource_name, request_amount, provide_amount)
    local delta = Entity.is_fluid_resource(resource_name) and Config.FLUID_RESOURCE_EXCHANGE_RATE or Config.SOLID_RESOURCE_EXCHANGE_RATE
    if request_amount < delta then
        delta = request_amount
    end
    if provide_amount < delta then
        delta = provide_amount
    end
    other.resource_amount[resource_name] = other.resource_amount[resource_name] - delta
    self.base.resource_amount[resource_name] = self.base.resource_amount[resource_name] + delta
    return delta
end

function ResourceExchangeController:do_transfer_power(other, request_amount, provide_amount)
    local delta = Config.POWER_EXCHANGE_RATE
    if request_amount < delta then
        delta = request_amount
    end
    if provide_amount < delta then
        delta = provide_amount
    end
    other.hyper_accumulator.energy = other.hyper_accumulator.energy - delta
    self.base.hyper_accumulator.energy = self.base.hyper_accumulator.energy + delta
    return delta
end

function ResourceExchangeController:render_exchange_result(result_table)
    local base = self.base
    local text = Table.reduce(result_table, function(text, amount, name)
        if amount > 0 then
            if Entity.is_fluid_resource(name) then
                text = text .. ' [fluid=' .. name .. ']' .. (amount / 3000) .. '%'
            elseif name == 'power' then
                text = text .. ' [img=tooltip-category-electricity]' .. String.exponent_string(amount)
            else
                text = text .. ' [item=' .. name .. ']' .. amount
            end
        end
        return text
    end, "")
    if text ~= "" then
        Entity.create_flying_text(base.vehicle, text, {
            color = ColorList.yellow,
            position = {base.vehicle.position.x, base.vehicle.position.y-2}
        })
    end
end

function ResourceExchangeController:create_resource_exchange_schema()
    local resource_exchange_schema = {}
    for resource_name, _ in pairs(Entity.get_resource_entity_prototypes()) do
        if not Entity.is_fluid_resource(resource_name) then
            resource_exchange_schema[resource_name] = {request = 1000000, reserve = 500000}
        else
            resource_exchange_schema[resource_name] = {request = 15000000, reserve = 7500000}
        end
    end
    return resource_exchange_schema
end

function ResourceExchangeController:set_resource_exchange(resource_name, request, reserve)
    local record = self.resource_exchange_schema[resource_name]
    request, reserve = tonumber(request), tonumber(reserve)
    if request and request >= 0 then
        record.request = Entity.is_fluid_resource(resource_name) and request * 3000 or request
    end
    if reserve and reserve >= 0 then
        record.reserve = Entity.is_fluid_resource(resource_name) and reserve * 3000 or reserve
    end
end

function ResourceExchangeController:set_power_exchange(request, reserve)
    request, reserve = tonumber(request), tonumber(reserve)
    if request and request >= 0 then
        self.power_exchange_schema.request = request
    end
    if reserve and reserve >= 0 then
        self.power_exchange_schema.reserve = reserve
    end
end

function ResourceExchangeController:get_resource_information()
    local info = {}
    for name, record in pairs(self.resource_exchange_schema) do
        info[name] = Table.merge({
            amount = self.base.resource_amount[name]
        }, record)
    end
    return info
end

function ResourceExchangeController:get_power_information()
    return {
        energy = self.base:get_energy(),
        buffer = self.base:get_electric_buffer_size(),
        request = self.power_exchange_schema.request,
        reserve = self.power_exchange_schema.reserve
    }
end

return ResourceExchangeController
