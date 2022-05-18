local LazyTable = require 'klib/utils/lazy_table'

local Player = {}

Player.PLAYER_TABLE_NAME = "klib_player_data"

function Player.set_data(player_index, ...)
    LazyTable.set(global, Player.PLAYER_TABLE_NAME, player_index, ...)
end

function Player.get_data(player_index, ...)
    return LazyTable.get(global, Player.PLAYER_TABLE_NAME, player_index, ...)
end

function Player.remove_data(player_index, ...)
    LazyTable.remove(global, Player.PLAYER_TABLE_NAME, player_index, ...)
end

return Player