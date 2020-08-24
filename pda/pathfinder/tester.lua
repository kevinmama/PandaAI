local Position = require '__stdlib__/stdlib/area/position'
local Area = require '__stdlib__/stdlib/area/area'
local ColorList = require '__stdlib__/stdlib/utils/defines/color_list'
local NavMesh = require 'pda/pathfinder/navmesh'
local Tiles = require 'pda/pathfinder/pasfv/tiles'
local Tester = {}

local mesh

function Tester.test_merge_tiles(event)
    local player = game.players[event.player_index]
    local surface = player.surface
    local tiles = surface.find_tiles_filtered({
        area = Position.expand_to_area(player.position, 64),
        collision_mask = {'player-layer'}
    })
    tiles = Tiles.merge_tiles(tiles)

    for _, tile in pairs(tiles) do
        rendering.draw_rectangle({
            color = ColorList.red,
            left_top = tile.left_top,
            right_bottom = tile.right_bottom,
            surface = surface,
            filled = false,
            time_to_live = 600,
        })
    end
end

function Tester.new_world(surface)
    if mesh then
        mesh:destroy()
    end
    NavMesh:new(surface, 'player-layer')
end

return Tester
