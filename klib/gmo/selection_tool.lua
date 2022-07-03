local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'
local LazyTable = require 'klib/utils/lazy_table'
local Player = require 'klib/gmo/player'
local Inventory = require 'klib/gmo/inventory'
local Command = require 'klib/gmo/command'

local SelectionTool = {}
local dispatchers = {{}, {}, {}}
local registry

local SELECT_MODE = 1
local ALT_SELECT_MODE = 2
local REVERSE_SELECT_MODE = 3
SelectionTool.ALL_MODES = { SELECT_MODE, ALT_SELECT_MODE, REVERSE_SELECT_MODE}
SelectionTool.SELECT_MODE = SELECT_MODE
SelectionTool.ALT_SELECT_MODE = ALT_SELECT_MODE
SelectionTool.REVERSE_SELECT_MODE = REVERSE_SELECT_MODE

local ST_ITEM = 'selection-tool'
local QB_ITEM = 'spidertron-remote'

--------------------------------------------------------------------------------
--- API
--------------------------------------------------------------------------------

local last_id = 0
function SelectionTool.generate_type_id()
    last_id = last_id + 1
    return last_id
end

function SelectionTool.register_selection(type, handler)
    --dispatchers[SELECT_MODE][type] = handler
    LazyTable.insert(dispatchers[SELECT_MODE], type, handler)
end
function SelectionTool.register_alt_selection(type, handler)
    --dispatchers[ALT_SELECT_MODE][type] = handler
    LazyTable.insert(dispatchers[ALT_SELECT_MODE], type, handler)
end
function SelectionTool.register_reverse_selection(type, handler)
    --dispatchers[REVERSE_SELECT_MODE][type] = handler
    LazyTable.insert(dispatchers[REVERSE_SELECT_MODE], type, handler)
end
function SelectionTool.register_selections(modes, type, handler)
    for _, mode in pairs(modes) do
        if 1 <= mode and mode <= 3 then
            LazyTable.insert(dispatchers[mode], type, handler)
        else
            error("selection mode must be SELECT (1), ALT_SELECT (2) or REVERSE_SELECT (3)")
        end
    end
end

function SelectionTool.pick_selection_tool(player, force)
    local success, cursor_stack = Player.set_cursor_stack(player, ST_ITEM, not force)
    if not success then
        player.print({"klib.cannot_pick_selection_tool"})
    end
    return success, cursor_stack
end

function SelectionTool.start_selection(player, type, tags, options)
    options = options or {}
    local picked, stack = SelectionTool.pick_selection_tool(player, options.force)
    if picked then
        registry:set_selection_state({
            player_index = player.index,
            type = type,
            tags = tags,
            auto_destroy = options.auto_destroy
        })
        return true, stack
    else
        return false
    end
end

function SelectionTool.get_selection_state(player)
    local state = registry:get_selection_state_for_player(player, true)
    if state then
        return state.type, state.tags
    end
end

function SelectionTool.update_selection_tags(player, tags)
    local state = registry:get_selection_state_for_player(player, true)
    if state then
        if not state.tags then state.tags = {} end
        Table.merge(state.tags, tags or {})
    end
end

--------------------------------------------------------------------------------
--- auto destroy events
--------------------------------------------------------------------------------

local function clear_selection_tool_from_inventory(inventory)
    local cleared = false
    if inventory then
        for i = 1, #inventory do
            local stack = inventory[i]
            if stack and stack.valid_for_read and stack.name == ST_ITEM then
                local state = registry:get_selection_state(stack.item_number)
                if not state then
                    stack.clear()
                    cleared = true
                end
            end
        end
    end
    return cleared
end

local function update_auto_destroy_selection_tool(player)
    if registry.should_auto_destroys[player.index] then
        if clear_selection_tool_from_inventory(player.get_main_inventory()) then
            registry:clear_selection_state(-player.index)
        end
    end

    local state = registry:get_selection_state_for_player(player)
    registry.should_auto_destroys[player.index] = state and state.auto_destroy
end

Event.register(defines.events.on_player_dropped_item, function(event)
    local stack = event.entity.stack
    if stack.name == ST_ITEM then
        registry:clear_selection_state(stack.item_number)
        registry:clear_selection_state(-event.player_index)
        event.entity.destroy()
    elseif stack.name == QB_ITEM then
        local state = registry:get_selection_state(stack.item_number)
        if state then
            registry:clear_selection_state(stack.item_number)
            event.entity.destroy()
        end
    end
end)

--Event.register(defines.events.on_player_fast_transferred, function(event)
--    if registry.should_auto_destroys[event.player_index] then
--        clear_selection_tool_from_inventory(Inventory.get_main_inventory(event.entity))
--        registry:clear_selection_state(-event.player_index)
--    end
--end)

--------------------------------------------------------------------------------
--- Selection event dispatcher
--------------------------------------------------------------------------------

local function dispatch_selection_event(mode, event)
    if event.item == ST_ITEM then
        local player = game.get_player(event.player_index)
        local type, tags = SelectionTool.get_selection_state(player)
        local handlers = type and dispatchers[mode][type]
        if handlers then
            event.mode = mode
            event.type = type
            for _, handler in pairs(handlers) do
                handler(Table.merge({
                    tags = Table.deepcopy(tags)
                }, event))
            end
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

--------------------------------------------------------------------------------
--- quick bar
--------------------------------------------------------------------------------

