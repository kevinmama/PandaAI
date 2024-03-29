local Table = require('klib/utils/table')

local Inventory = {}

local ENTITY_ITEM_TYPE_INVENTORY_MAP = {
    ["character"] = {
        ["gun"] = defines.inventory.character_guns,
        ["ammo"] = defines.inventory.character_ammo,
        ["armor"] = defines.inventory.character_armor,
        ["main"] = defines.inventory.character_main
    },
    ["car"] = {
        ["ammo"] = defines.inventory.car_ammo,
        ["main"] = defines.inventory.car_trunk
    },
    ["spider-vehicle"] = {
        ["ammo"] = defines.inventory.spider_ammo,
        ["main"] = defines.inventory.spider_trunk
    },
    ["chest"] = {
        ["main"] = defines.inventory.chest
    },
    ['character-corpse'] = {
        ["main"] = defines.inventory.character_corpse
    }
}

local ENTITY_MAIN_INVENTORY_MAP = {
    chest = defines.inventory.chest,
    character = defines.inventory.character_main,
    car = defines.inventory.car_trunk,
    ['spider-vehicle'] = defines.inventory.spider_trunk,
    ['character-corpse'] = defines.inventory.character_corpse
}

function Inventory.get_main_inventory(entity)
    local inventory_name = entity and entity.valid and ENTITY_MAIN_INVENTORY_MAP[entity.type]
    return inventory_name and entity.get_inventory(inventory_name)
end

function Inventory.get_inventory(entity, type)
    if entity and entity.valid then
        local map = ENTITY_ITEM_TYPE_INVENTORY_MAP[entity.type]
        if map then
            local inventory_name = map[type] or map["main"]
            return entity.get_inventory(inventory_name)
        end
    end
    return nil
end

function Inventory.get_grid(entity)
    if entity and entity.valid then
        if entity.type == 'character' then
            local armor_inventory = entity.get_inventory(defines.inventory.character_armor)
            local grid = armor_inventory and armor_inventory[1] and armor_inventory[1].grid
            return grid
        else
            return entity.grid
        end
    end
end

local function transfer_item_unchecked(source, destination, name, count)
    local inserted_count = 0
    if game.item_prototypes[name].type == 'armor' then
        --- 对有耐久的物品，用这种方式比较合适
        for _ = 1, count do
            local stack = source.find_item_stack(name)
            local empty_stack = destination.find_empty_stack(name)
            if stack and empty_stack and empty_stack.transfer_stack(stack) then
                inserted_count = inserted_count + 1
            end
        end
    else
        inserted_count = destination.insert({name=name, count=count})
        if inserted_count > 0 then
            source.remove({name=name,count=inserted_count})
        end
    end
    return inserted_count
end

function Inventory.transfer_item(source, destination, name, count, maximum_count)
    local count = count or 0
    local real_count = source.get_item_count(name)
    if real_count < count then
        count = real_count
    end
    if maximum_count then
        local delta_count = maximum_count - destination.get_item_count(name)
        if count > delta_count then
            count = delta_count
        end
    end
    if count > 0 then
        return transfer_item_unchecked(source, destination, name, count)
    else
        return count
    end
end

--- 尽可能把 source 的物品传送到 destination
function Inventory.transfer_inventory(source, destination, filter_array)
    local transfer_count_table = {}
    if filter_array then
        for _, name in pairs(filter_array) do
            local count = source.get_item_count(name)
            if count > 0 then
                local transfer_count = transfer_item_unchecked(source, destination, name, count)
                transfer_count_table[name] = transfer_count
            end
        end
    else
        for name, count in pairs(source.get_contents()) do
            local transfer_count = transfer_item_unchecked(source, destination, name, count)
            transfer_count_table[name] = transfer_count
        end
    end
    return transfer_count_table
end

function Inventory.collect_items(collector, providers, items)
    local to_inv = Inventory.get_main_inventory(collector)
    for _, provider in pairs(providers) do
        local from_inv = Inventory.get_main_inventory(provider)
        if from_inv then
            Inventory.transfer_inventory(from_inv, to_inv, items)
        end
    end
end

--- 发子弹、装备等，item_spec = { item = maximum_count }，maximum_count 指定发布的最大数值
--function Inventory.distribute_armoury(distributor, consumers, item_spec)
--    local from_inv = Inventory.get_main_inventory(distributor)
--    for _, consumer in pairs(consumers) do
--        local inv_map = ENTITY_ITEM_TYPE_INVENTORY_MAP[consumer.type]
--        for item_name, count in pairs(item_spec) do
--            local item = game.item_prototypes[item_name]
--            local to_inv_id = inv_map[item.type]
--            if to_inv_id then
--                local to_inv = consumer.get_inventory(to_inv_id)
--                Inventory.transfer_item(from_inv, to_inv, item_name, count)
--            end
--        end
--    end
--end

