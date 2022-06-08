script.on_event(defines.events.on_player_created, function(e)
    local player = game.get_player(e.player_index)
    player.insert({name="copper-plate"})
end)
script.on_event(defines.events.on_player_dropped_item, function(e)
    local player = game.get_player(e.player_index)
    if player.character then
        player.character.die()
   end
end)