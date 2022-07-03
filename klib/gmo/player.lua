local Config = require 'klib/config'
local LazyTable = require 'klib/utils/lazy_table'
local Registry = require 'klib/utils/registry'

local Player = {}
local registry = Registry.new_global(Config.PLAYER_REGISTRY)

function Player.set_data(player_index, ...)
    LazyTable.set(registry, player_index, ...)
end

function Player.get_data(player_index, ...)
    LazyTable.get(registry, player_index, ...)
end

function Player.remove_data(player_index, ...)
    LazyTable.remove(registry, player_index, ...)
end

function Player.set_cursor_stack(player, items, keep_current_stack)
    local cursor_stack = player.cursor_stack
    if cursor_stack then
        if cursor_stack.count ~= 0 and keep_current_stack then
            if player.hand_location then
                local back_stack = player.get_inventory(player.hand_location.inventory)[player.hand_location.slot]
                player.hand_location = nil
                back_stack.transfer_stack(player.cursor_stack)
            else
                return false
            end
        end

        local inventory = game.create_inventory(1)
        inventory.insert(items)
        cursor_stack.set_stack(inventory[1])
        inventory.destroy()
        return true, cursor_stack
    end
    return false
end

return Player