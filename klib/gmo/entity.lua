local CollisionMaskUtil = require '__core__/lualib/collision-mask-util'
local Table = require('klib/utils/table')
local Type = require 'klib/utils/type'
local LazyTable = require('klib/utils/lazy_table')
local StdEntity = require('stdlib/entity/entity')

local Inventory = require 'klib/gmo/inventory'
local Position = require 'klib/gmo/position'
local Area = require 'klib/gmo/area'

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

function Entity.find_safe_pos(entity, position, surface, radius, precision, force_to_tile_center)
    local name = entity.object_name == 'LuaPlayer' and 'character' or entity.name
    surface = surface or entity.surface
    return surface.find_non_colliding_position(name, position, radius, precision, force_to_tile_center) or position
end

function Entity.safe_teleport(entity, position, surface, radius, precision, force_to_tile_center)
    surface = surface or entity.surface
    local safe_pos = Entity.find_safe_pos(entity, position, surface, radius, precision, force_to_tile_center)
    if entity.surface == surface then
        return entity.teleport(safe_pos)
    else
        return entity.teleport(safe_pos, surface)
    end
end

function Entity.safe_clone(entity, position, surface, radius, precision, force_to_tile_center)
    surface = surface or entity.surface
    local safe_pos = Entity.find_safe_pos(entity, position, surface, radius, precision, force_to_tile_center)
    return entity.clone({
        position = safe_pos,
        surface = surface,
        force = entity.force
    })
end

function Entity.teleport(entity, position, surface)
    if not entity or not entity.valid then return false end
    surface = surface or entity.surface
    local teleported
    if surface == entity.surface then
        teleported = entity.teleport(position)
    else
        teleported = entity.teleport(position, surface)
    end
    if teleported then
        return true, entity
    else
        -- try clone
        local cloned_entity = entity.clone({
            position = Position.center(position),
            surface = surface,
            force = entity.force,
        })
        if cloned_entity then
            teleported = true
            Entity.copy_circuit_connections(entity, cloned_entity)
            entity.destroy({raise_destroy=true})
            return true, cloned_entity
        else
            return false
        end
    end
end

--- 传送带不能用 teleport 函数 (unsafe)
function Entity.teleport_by_blueprint(entity, surface, position)
    local bp_entity = surface.create_entity{name='item-on-ground',position=position,stack='blueprint'}
    if not bp_entity then return false end
    bp_entity.stack.create_blueprint({
        surface = surface,
        force = entity.force,
        area = entity.bounding_box,
        --always_include_tiles = true,
        include_entities = true,
        include_modules = true,
        include_station_names = true,
        include_trains = true,
        include_fuel = true
    })
    local ghosts = bp_entity.stack.build_blueprint({
        surface = surface, force = entity.force, position = position,
        force_build = true, skip_fog_of_war = false, by_player = entity.last_user
    })
    bp_entity.destroy()
    -- 只建造被传送的实体
    for _, ghost in ipairs(ghosts) do
        if entity.name ~= 'entity-ghost' and entity ~= 'tile-ghost' then
            -- 实体非ghost
            if ghost.ghost_name == entity.name then
                local _, created_entity = ghost.revive()
                if created_entity and (entity.type == 'transport-belt' or entity.type == 'loader') then
                    -- 这个方法是没用的，只能用 die() 再把地上的东西传送出去
                    --Entity.clone_transport_line(entity, created_entity)
                    entity.die()
                end
                return true
            else
                ghost.destroy()
            end
        else
            -- 实体为ghost
            if ghost.ghost_name ~= entity.ghost_name then
                ghost.destroy()
            else
                return true
            end
        end
    end
    return false
end

function Entity.copy_circuit_connections(from, to)
    local definitions = from.circuit_connection_definitions
    if definitions then
        for _, definition in pairs(definitions) do
            to.connect_neighbour(definition)
        end
    end
end

