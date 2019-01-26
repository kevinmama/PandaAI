local KHelper = {}
function KHelper.get_player_by_event(event)
    return game.players[event.player_index]
end
function KHelper.get_player_by_index(index)
    return game.players[index]
end
return KHelper
