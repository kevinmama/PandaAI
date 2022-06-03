local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'

local SelectionTool = {
    auto_destroy_selection_tool = true
}

local dispatcher = {}
local registry
local Registry = KC.singleton("klib.gmo.SelectionTool$Registry", function(self)
    self.selections = {}
end)

function SelectionTool.register_selection(mode, handler)
    -- 目前只支持 1 个
    dispatcher[mode] = handler
end

function SelectionTool.pick_selection_tool(player)
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

function SelectionTool.start_selection(player, mode, tags)
    if SelectionTool.pick_selection_tool(player) then
        registry:set_selection_state(player.index, mode, tags)
        return true
    else
        return false
    end
end

local function clear_selection_tool_from_inventory(inventory)
    if inventory then
        local stack = inventory.find_item_stack('selection-tool')
        if stack then stack.clear() end
    end
end

local function register_auto_destroy_selection_tool_event()
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

Event.register(defines.events.on_player_selected_area, function(event)
    if event.item == 'selection-tool' then
        local mode, tags = registry:get_selection_state(event.player_index)
        local handler = dispatcher[mode]
        if handler then
            event.mode = mode
            event.tags = tags
            handler(event)
        end
    end
end)

function Registry:on_ready()
    registry = self
    if SelectionTool.auto_destroy_selection_tool then
        register_auto_destroy_selection_tool_event()
    end
end

function Registry:get_selection_state(player_index)
    local state = self.selections[player_index]
    if state then
        return state[1], state[2]
    else
        return nil
    end
end

function Registry:set_selection_state(player_index, mode, tags)
    self.selections[player_index] = { mode, tags }
end

Registry:on(defines.events.on_player_created, function(self, event)
    self.selections[event.player_index] = {}
end)

Registry:on(defines.events.on_player_removed, function(self, event)
    self.selections[event.player_index] = nil
end)

return SelectionTool