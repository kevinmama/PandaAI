local LazyTable = require 'klib/utils/lazy_table'
local Event = require 'klib/event/event'
local Inventory = require 'klib/gmo/inventory'

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

local function clear_selection_tool_from_inventory(inventory)
    if inventory then
        local stack = inventory.find_item_stack('selection-tool')
        if stack then
            stack.clear()
        end
    end
end

function Player.register_auto_destroy_selection_tool_event()
    Event.register(defines.events.on_player_cursor_stack_changed, function(event)
        local player = game.get_player(event.player_index)
        clear_selection_tool_from_inventory(player.get_main_inventory())
    end)

    Event.register(defines.events.on_player_dropped_item, function(event)
        if event.entity.stack.name == 'selection-tool' then
            event.entity.destroy()
        end
    end)
    Event.register(defines.events.on_player_fast_transferred, function(event)
        clear_selection_tool_from_inventory(Inventory.get_main_inventory(event.entity))
    end)
end

function Player.pick_selection_tool(player)
    if player.cursor_stack.count > 0 then
        player.print({"klib.cannot_pick_selection_tool"})
        return false
    else
        local selection_tool = player.surface.create_entity({
            name = 'item-on-ground',
            stack = 'selection-tool',
            position = player.position
        })
        player.cursor_stack.set_stack(selection_tool.stack)
        selection_tool.destroy()
        return true
    end
end

return Player