-- Entity.teleport_area({
--          from_surface=,
--          from_center=,
--          to_surface=,
--          to_center=,
--          dimensions=,
--          inside=,
--          entity_finder=,
--          entity_filter=,
--          teleport_filter=,
-- 用来修复外部引用
--          on_teleported=,
--          on_cloned=,
-- 克隆及传送的实体都会被调用
--          on_success=,
--          on_failed=,
-- })
--- 能处理带子的区域传送
function Entity.teleport_area(params)
    local from_center = params.round and params.round(params.from_center) or Position.round_to_even(params.from_center)
    local to_center = params.round and params.round(params.to_center) or Position.round_to_even(params.to_center)
    local from_surface = params.from_surface
    local to_surface = params.to_surface or params.from_surface
    local from_area = Area.from_dimensions(params.dimensions, from_center, params.inside)
    local entities
    if params.entities_finder then
        entities = params.entities_finder(from_area)
    else
        entities = from_surface.find_entities_filtered(Table.merge({
            area = from_area
        }, params.entity_filter or {}))
    end
    local teleport_filter = params.teleport_filter
    local on_teleported = params.on_teleported
    local on_cloned = params.on_cloned
    local on_failed = params.on_failed
    local on_success = params.on_success

    local clone_map = {}
    local teleport_map = {}
    local same_surface = from_surface == to_surface

    -- 传送或克隆
    local count = Table.size(entities)
    local i = 0
    for _, entity in pairs(entities) do
        i = i + 1
        local should_teleport
        if teleport_filter then
            should_teleport = entity.valid and teleport_filter(entity)
        else
            should_teleport = entity.valid
        end
        if should_teleport then
            if i < count and ROLLING_STOCK[entity.name] then
                Table.insert(entities, entity)
            else
                local entity_position = entity.position
                local pos = { x= to_center.x+entity_position.x- from_center.x, y= to_center.y+entity_position.y- from_center.y}
                local teleported
                if same_surface then
                    teleported = entity.teleport(pos)
                else
                    teleported = entity.teleport(pos, to_surface)
                end

                if teleported then
                    teleport_map[entity] = entity_position
                else
                    local clone_entity = entity.clone({ position = pos, surface = to_surface, force = entity.force })
                    if clone_entity then
                        clone_map[entity] = clone_entity
                    else
                        if on_failed then on_failed(entity) end
                    end
                end
            end
        end
    end

    -- 修复克隆体连接
    for entity, clone in pairs(clone_map) do
        local definitions = entity.circuit_connection_definitions
        if definitions then
            for _, definition in pairs(definitions) do
                local target_entity = clone_map[definition.target_entity] or definition.target_entity
                if clone.surface == target_entity.surface and clone.can_wires_reach(target_entity) then
                    definition.target_entity = target_entity
                    clone.connect_neighbour(definition)
                end
            end
        end
        -- 修复火车自动
        if entity.train then
            clone.train.manual_mode = entity.train.manual_mode
        end
    end

    for entity, clone in pairs(clone_map) do
        if on_cloned then on_cloned(entity, clone) end
        if on_success then on_success(entity) end
        if entity.destroy({raise_destroy=true}) then
            clone_map[entity] = nil
        end
    end
    -- 处理掉火车留下的铁轨
    for entity, _ in pairs(clone_map) do
        entity.destroy({raise_destroy=true})
    end

    -- 更新传送连接
    for entity, from_position in pairs(teleport_map) do
        Entity.disconnect_unreachable_neighbours(entity)
        if on_teleported then on_teleported(entity, from_position, from_surface) end
        if on_success then on_success(entity) end
    end
end

function Entity.disconnect_unreachable_neighbours(entity)
    local neighbours_map
    if entity.type == 'electric-pole' then
        neighbours_map = entity.neighbours
    else
        neighbours_map = entity.circuit_connected_entities
    end
    if neighbours_map then
        for wire_name, neighbours in pairs(neighbours_map) do
            for _, neighbour in pairs(neighbours) do
                if entity.surface == neighbour.surface and not entity.can_wires_reach(neighbour) then
                    Entity.disconnect_neighbour(entity, neighbour, wire_name)
                end
            end
        end
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

--- invalid stack
function Entity.preserve_transport_line_item_and_destroy(entity)
    local position, surface, force = entity.position, entity.surface, entity.force
    local stacks = {}
    for i=1, entity.get_max_transport_line_index() do
        local line = entity.get_transport_line(i)
        for j=1, #line do
            Table.insert(stacks, line[j])
        end
    end
    entity.die()
    if not Table.is_empty(stacks) then
        local entity = surface.create_entity({name = 'wooden-chest', position = position, force = force})
        local inventory = entity.get_inventory(defines.inventory.chest)
        for _, stack in pairs(stacks) do
            local empty_stack = inventory.find_empty_stack()
            if empty_stack then
                empty_stack.transfer_stack(stack)
            end
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

local function parse_wires(wires)
    if wires == nil then
        wires = COPPER_WIRES
    elseif wires == "all" then
        wires = ALL_WIRES
    elseif Type.is_string(wires) then
        wires = {defines.wire_type[wires]}
    else
        for index, wire in pairs(wires) do
            if Type.is_string(wire) then
                wires[index] = defines.wire_type[wire]
            end
        end
    end
    return wires
end

--- 仅适合来源和目标都只有一个接线点
function Entity.connect_neighbour(entity, target, wires)
    wires = parse_wires(wires)
    for _, wire in pairs(wires) do
        entity.connect_neighbour({ wire = wire, target_entity = target })
    end
end

function Entity.disconnect_neighbour(entity, target, wires)
    wires = parse_wires(wires)
    for _, wire in pairs(wires) do
        entity.disconnect_neighbour({ wire = wire, target_entity = target })
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
    local find_radius, find_precision, force_to_tile_center = entity_spec.find_radius or 8, entity_spec.find_precision or 1, entity_spec.force_to_tile_center or false
    local safe_pos = surface.find_non_colliding_position(entity_spec.name, entity_spec.position, find_radius, find_precision, force_to_tile_center) or entity_spec.position
    local create_entity_params = Table.dictionary_merge( { position = safe_pos}, entity_spec)
    create_entity_params.find_radius, create_entity_params.find_precision, create_entity_params.force_to_tile_center = nil, nil, nil
    local unit = surface.create_entity(create_entity_params)
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
    return prototype and prototype.type == 'resource' and prototype.resource_category == 'basic-fluid'
end

function Entity.is_entity(entity)
    return entity ~= nil and entity.object_name == 'LuaEntity'
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

function Entity.die_without_corpse_and_ghost(entity, force)
    if not entity then return false end
    if force then
        Entity.set_indestructible(entity, false)
    end
    local surface, area = entity.surface, entity.bounding_box
    local died = entity.die()
    local stuffs = surface.find_entities_filtered({ type = { 'corpse', 'entity-ghost'}, area = area })
    for _, stuff in pairs(stuffs) do
        stuff.destroy()
    end
    return died
end

function Entity.can_build_reach(builder, entity)
    return Position.distance_squared(builder.position, entity.position) <= builder.build_distance^2
end

function Entity.get_resource_entity_prototypes()
    return game.get_filtered_entity_prototypes({{ filter = "type", type = "resource" }})
end

function Entity.is_valid(entity)
    return entity and entity.valid
end

return Entity