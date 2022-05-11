local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local LazyTable = require 'klib/utils/lazy_table'
local Entity = require 'klib/gmo/entity'
local Area = require 'klib/gmo/area'
local ColorList = require 'stdlib/utils/defines/color_list'
local Position = require 'klib/gmo/position'

local Config = require 'scenario/mobile_factory/config'

local CHUNK_SIZE, BASE_SIZE = Config.CHUNK_SIZE, Config.BASE_SIZE
local IRON_ORE, COPPER_ORE, COAL, STONE, URANIUM_ORE, CRUDE_OIL =
Config.IRON_ORE, Config.COPPER_ORE, Config.COAL, Config.STONE, Config.URANIUM_ORE, Config.CRUDE_OIL
local RESOURCE_PATCH_LENGTH, RESOURCE_PATCH_SIZE = Config.RESOURCE_PATCH_LENGTH, Config.RESOURCE_PATCH_SIZE

local MobileBaseResourceWarper = KC.class('scenario.MobileFactory.MobileBaseResourceWarper', function(self, base)
    self:set_base(base)
end)

MobileBaseResourceWarper:refs("base")

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
    if self:can_warp() then
        self:find_and_warp()
        self:warp_inventory()
    end
end

--- 基地成员在线、且无严重受损
function MobileBaseResourceWarper:can_warp()
    return not self:get_base():is_heavy_damaged()
end

function MobileBaseResourceWarper:find_and_warp()
    local base = self:get_base()
    -- 无法检测机器人修理，故在这里检查
    Entity.set_frozen(base.vehicle, false)
    local resources = base.surface.find_entities_filtered({
        area = Area.expand(base.vehicle.bounding_box, Config.RESOURCE_WARP_LENGTH),
        name = { IRON_ORE, COPPER_ORE, COAL, STONE, URANIUM_ORE, CRUDE_OIL }
    })
    if not Table.is_empty(resources) then
        self:warp_resources_to_base(resources)
    end
end

--- 折跃资源到基地内
function MobileBaseResourceWarper:warp_resources_to_base(resources)
    self:warp_to_base_storage(resources)
    self:warp_oil_to_base()
    self:warp_ores_to_base()
end

--- 添加到基地资源计数
function MobileBaseResourceWarper:warp_to_base_storage(resources)
    local base = self:get_base()
    local delta_amount = {}
    for _, resource in ipairs(resources) do
        local delta, rate
        if resource.name == CRUDE_OIL then
            rate = Config.RESOURCE_WARP_RATE * 3000
        else
            rate = Config.RESOURCE_WARP_RATE
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
        end
    end
    --game.print(serpent.line(base.resource_amount))
    self:render_warped_resources(delta_amount)
end

function MobileBaseResourceWarper:render_warped_resources(amount_map)
    local base = self:get_base()
    local text = Table.reduce(amount_map, function(text, amount, name)
        if name ~= CRUDE_OIL then
            text = text .. ' [item=' .. name .. ']' .. amount
        else
            text = text .. ' [fluid=' .. name .. ']' .. (amount / 3000) .. '%'
        end
        return text
    end, "")
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
        if amount >= RESOURCE_PATCH_SIZE*10 then
            local exist_resources = base.surface.find_entities_filtered({
                name=name,
                area = Area.from_dimensions({width=RESOURCE_PATCH_LENGTH,height=RESOURCE_PATCH_LENGTH},c)
            })
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
        end
    end
end

--- 同步基地出口车与基地车的物品栏
--- 设置了过滤器的做输出，没设置的做输入
function MobileBaseResourceWarper:warp_inventory()
    local base = self:get_base()
    local inv1 = base.vehicle.get_inventory(defines.inventory.car_trunk)
    local inv2 = base.exit_entity.get_inventory(defines.inventory.car_trunk)
    Entity.exchange_car_inventory(inv1, inv2)
end

return MobileBaseResourceWarper