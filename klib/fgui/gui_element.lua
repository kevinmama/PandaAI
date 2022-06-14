local Table = require 'klib/utils/table'
local LazyTable = require 'klib/utils/lazy_table'
local Type = require 'klib/utils/type'
local gui = require 'flib/gui'

local ELEM_MODS = "elem_mods"
local STYLE_MODS = "style_mods"
local ACTIONS = "actions"
local ON_CLICK = "on_click"
local ON_SELECTED_TAB_CHANGED = "on_selected_tab_changed"

local GE = {}

function GE.get_player(event)
    return game.get_player(event.player_index)
end

function GE.is_element(element)
    return element and element.object_name == 'LuaGuiElement'
end

function GE.set_action(structure, event_type, action_name)
    LazyTable.set(structure, ACTIONS, event_type, action_name)
end

function GE.set_action_if_absent(structure, event_type, action_name)
    LazyTable.set_if_absent(structure, ACTIONS, event_type, action_name)
end

function GE.table(component, style, column_count, ref, options, children)
    local structure = Table.merge({
        type = 'table',
        style = style,
        column_count = column_count,
        ref = ref,
        children = children
    }, options or {})
    if component then component:set_component_tag(structure) end
    return structure
end

function GE.column_alignments(table, column_alignments)
    local is_same = Type.is_string(column_alignments)
    for i = 1, table.column_count do
        table.style.column_alignments[i] = is_same and column_alignments or column_alignments[i]
    end
end

-- updater = {records=, next=, create_row=, update_row=}
function GE.update_table(table, updater)
    local children = table.children
    local column_count = updater.column_count or table.column_count
    local row = (updater.skip_row or 0) + 1
    local function update_row(key, record)
        local child = children[row *column_count]
        if child then
            local elems = {}
            for col = 1, column_count do
                Table.insert(elems, children[(row-1)*column_count + col])
            end
            updater.update_row(elems, row, key, record)
        else
            updater.create_row(table, row, key, record)
        end
        row = row + 1
    end

    if updater.records then
        for key, record in pairs(updater.records) do
            update_row(key, record)
        end
    elseif updater.next_row then
        local key, record = updater.next_row(row)
        while key or record do
            update_row(key, record)
            key, record = updater.next_row(row)
        end
    end
    for j = (row-1)*column_count + 1, #children do
        children[j].destroy()
    end
end

function GE.label(caption, style, style_mods, options)
    return Table.merge({type = 'label', caption = caption, style = style, style_mods = style_mods}, options or {})
end

function GE.editable_label(component, options)
    local structure = GE.flow(false, nil, {
        GE.label(options.caption, options.style, options.style_mods, {
            ref = options.ref,
            tooltip = options.tooltip,
            actions = {
                on_click = options.on_edit
            },
            tags = options.tags
        }),
        GE.textfield(component, options.textfield_style,
                options.textfield_ref, options.on_submit, {
            style_mods = options.textfield_style_mods,
            elem_mods = Table.merge({visible = false}, options.textfield_elem_mods or {}),
            tags = options.textfield_tags
        }),
    })
    if component then component:set_component_tag(structure.children[1]) end
    return structure
end

function GE.frame(vertical, style, ref, options, children)
    return Table.merge({
        type = 'frame',
        direction = vertical == true and 'vertical' or 'horizontal',
        style = style,
        ref = ref,
        children = children
    }, options or {})
end

function GE.flow(vertical, options, children)
    local structure = Table.merge({
        type = 'flow',
        direction = vertical == true and 'vertical' or 'horizontal',
        children = children
    }, options)
    if not vertical then
        LazyTable.set_if_absent(structure, "style_mods", "vertical_align", "center")
    end
    return structure
end

function GE.hr(options)
    return Table.merge({
        type = "line", style = "line", style_mods = {top_margin = 4, bottom_margin = 4}
    }, options or {})
end

function GE.placeholder(n)
    local placeholder = { type = "empty-widget" }
    local t = {}
    for _ = 1, n do
        Table.insert(t, placeholder)
    end
    return unpack(t)
end

function GE.fill_horizontally(options)
    return Table.merge({
        type = "empty-widget",
        style_mods = {horizontally_stretchable = true},
        ignored_by_interaction = true
    }, options or {})
end

function GE.drag_widget(options)
    return Table.merge({
        type = "empty-widget",
        style = "draggable_space",
        style_mods = {horizontally_stretchable=true},
        ignored_by_interaction = true
    }, options or {})