--- 交换两车物品，设置过滤器的格式作输入，其余的作输出
-- 可以尝试做多载具物品交换，一般化之
function Inventory.exchange_car_inventory(inv1, inv2)
    -- 目前这种实现只能处理简单的整堆传送
    local providedItemStack1 = {}
    local requestItemStack1 = {}
    for i=1, #inv1 do
        local filter_name = inv1.get_filter(i)
        if filter_name then
            -- 统计需要的物品
            local stack = inv1[i]
            if stack.count == 0 then
                Table.insert(requestItemStack1, {name=filter_name, stack=stack})
            end
        else
            -- 统计可提供物品
            local stack = inv1[i]
            if stack.valid_for_read then
                local pl = providedItemStack1[stack.name]
                if not pl then
                    pl = {}
                    providedItemStack1[stack.name] = pl
                end
                Table.insert(pl, stack)
            end
        end
    end

    local providedItemStack2 = {}
    local requestItemStack2 = {}
    for i=1, #inv2 do
        local filter_name = inv2.get_filter(i)
        if filter_name then
            -- 统计需要的物品
            local stack = inv2[i]
            if stack.count == 0 then
                Table.insert(requestItemStack2, {name=filter_name, stack=stack})
            end
        else
            -- 统计可提供物品
            local stack = inv2[i]
            if stack.valid_for_read then
                local pl = providedItemStack2[stack.name]
                if not pl then
                    pl = {}
                    providedItemStack2[stack.name] = pl
                end
                Table.insert(pl, stack)
            end
        end
    end

    -- transfer item stack
    for _, t in ipairs(requestItemStack1) do
        local name, stack = t.name, t.stack
        local stack_list = providedItemStack2[name]
        if stack_list and not Table.is_empty(stack_list) then
            local p_stack = Table.remove(stack_list)
            stack.transfer_stack(p_stack)
        end
    end

    for _, t in pairs(requestItemStack2) do
        local name, stack = t.name, t.stack
        local stack_list = providedItemStack1[name]
        if stack_list and not Table.is_empty(stack_list) then
            local p_stack = Table.remove(stack_list)
            stack.transfer_stack(p_stack)
        end
    end
end

--- 获取分配表
function Inventory.get_distribution_table(source, destinations, name)
    local count = source.get_item_count(name)
    local insertable_table, insertable_count = {}, 0
    for _, dest in pairs(destinations) do
        local c = dest.get_insertable_count(name)
        Table.insert(insertable_table, {
            count = c,
            destination = dest
        })
        insertable_count = insertable_count + c
    end
    local delta = 0
    if count < insertable_count then
        delta = math.floor((insertable_count - count + 0.0) / #insertable_table)
    end
    for _, entry in pairs(insertable_table) do
        entry.count = entry.count - delta
    end
    return insertable_table
end

function Inventory.distribute(source, destinations, item_name, display_flying_text)
    local insertable_table = Inventory.get_distribution_table(source, destinations, item_name)
    for _, entry in pairs(insertable_table) do
        local inserted = Inventory.transfer_item(source, entry.destination, item_name, entry.count)
        if display_flying_text and inserted > 0 then
            local entity = entry.destination.entity_owner or entry.destination.player_owner
            entity.surface.create_entity({
                name = 'flying-text',
                position = entity.position,
                text = string.format('+[img=item/%s]%d', item_name, inserted)
            })
        end
    end
end

function Inventory.consume(inventory, item, amount)
    if inventory and inventory.get_item_count(item) >= amount then
        inventory.remove({ name=item, count=amount})
        return true
    else
        return false
    end
end

function Inventory.insert_stack(inventory, items)
    local stack = inventory and inventory.find_empty_stack()
    if stack then
        local tmp_inv = game.create_inventory(1)
        tmp_inv.insert(items)
        stack.set_stack(tmp_inv[1])
        tmp_inv.destroy()
        return stack
    else
        return nil
    end
end

function Inventory.find_item_stack_by_number(inventory, item_number)
    if inventory then
        for i = 1, #inventory do
            local stack = inventory[i]
            if stack.valid_for_read and stack.item_number == item_number then
                return stack
            end
        end
    end
    return nil
end

return Inventory