local function fix_quick_bar_selection_tool(player, stack)
    if not stack then return end
    local i = 1
    while true do
        local page = player.get_active_quick_bar_page(i)
        if not page then return else i = i + 1 end
        local offset = 10 * (page - 1)
        for j = offset + 1, offset + 10 do
            local prototype = player.get_quick_bar_slot(j)
            if prototype and prototype.name == ST_ITEM then
                player.set_quick_bar_slot(j, stack)
                return
            end
        end
    end
end

local function create_quick_bar_selection_tool(player, state)
    local quick_bar_stack = Inventory.insert_stack(player.get_main_inventory(), QB_ITEM)
    if quick_bar_stack then
        registry:set_quick_bar_state(quick_bar_stack.item_number, state)
        state.quick_bar = quick_bar_stack.item_number
        fix_quick_bar_selection_tool(player, quick_bar_stack)
    end
end

local function on_player_set_quick_bar_slot(event)
    local player = game.get_player(event.player_index)
    local state = registry:get_selection_state_for_player(player, true)
    if state then
        if not state.quick_bar then
            create_quick_bar_selection_tool(player, state)
        else
            local stack = Inventory.find_item_stack_by_number(player.get_main_inventory(), state.quick_bar)
            fix_quick_bar_selection_tool(player, stack)
        end
    end
end

Event.register(defines.events.on_player_set_quick_bar_slot, on_player_set_quick_bar_slot)


local function pick_quick_bar_selection_tool(player)
    local state = registry:get_quick_bar_state_for_player(player, true)
    if state then
        local picked, stack = SelectionTool.pick_selection_tool(player)
        if picked then
            registry:set_selection_state(state.auto_destroy and -player.index or stack.item_number, state)
        end
    end
end

--------------------------------------------------------------------------------
--- Selection Registry
--------------------------------------------------------------------------------

local Registry = KC.singleton("klib.gmo.SelectionTool$Registry", function(self)
    -- player_index -> boolean
    self.should_auto_destroys = {}
    -- 持久选择器 item_number -> selection_state， 自动销毁的 -player_index -> selection_state
    self.selection_states = {}
end)

function Registry:on_ready()
    registry = self
end

local function mark_state_by_stack(states, stack)
    local item_number = stack and stack.valid_for_read and stack.item_number
    local state = item_number and states[item_number]
    if state then state.exists = true end
end

-- 清理所有不在玩家身上的选择器或工具
function Registry:destroy_invalid_states()
    local total = 0
    local destroyed = 0
    local group = Table.group_by(self.selection_states, "player_index")
    for player_index, states in pairs(group) do
        local player = game.get_player(player_index)
        if player then
            local state = states[-player.index]
            if state then state.exists = true end
            mark_state_by_stack(states, player.cursor_stack)
            local inventory = player.get_main_inventory()
            if inventory then
                for i = 1, #inventory do
                    mark_state_by_stack(states, inventory[i])
                end
            end
        end
        for key, state in pairs(states) do
            total = total + 1
            if state.exists then
                state.exists = nil
            else
                self.selection_states[key] = nil
                destroyed = destroyed + 1
            end
        end
    end
    game.print({"klib.destroy_invalid_selection_states", total, destroyed})
end

function Registry:get_selection_state(item_number)
    return self.selection_states[item_number]
end

function Registry:get_selection_state_for_player(player, check)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == ST_ITEM then
        local state = self.selection_states[cursor_stack.item_number] or self.selection_states[-player.index]
        if not check or (state and state.player_index == player.index) then
            return state
        end
    end
    return nil
end

function Registry:set_selection_state(params, state)
    if Type.is_table(params) then
        local index
        local auto_destroy = params.auto_destroy
        if auto_destroy == nil then auto_destroy = true end
        if auto_destroy then
            index = - params.player_index
        else
            index = params.item_number or game.get_player(params.player_index).cursor_stack.item_number
        end
        self.selection_states[index] = {
            player_index = params.player_index,
            auto_destroy = auto_destroy,
            type = params.type,
            tags = params.tags
        }
    else
        self.selection_states[params] = state
    end
end

function Registry:clear_selection_state(item_number)
    self.selection_states[item_number]= nil
end

function Registry:get_quick_bar_state_for_player(player, check)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == QB_ITEM then
        local state = self.selection_states[cursor_stack.item_number]
        if not check or (state and state.player_index == player.index) then
            return state
        end
    end
    return nil
end

function Registry:set_quick_bar_state(item_number, state)
    self.selection_states[item_number] = state
end

--------------------------------------------------------------------------------
--- Events
--------------------------------------------------------------------------------

Event.register(defines.events.on_player_cursor_stack_changed, function(event)
    local player = game.get_player(event.player_index)
    update_auto_destroy_selection_tool(player)
    pick_quick_bar_selection_tool(player)
end)

-- 每天清一次
Event.on_nth_tick(24*60*3600, function()
--Event.on_nth_tick(60, function()
    registry:destroy_invalid_states()
end)

Registry:on(defines.events.on_player_removed, function(self, event)
    self.should_auto_destroys[event.player_index] = nil
    self.selection_states[-event.player_index] = nil
end)

Command.add_admin_command('destroy-invalid-selection-states', "destroy all invalid selection states", function()
    registry:destroy_invalid_states()
end)

return SelectionTool