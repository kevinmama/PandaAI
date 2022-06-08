local Area = {}
function Area.iterate(area, inside, step)
    step = step or 1
    local x, y = area.left_top.x, area.left_top.y
    local max_x = area.right_bottom.x - (inside and 0.001 or 0)
    local max_y = area.right_bottom.y - (inside and 0.001 or 0)
    local first = true

    local function iterator()
        if first then
            first = false
        elseif x <= max_x and x + step <= max_x then
            x = x + step
        elseif y <= max_y and y + step <= max_y then
            x = area.left_top.x
            y = y + step
        else
            return
        end
        return {x=x,y=y}
    end

    return iterator
end


local function fill_out_of_map_tiles(event)
    local surface, area = event.surface, event.area
    if area.right_bottom.y < 50*32 then return end
    local tiles = {}
    local tiles2 = {}
    for pos in Area.iterate(area) do
        table.insert(tiles, {name = 'out-of-map', position = pos})
        table.insert(tiles2, {name = 'concrete', position = pos})
    end
    surface.set_tiles(tiles)
    surface.set_tiles(tiles2)
    game.print("set_tiles(" .. area.left_top.x .. ',' .. area.left_top.y .. ')')
end
script.on_event(defines.events.on_chunk_generated, fill_out_of_map_tiles)

local Chunk, CHUNK_SIZE = {}, 32
function Chunk.request_to_generate_chunks(surface, area)
    for x = area.left_top.x, area.right_bottom.x, CHUNK_SIZE do
        for y = area.left_top.y, area.right_bottom.y, CHUNK_SIZE do
            surface.request_to_generate_chunks({x=x,y=y},1)
        end
    end
end

local AREA = {
    left_top = {x=0, y=32*100},
    right_bottom = {x=32*2-0.001, y=32*102-0.001}
}
script.on_nth_tick(30, function()
    local s = game.surfaces[1]
    if game.tick % 60 == 0 then
        game.print("gen chunks")
        Chunk.request_to_generate_chunks(s, AREA)
    else
        game.print("remove chunks")
        s.delete_chunk({-1,100})
        s.delete_chunk({0,100})
        s.delete_chunk({1,100})

        s.delete_chunk({-1,101})
        s.delete_chunk({0,101})
        s.delete_chunk({1,101})

        s.delete_chunk({-1,102})
        s.delete_chunk({0,102})
        s.delete_chunk({1,102})
    end
end)
