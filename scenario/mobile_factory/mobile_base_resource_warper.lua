local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local LazyTable = require 'klib/utils/lazy_table'
local Entity = require 'klib/gmo/entity'
local Inventory = require 'klib/gmo/inventory'
local Area = require 'klib/gmo/area'
local ColorList = require 'stdlib/utils/defines/color_list'
local Position = require 'klib/gmo/position'

local Config = require 'scenario/mobile_factory/config'
local U = require 'scenario/mobile_factory/mobile_base_utils'

local CHUNK_SIZE, BASE_SIZE = Config.CHUNK_SIZE, Config.BASE_SIZE
local IRON_ORE, COPPER_ORE, COAL, STONE, URANIUM_ORE, CRUDE_OIL =
Config.IRON_ORE, Config.COPPER_ORE, Config.COAL, Config.STONE, Config.URANIUM_ORE, Config.CRUDE_OIL
local RESOURCE_PATCH_LENGTH, RESOURCE_PATCH_SIZE = Config.RESOURCE_PATCH_LENGTH, Config.RESOURCE_PATCH_SIZE

local MobileBaseResourceWarper = KC.class('scenario.MobileFactory.MobileBaseResourceWarper', function(self, base)
    self:set_base(base)
    self.found_resources = {}
end)

MobileBaseResourceWarper:reference_objects("base")

--- 创建资源位置
function MobileBaseResourceWarper:compute_resource_locations()
    local base = self:get_base()
    local resource_locations = {}
    local location_y = base.center.y + BASE_SIZE.height /2 - CHUNK_SIZE
    resource_locations[IRON_ORE] = {x = base.center.x - BASE_SIZE.width /2 + CHUNK_SIZE, y = location_y}
    resource_locations[COPPER_ORE] = {x = base.center.x - BASE_SIZE.width /2 + 3*CHUNK_SIZE, y = location_y}
    resource_locations[COAL] = {x = base.center.x - BASE_SIZE.width /2 + 5*CHUNK_SIZE, y = location_y}
    resource_locations[CRUDE_OIL] = {x = base.center.x + BASE_SIZE.width /2 - 5*CHUNK_SIZE, y = location_y}
    resource_locations[STONE] = {x = base.center.x + BASE_SIZE.width /2 - 3*CHUNK_SIZE, y = location_y}
    resource_locations[URANIUM_ORE] = {x = base.center.x + BASE_SIZE.width /2 - CHUNK_SIZE, y = location_y}
    return resource_locations
end

function MobileBaseResourceWarper:run()
    self:warp_vehicle_inventory()
    if self:can_warp() then
        self:warp_resources_to_base()
        self:warp_exchanging_entities()
    end
end

MobileBaseResourceWarper:on_nth_tick(2, function(self)
    local base = self:get_base()
    if base:can_run() and self:can_warp() then
        self:warp_fluid()
    end
end)

function MobileBaseResourceWarper:update_on_base_changed_working_state()
    local base = self:get_base()
    if base.working_state == Config.BASE_WORKING_STATE_STATION then
        self:find_resources()
    else
        self.found_resources = {}
    end
end

--- 基地成员在线、且无严重受损
function MobileBaseResourceWarper:can_warp()
    local base = self:get_base()
    return not base:is_heavy_damaged() and base.working_state == Config.BASE_WORKING_STATE_STATION
end

-- FIXME: 要重构成缓存找到的矿石
function MobileBaseResourceWarper:find_resources()
    local base = self:get_base()
    local resources = base.surface.find_entities_filtered({
        area = Area.expand(base.vehicle.bounding_box, Config.RESOURCE_WARP_LENGTH),
        name = { IRON_ORE, COPPER_ORE, COAL, STONE, URANIUM_ORE, CRUDE_OIL }
    })
    self.found_resources = resources
end

--- 折跃资源到基地内
function MobileBaseResourceWarper:warp_resources_to_base()
    if Table.is_empty(self.found_resources) then return end
    self:warp_to_base_storage()
    self:warp_oil_to_base()
    self:warp_ores_to_base()
end

-- 资源折跃速率和采矿产能关联
function MobileBaseResourceWarper:get_resource_warp_rate()
    return self:get_base():get_team():get_resource_warp_rate()
end

--- 添加到基地资源计数
function MobileBaseResourceWarper:warp_to_base_storage()
    local base = self:get_base()
    local delta_amount = {}
    Table.array_each_reverse(self.found_resources, function(resource, index)
        local delta, rate
        if resource.valid then
            if resource.name == CRUDE_OIL then
                rate = self:get_resource_warp_rate() * 3000
            else
                rate = self:get_resource_warp_rate()
            end
            if resource.amount > rate then
                delta = rate
                resource.amount = resource.amount - delta
                base.resource_amount[resource.name] = base.resource_amount[resource.name] + delta
                LazyTable.add(delta_amount, resource.name, delta)
            else
                delta = resource.amount
                base.resource_amount[resource.name] = base.resource_amount[resource.name] + delta
                LazyTable.add(delta_amount, resource.name, delta)
                resource.destroy()
                Table.remove(self.found_resources, index)
            end
        else
            Table.remove(self.found_resources, index)
        end
    end)
    --game.print(serpent.line(base.resource_amount))

    --Event.raise_event(Config.ON_BASE_WARPED_RESOURCES , {
    --    base_id = base:get_id(),
    --    amount = delta_amount
    --})
    local pollution = base:get_polluter():spread_warped_resources_pollution(delta_amount)
    self:render_warped_resources(delta_amount, pollution)
