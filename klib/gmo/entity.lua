local Entity = {}
local Table = require('klib/utils/table')
local Type = require 'klib/utils/type'
local LazyTable = require('klib/utils/lazy_table')
local StdEntity = require('stdlib/entity/entity')

local Inventory = require 'klib/gmo/inventory'

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
    if entity.surface ~= surface then
        entity.teleport(safe_pos, surface)
    else
        entity.teleport(safe_pos)
    end
end

function Entity.transfer_fluid(source, destination)
    local fluidbox = source.fluidbox
    local i = 1
    for name, amount in pairs(source.get_fluid_contents()) do
        local inserted_amount = destination.insert_fluid({name = name, amount = amount, temperature = fluidbox[i].temperature})
        i = i + 1
        if inserted_amount > 0 then
            source.remove_fluid({name = name, amount = inserted_amount})
        end
    end
end

function Entity.preserve_loader_item_and_destroy(loader)
    local contents = loader.get_transport_line(1).get_contents()
    local position, surface, force = loader.position, loader.surface, loader.force
    loader.destroy()
    if not Table.is_empty(contents) then
        local entity = surface.create_entity({name = 'wooden-chest', position = position, force = force})
        local inventory = entity.get_inventory(defines.inventory.chest)
        for name, count in pairs(contents) do
            inventory.insert({name = name, count = count})
        end
    end
end

--- 使用容量最小的容器装被销毁的箱子中的物品
function Entity.preserve_chest_item_and_destroy(chest)
    local inv = chest.get_inventory(defines.inventory.chest)
    local available_slots = #inv - inv.count_empty_stacks()
    -- 检查需要用到哪个原型
    local preserve_chest_name = 'steel-chest'
    if available_slots <= game.entity_prototypes['wooden-chest'].get_inventory_size(defines.inventory.chest) then
        preserve_chest_name = 'wooden-chest'
    elseif available_slots <= game.entity_prototypes['iron-chest'].get_inventory_size(defines.inventory.chest) then
        preserve_chest_name = 'iron-chest'
    end
    local contents = inv.get_contents()
    local position, surface, force = chest.position, chest.surface, chest.force
    chest.destroy()

    if not Table.is_empty(contents) then
        local entity = surface.create_entity({name = preserve_chest_name, position = position, force = force})
        local inventory = entity.get_inventory(defines.inventory.chest)
        for name, count in pairs(contents) do
            inventory.insert({name = name, count = count})
        end
    end
end

function Entity.connect_neighbour(entity, target, wires)
    for _, wire in pairs(wires) do
        entity.connect_neighbour({
            wire = defines.wire_type[wire],
            target_entity = target
        })
    end
end

--- 给单位武器装备，如果单位无法接收，则略过
function Entity.give_unit_armoury(unit, weapon_spec)
    if unit and unit.valid and unit.type == 'character' then
        local gun_inventory = unit.get_inventory(defines.inventory.character_guns)
        local ammo_inventory = unit.get_inventory(defines.inventory.character_ammo)
        for name, count in pairs(weapon_spec) do
            local inserted = 0
            local prototype = game.item_prototypes[name]
            local type = prototype and prototype.type
            if type == 'gun' then
                inserted = gun_inventory.insert({name=name, count=count})
            elseif type == 'ammo' then
                inserted = ammo_inventory.insert({name=name, count=count})
            elseif type == 'armor' then
                inserted = unit.get_inventory(defines.inventory.character_armor).insert({name=name, count=count})
            elseif string.match(name, '-equipment') then
                local armor_inventory = unit.get_inventory(defines.inventory.character_armor)
                local grid = armor_inventory and armor_inventory[1] and armor_inventory[1].grid
                if grid then
                    for _ = 1, count do
                        if grid.put({name=name}) then
                            inserted = inserted + 1
                        end
                    end
                end
            end
            if type and count - inserted > 0 then
                local item_inventory = unit.get_inventory(defines.inventory.character_main)
                item_inventory.insert({name=name, count=count-inserted})
            end
        end
    end
end

function Entity.give_entity_items(entity, item_spec)
    if entity and entity.valid then
        local inventory = Inventory.get_main_inventory(entity)
        if inventory then
            for name, count in pairs(item_spec) do
                inventory.insert({name = name, count = count})
            end
        end
    end
end

function Entity.create_unit(surface, entity_spec, weapon_spec, armor_spec, item_spec)
    local safe_pos = surface.find_non_colliding_position(entity_spec.name, entity_spec.position, 8, 1) or entity_spec.position
    local unit = surface.create_entity(Table.dictionary_merge( {position = safe_pos}, entity_spec))
    Entity.give_unit_armoury(unit, weapon_spec)
    return unit
end

function Entity.buy(entity, price)
    local inv = entity.get_inventory(defines.inventory.character_main)
    if inv.get_item_count('coin') >= price then
        inv.remove({name='coin', count=price})
        return true
    else
        return false
    end
end

return Entity