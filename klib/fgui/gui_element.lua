local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'

local GE = {}

function GE.get_player(event)
    return game.get_player(event.player_index)
end

function GE.update_table(table, updater)
    local children = table.children
    local column_count = updater.column_count or table.column_count
    local row = (updater.skip_row + 1) or 1

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
    elseif updater.next then
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
    return Table.merge({
        type = 'flow',
        direction = vertical == true and 'vertical' or 'horizontal',
        children = children
    }, options)
end

function GE.hr(options)
    return Table.merge({
        type = "line", style = "line", style_mods = {top_margin = 4, bottom_margin = 4}
    }, options or {})
end

function GE.fill_horizontally()
    return { type = "empty-widget", style_mods = {horizontally_stretchable = true}}
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

function GE.textfield(style, ref, on_confirmed, options)
    return Table.merge({
        type = "textfield",
        style = style,
        ref = ref,
        actions = {
            on_confirmed = on_confirmed
        }
    }, options or {})
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

function GE.list_box(style, ref, on_selection_state_changed, options)
    return Table.merge({
        type = 'list-box',
        style = style,
        ref = ref,
        actions = {
            on_selection_state_changed = on_selection_state_changed
        }
    }, options or {})
end

function GE.sprite_button(sprite, style, tooltip, ref, on_click, options)
    return Table.merge({
        type = "sprite-button",
        sprite = sprite,
        style = style or "tool_button",
        tooltip = tooltip,
        mouse_button_filter = {"left", "right"},
        ref = ref,
        actions = {
            on_click = on_click
        }
    }, options or {})
end

function GE.progressbar(style, style_mods, ref, options)
    return Table.merge({
        type = "progressbar",
        style = style,
        style_mods = style_mods,
        ref = ref,
    }, options or {})
end


return GE