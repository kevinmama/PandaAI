local CollisionMaskUtil = require '__core__/lualib/collision-mask-util'
local Table = require('klib/utils/table')
local Type = require 'klib/utils/type'
local LazyTable = require('klib/utils/lazy_table')
local StdEntity = require('stdlib/entity/entity')

local Inventory = require 'klib/gmo/inventory'

local Entity = {}
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
function Entity.build_blueprint_from_string_old(bp_string, surface, offset, force, options)
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

local ROLLING_STOCK = {
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['artillery-wagon'] = true,
    ['fluid-wagon'] = true
}

--- Entity.build_blueprint_from_string({bp_string= , surface=, position=, force=, by_player=, properties={}}
--- Entity.build_blueprint_from_string({bp_string= , player=, properties={}}
function Entity.build_blueprint_from_string(params)
    local bp_string, player, properties =
    params.bp_string, params.player, params.properties
    local properties = params.properties
    local surface, position, force, by_player
    if player then
        surface = params.surface or player.surface
        position = params.position or player.position
        force = params.force or player.force
        by_player = params.by_player or player
    else
        surface = params.surface
        position = params.position
        force = params.force
        by_player = params.by_player
    end

    local bp = surface.create_entity {name = 'item-on-ground', position = position, force = force, stack = 'blueprint'}
    bp.stack.import_stack(bp_string)
    local ghosts = bp.stack.build_blueprint {
        surface = surface, force = force, position = position,
        force_build = true, skip_fog_of_war = false, by_player = by_player
    }
    bp.destroy()
    local count = #ghosts
    for i, ghost in ipairs(ghosts) do
        -- put rolling stock at the end.
        if i < count and ROLLING_STOCK[ghost.ghost_type] then
            ghosts[#ghosts + 1] = ghost
        else
            local _, entity = ghost.revive()
            if entity and properties then
                Table.merge(entity, properties)
            end
        end
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

local COPPER_WIRES = {defines.wire_type.copper}
local ALL_WIRES = {defines.wire_type.copper, defines.wire_type.red, defines.wire_type.green}

function Entity.connect_neighbour(entity, target, wires)
    if wires == nil then
        wires = COPPER_WIRES
    elseif wires == "all" then
        wires = ALL_WIRES
    end
    for _, wire in pairs(wires) do
        entity.connect_neighbour({ wire = wire, target_entity = target })
    end
end

--- 给单位武器装备，如果单位无法接收，则略过
function Entity.give_unit_armoury(unit, weapon_spec)
    if not weapon_spec then return end
    if unit and unit.valid then
        local gun_inventory = Inventory.get_inventory(unit, 'gun')
        local ammo_inventory = Inventory.get_inventory(unit, 'ammo')
        local main_inventory = Inventory.get_inventory(unit, 'main')
        for name, count in pairs(weapon_spec) do
            local inserted = 0
            local prototype = game.item_prototypes[name]
            local type = prototype and prototype.type
            if type == 'gun' then
                inserted = gun_inventory.insert({name=name, count=count})
            elseif type == 'ammo' then
                inserted = ammo_inventory.insert({name=name, count=count})
            elseif type == 'armor' then
                inserted = Inventory.get_inventory(unit, "armor").insert({name=name, count=count})
            elseif string.match(name, '-equipment') then
                local grid = Inventory.get_grid(unit)
                if grid then
                    for _ = 1, count do
                        if grid.put({name=name}) then
                            inserted = inserted + 1
                        end
                    end
                end
            end
            if type and count - inserted > 0 then
                main_inventory.insert({name=name, count=count-inserted})
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
    return Inventory.consume(inv, 'coin', price)
end

function Entity.create_flying_text(entity, text, props)
    return entity.surface.create_entity(Table.merge({
        name = 'flying-text',
        position = entity.position,
        text = text
    }, props))
end

function Entity.distribute_fuel(from_entity, to_entities, display_flying_text)
    local source = from_entity.get_main_inventory()
    local destinations = Table.map(to_entities, function(e) return e.get_fuel_inventory()  end)
    local prototypes = game.get_filtered_item_prototypes({ {filter = "fuel-category", ["fuel-category"] = "chemical"} })
    for name, _ in pairs(prototypes) do
        Inventory.distribute(source, destinations, name, display_flying_text)
   end
end

function Entity.distribute_smelting_ingredients(from_entity, to_entities, display_flying_text)
    local source = from_entity.get_main_inventory()
    local destinations = Table.map(to_entities, function(e) return e.get_inventory(defines.inventory.furnace_source)  end)
    local prototypes = game.get_filtered_recipe_prototypes({{filter = "category", category = "smelting"}})
    local names = {}
    Table.each(prototypes, function(prototype)
        Table.each(prototype.ingredients, function(ingredient)
            Table.insert(names, ingredient.name)
        end)
    end)
    Table.unique_values(names)
    for _, name in pairs(names) do
        Inventory.distribute(source, destinations, name, display_flying_text)
    end
end

function Entity.collect_outputs(to_entity, from_entities, display_flying_text)
    local destination = to_entity.get_main_inventory()
    local sources = Table.map(from_entities, function(e) return e.get_output_inventory()  end)
    for _, source in pairs(sources) do
        local transfer_table = Inventory.transfer_inventory(source, destination)
        if display_flying_text and not Table.is_empty(transfer_table) then
            local text = Table.reduce(transfer_table, function(text, count, name)
                return text .. string.format("-[img=item/%s]%d", name, count)
            end, "")
            local entity = source.entity_owner or source.player_owner
            Entity.create_flying_text(entity, text)
        end
    end
end

function Entity.get_resource_category(resource_name)
    return game.entity_prototypes[resource_name].resource_category
end

function Entity.is_fluid_resource(resource_name)
    local prototype = game.entity_prototypes[resource_name]
    return prototype.type == 'resource' and prototype.resource_category == 'basic-fluid'
end

function Entity.is_collides_in_position(entity_name, surface, position)
    local prototype = game.entity_prototypes[entity_name]
    local b = prototype.collision_box
    return 0 < #surface.find_entities_filtered({
        area = {
            left_top = {x = b.left_top.x + position.x, y = b.left_top.y + position.y},
            right_bottom = {x = b.right_bottom.x + position.x, y = b.right_bottom.y + position.y}
        },
        collision_mask = CollisionMaskUtil.get_mask(prototype)
    })
end

return Entity