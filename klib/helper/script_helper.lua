local ScriptHelper = {}

function ScriptHelper.each_connected_player(handler)
    for _, p in pairs(game.connected_players) do
        handler(p, _)
    end
end

function ScriptHelper.each_alive_player(handler)
    for _, player in pairs(game.connected_players) do
        if player.character ~= nil then
            handler(player, _)
        end
    end
end

function ScriptHelper.flying_text(msg, pos, color, surface)
    if color == nil then
        surface.create_entity({ name = "flying-text", position = pos, text = msg })
    else
        surface.create_entity({ name = "flying-text", position = pos, text = msg, color = color })
    end
end

return ScriptHelper