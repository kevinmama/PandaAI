local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Inventory = require 'klib/gmo/inventory'

local SelectionTool = {
    auto_destroy_selection_tool = true
}

local dispatchers = {{}, {}, {}}
local registry
local Registry = KC.singleton("klib.gmo.SelectionTool$Registry", function(self)
    self.selections = {}
end)

local SELECT_MODE = 1
local ALT_SELECT_MODE = 2
local REVERSE_SELECT_MODE = 3
SelectionTool.ALL_MODES = { SELECT_MODE, ALT_SELECT_MODE, REVERSE_SELECT_MODE}
SelectionTool.SELECT_MODE = SELECT_MODE
SelectionTool.ALT_SELECT_MODE = ALT_SELECT_MODE
SelectionTool.REVERSE_SELECT_MODE = REVERSE_SELECT_MODE

function SelectionTool.register_selection(type, handler)
    dispatchers[SELECT_MODE][type] = handler
end
function SelectionTool.register_alt_selection(type, handler)
    dispatchers[ALT_SELECT_MODE][type] = handler
end
function SelectionTool.register_reverse_selection(type, handler)
    dispatchers[REVERSE_SELECT_MODE][type] = handler
end
function SelectionTool.register_selections(modes, type, handler)
    for _, mode in pairs(modes) do
        if 1 <= mode and mode <= 3 then
            dispatchers[mode][type] = handler
        else
            error("selection mode must be SELECT (1), ALT_SELECT (2) or REVERSE_SELECT (3)")
        end
    end
end


function SelectionTool.pick_selection_tool(player, force)
    local cursor_stack = player.cursor_stack
    if cursor_stack then
        if force or cursor_stack.count == 0 then
            local selection_tool = player.surface.create_entity({
                name = 'item-on-ground',
                stack = 'selection-tool',
                position = player.position
            })
            cursor_stack.set_stack(selection_tool.stack)
            selection_tool.destroy()
            return true
        end
    end
    player.print({"klib.cannot_pick_selection_tool"})
    return false
end

function SelectionTool.start_selection(player, type, tags, force)
    if SelectionTool.pick_selection_tool(player, force) then
        registry:set_selection_state(player.index, type, tags)
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

local function dispatch_selection_event(mode, event)
    if event.item == 'selection-tool' then
        local type, tags = registry:get_selection_state(event.player_index)
        local handler = dispatchers[mode][type]
        if handler then
            event.mode = mode
            event.type = type
            event.tags = tags
            handler(event)
        end
    end
end

Event.register(defines.events.on_player_selected_area,  function(event)
    dispatch_selection_event(SELECT_MODE, event)
end)
Event.register(defines.events.on_player_alt_selected_area,  function(event)
    dispatch_selection_event(ALT_SELECT_MODE, event)
end)
Event.register(defines.events.on_player_reverse_selected_area,  function(event)
    dispatch_selection_event(REVERSE_SELECT_MODE, event)
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

function Registry:set_selection_state(player_index, type, tags)
    self.selections[player_index] = { type, tags }
end

Registry:on(defines.events.on_player_created, function(self, event)
    self.selections[event.player_index] = {}
end)

Registry:on(defines.events.on_player_removed, function(self, event)
    self.selections[event.player_index] = nil
end)

return SelectionTool