end

function GE.h1(caption, style_mods, options)
    return Table.merge({type="label", caption=caption, style = "heading_1_label", style_mods=style_mods}, options or {})
end

function GE.h2(caption, style_mods, options)
    return Table.merge({type="label", caption=caption, style = "heading_2_label", style_mods=style_mods}, options or {})
end

function GE.h3(caption, style_mods, options)
    return Table.merge({type="label", caption=caption, style = "heading_3_label", style_mods=style_mods}, options or {})
end

function GE.textfield(component, style, ref, on_confirmed, options)
    local structure = Table.merge({
        type = "textfield",
        style = style,
        ref = ref,
        actions = {
            on_confirmed = on_confirmed
        }
    }, options or {})
    if component then component:set_component_tag(structure) end
    return structure
end

function GE.drop_down(style, ref, on_selection_state_changed, options)
    return Table.merge({
        type = 'drop-down',
        style = style,
        ref = ref,
        actions = {
            on_selection_state_changed = on_selection_state_changed
        }
    }, options or {})
end

function GE.list_box(component, style, ref, on_selection_state_changed, options)
    local structure = Table.merge({
        type = 'list-box',
        style = style,
        ref = ref,
        actions = {
            on_selection_state_changed = on_selection_state_changed
        }
    }, options or {})
    if component then component:set_component_tag(structure) end
    return structure
end

--- update drop-down or list-box
function GE.update_items(elem, updater)
    elem.clear_items()
    local ids = {}
    local i = 1
    local function update_item(key, record)
        local caption, id = updater.update(i, key, record)
        elem.add_item(caption)
        ids[i] = id
        i = i + 1
    end
    if updater.records then
        for key, record in pairs(updater.records) do
            update_item(key, record)
        end
    elseif updater.next then
        local key, record = updater.next()
        while key or record do
            update_item(key, record)
            key, record = updater.next(key)
        end
    end
    gui.update_tags(elem, {[updater.tag or "ids"] = ids})
end

function GE.checkbox(component, caption, style, state, ref, on_checked_state_changed, options)
    local structure = Table.merge({
        type = "checkbox",
        caption = caption,
        style = style,
        state = state,
        ref = ref,
    }, options or {})
    if component then component:set_component_tag(structure) end
    if on_checked_state_changed then GE.set_action_if_absent(structure, "on_checked_state_changed", on_checked_state_changed) end
    return structure
end

function GE.button(component, caption, style, tooltip, on_click, options)
    local structure = Table.merge({
        type = 'button',
        caption = caption,
        style = style,
        tooltip = tooltip,
    }, options or {})
    if component then component:set_component_tag(structure) end
    if on_click then GE.set_action_if_absent(structure, ON_CLICK, on_click) end
    return structure
end

function GE.sprite_button(component, sprite, style, tooltip, on_click, options)
    local structure = Table.merge({
        type = "sprite-button",
        sprite = sprite,
        style = style or "tool_button",
        tooltip = tooltip,
        mouse_button_filter = {"left", "right"},
    }, options or {})
    if on_click then GE.set_action_if_absent(structure, ON_CLICK, on_click) end
    if component then component:set_component_tag(structure) end
    return structure
end

function GE.progressbar(style, style_mods, ref, options)
    return Table.merge({
        type = "progressbar",
        style = style,
        style_mods = style_mods,
        ref = ref,
    }, options or {})
end

function GE.tabbed_pane(component, style, ref, on_selected_tab_changed, options)
    local structure = Table.merge({
        type = "tabbed-pane",
        style = style,
        ref = ref,
        tabs = {}
    }, options or {})
    if component then component:set_component_tag(structure) end
    LazyTable.set_if_absent(structure, STYLE_MODS, "horizontally_stretchable", true)
    if on_selected_tab_changed then
        GE.set_action_if_absent(structure, ON_SELECTED_TAB_CHANGED, on_selected_tab_changed)
    end
    return structure
end

function GE.scroll_pane(vertical, style, horizontal_scroll_policy, vertical_scroll_policy, options, children)
    return Table.merge({
        type = "scroll-pane",
        direction = vertical and "vertical" or "horizontal",
        style = style,
        horizontal_scroll_policy = horizontal_scroll_policy,
        vertical_scroll_policy = vertical_scroll_policy,
        children = children
    }, options or {})
end

return GE