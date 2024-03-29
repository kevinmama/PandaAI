local Table = require 'klib/utils/table'
local Area = require 'klib/gmo/area'
local Surface = {}

--Surface.swap_tiles({
--    area1=,
--    surface1=,
--    area2=,
--    surface2=,
--    swap_area=,
--    swap_surface=,
--})
--- 交换地砖
function Surface.swap_tiles(params)
    local area1 = params.area1
    local surface1 = params.surface1
    local area2 = params.area2
    local surface2 = params.surface2 or surface1
    local swap_area = params.swap_area
    local swap_surface = params.swap_surface or surface1

    local options = {
        clone_tiles = true,
        clone_entities = false,
        clone_decoratives = true,
        clear_destination_entities = false,
        clear_destination_decoratives = true,
        expand_map = true,
        create_build_effect_smoke = false,
    }

    surface1.clone_area(Table.merge({
        source_area = area1,
        destination_area = swap_area,
        destination_surface = swap_surface,
    }, options))
    surface2.clone_area(Table.merge({
        source_area = area2,
        destination_area = area1,
        destination_surface = surface1,
    }, options))
    swap_surface.clone_area(Table.merge({
        source_area = swap_area,
        destination_area = area2,
        destination_surface = surface2,
    }, options))
end

function Surface.set_tiles(surface, tile_name, area)
    local tiles = {}
    for position in Area(area):iterate(true, true) do
        Table.insert(tiles, {name = tile_name, position = position})
    end
    surface.set_tiles(tiles)
end

function Surface.clear_entities_in_area(surface, area)
    local enemies = surface.find_entities(area)
    for _, enemy in pairs(enemies) do
        enemy.destroy()
    end
end

function Surface.clear_enemies_in_area(surface, area)
    local enemies = surface.find_entities_filtered({
        force = game.forces['enemy'],
        area = area,
    })
    for _, enemy in pairs(enemies) do
        enemy.destroy()
    end
end

function Surface.has_resources(surface, area)
    return #surface.find_entities_filtered({
        type = "resource",
        area = area
    }) > 0
end

return Surface