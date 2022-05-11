local Entity = {}
local Table = require('klib/utils/table')
local LazyTable = require('klib/utils/lazy_table')
local StdEntity = require('stdlib/entity/entity')

Entity.has = StdEntity.has
Entity.set_indestructible = StdEntity.set_indestructible
Entity.set_frozen = StdEntity.set_frozen

--- build blueprint from blueprint string, blueprint string must be absolute aligned to grid
--- from: eradicator, url: https://forums.factorio.com/viewtopic.php?t=60584
--- @param bp_string string
--- @param surface LuaSurface
--- @param offset Position
--- @param force LuaForce
--- @param options table add to entity when created
function Entity.build_blueprint_from_string(bp_string, surface, offset, force, options)
    local bp_entity = surface.create_entity{name='item-on-ground',position=offset,stack='blueprint'}
    bp_entity.stack.import_stack(bp_string)
    local bp_entities = bp_entity.stack.get_blueprint_entities()
    bp_entity.destroy()
    for _,entity in pairs(Table.deep_copy(bp_entities)) do
        entity.position = {entity.position.x + offset.x, entity.position.y + offset.y}
        entity.force = force
        local created_entity = surface.create_entity(entity)
        if created_entity then Table.merge(created_entity, options) end
    end
end

function Entity.get_data(entity, ...)
    local data = StdEntity.get_data(entity)
    if not next({...}) then
        return data
    else
        if data ~= nil then
            return LazyTable.get(data, ...)
        else
            return nil
        end
    end
end

function Entity.set_data(entity, ...)
    local args = {...}
    if #args == 0 then
        StdEntity.set_data(entity)
    elseif #args == 1 then
        StdEntity.set_data(entity, args[1])
    else
        local data = StdEntity.get_data(entity)
        if not data then
            data = {}
            StdEntity.set_data(entity, data)
        end
        LazyTable.set(data, ...)
    end
end

function Entity.safe_teleport(entity, surface, position, radius, precision, force_to_tile_center)
    local name = entity.object_name == 'LuaPlayer' and 'character' or entity.name
    local safe_pos = surface.find_non_colliding_position(name, position, radius, precision, force_to_tile_center)
    if not safe_pos then safe_pos = position end
    entity.teleport(safe_pos, surface)
end

--- 交换两车物品，设置过滤器的格式作输入，其余的作输出
-- 可以尝试做多载具物品交换，一般化之
function Entity.exchange_car_inventory(inv1, inv2)
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

return Entity