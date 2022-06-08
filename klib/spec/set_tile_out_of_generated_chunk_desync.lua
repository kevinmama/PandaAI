script.on_nth_tick(60, function()
    game.surfaces[1].set_tiles({
        { name = 'out-of-map', position = { 32 * 100, 0 } }
    })
end)

script.on_nth_tick(300, function()
    game.surfaces[1].delete_chunk({32,0})
end)