end

function MobileBaseResourceWarper:render_warped_resources(amount_map, pollution)
    local base = self:get_base()
    local text = Table.reduce(amount_map, function(text, amount, name)
        if name ~= CRUDE_OIL then
            text = text .. ' [item=' .. name .. ']' .. amount
        else
            text = text .. ' [fluid=' .. name .. ']' .. (amount / 3000) .. '%'
        end
        return text
    end, "")
    text = text .. '[img=utility/show_pollution_in_map_view]' .. pollution
    local ft = base.surface.create_entity({
        name = 'flying-text',
        text = text,
        position = Position(base.vehicle.position),
        color = ColorList.green
    })
end

--- 折跃原油
function MobileBaseResourceWarper:warp_oil_to_base()
    local base = self:get_base()
    local amount = base.resource_amount[CRUDE_OIL]
    local num_crude_oil = 9
    if amount >= num_crude_oil * 30000 then
        local delta = amount / num_crude_oil
        base.resource_amount[CRUDE_OIL] = amount % num_crude_oil
        local entities = base.surface.find_entities_filtered({
            name = CRUDE_OIL,
            area = Area.from_dimensions({width=RESOURCE_PATCH_LENGTH,height=RESOURCE_PATCH_LENGTH}, base.resource_locations[CRUDE_OIL])
        })
        for _, e in ipairs(entities) do
            e.amount = e.amount + delta
        end
    end
end

--- 折跃矿石
function MobileBaseResourceWarper:warp_ores_to_base()
    local base = self:get_base()
    for _, name in ipairs({IRON_ORE, COPPER_ORE, COAL, STONE, URANIUM_ORE}) do
        local amount = base.resource_amount[name]
        local c = base.resource_locations[name]
        if amount >= RESOURCE_PATCH_SIZE*5 then
            local area = Area.from_dimensions({width=RESOURCE_PATCH_LENGTH,height=RESOURCE_PATCH_LENGTH},c)
            local exist_resources = base.surface.find_entities_filtered({ name=name, area = area })
            local exist_amount = 0
            for _, res in ipairs(exist_resources) do
                exist_amount = exist_amount + res.amount
                res.destroy()
            end
            local new_amount = (amount + exist_amount) / RESOURCE_PATCH_SIZE
            local remain_amount = (amount + exist_amount) % RESOURCE_PATCH_SIZE
            base.resource_amount[name] = remain_amount

            for offset_x = - RESOURCE_PATCH_LENGTH/2, RESOURCE_PATCH_LENGTH/2-1 do
                for offset_y = - RESOURCE_PATCH_LENGTH/2, RESOURCE_PATCH_LENGTH/2-1 do
                    local position = { x=c.x+offset_x, y=c.y+offset_y}
                    base.surface.create_entity({ name = name, position = position, amount = new_amount})
                end
            end

            -- 更新矿机工作状态。资源枯竭后再恢复时，机器不工作，需要更新连接。
            local drills = base.surface.find_entities_filtered({type="mining-drill", area = area})
            for _, drill in drills do
                drill.update_connections()
            end
        end
    end
end

--- 同步基地出口车与基地车的物品栏
--- 设置了过滤器的做输出，没设置的做输入
function MobileBaseResourceWarper:warp_vehicle_inventory()
    local base = self:get_base()
    local inv1 = base.vehicle.get_inventory(defines.inventory.car_trunk)
    local inv2 = base.exit_entity.get_inventory(defines.inventory.car_trunk)
    Inventory.exchange_car_inventory(inv1, inv2)
end

function MobileBaseResourceWarper:warp_exchanging_entities()
    local base = self:get_base()
    local e1 = base.base_exchanging_entities
    local e2 = base.vehicle_exchanging_entities
    U.transfer_chest_inventory(e1.chest1, e2.chest1)
    U.transfer_chest_inventory(e1.chest2, e2.chest2)
    U.transfer_chest_inventory(e2.chest3, e1.chest3)
    U.transfer_chest_inventory(e2.chest4, e1.chest4)
end

function MobileBaseResourceWarper:warp_fluid()
    local base = self:get_base()
    local e1 = base.base_exchanging_entities
    local e2 = base.vehicle_exchanging_entities
    Entity.transfer_fluid(e2.pump1, e1.pump1)
    Entity.transfer_fluid(e2.pump2, e1.pump2)
    Entity.transfer_fluid(e1.pump3, e2.pump3)
    Entity.transfer_fluid(e1.pump4, e2.pump4)
end

Event.register(Config.ON_BASE_CHANGED_WORKING_STATE, function(event)
    local base = KC.get(event.base_id)
    local warper = base:get_resource_warper()
    warper:update_on_base_changed_working_state()
end)

return MobileBaseResourceWarper