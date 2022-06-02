local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'

local GuiElement = {}

function GuiElement.get_player(event)
    return game.get_player(event.player_index)
end

function GuiElement.update_table(table, updater)
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

function GuiElement.label(caption, style, style_mods, options)
    return Table.merge({type = 'label', caption = caption, style = style, style_mods = style_mods}, options or {})
end

function GuiElement.flow(vertical, options, children)
    return Table.merge({
        type = 'flow',
        direction = vertical == true and 'vertical' or 'horizontal',
        children = children
    }, options)
end

function GuiElement.hr(options)
    return Table.merge({
        type = "line", style = "line", style_mods = {top_margin = 4, bottom_margin = 4}
    }, options or {})
end

function GuiElement.fill_horizontally()
    return { type = "empty-widget", style_mods = {horizontally_stretchable = true}}
end

function GuiElement.h1(caption, style_mods, options)
    return Table.merge({type="label", caption=caption, style = "heading_1_label", style_mods=style_mods}, options or {})
end

function GuiElement.h2(caption, style_mods, options)
    return Table.merge({type="label", caption=caption, style = "heading_2_label", style_mods=style_mods}, options or {})
end

function GuiElement.h3(caption, style_mods, options)
    return Table.merge({type="label", caption=caption, style = "heading_3_label", style_mods=style_mods}, options or {})
end

function GuiElement.textfield(style, ref, on_confirmed, options)
    return Table.merge({
        type = "textfield",
        style = style,
        ref = ref,
        actions = {
            on_confirmed = on_confirmed
        }
    }, options or {})
end

function GuiElement.drop_down(style, ref, on_selection_state_changed, options)
    return Table.merge({
        type = 'drop-down',
        style = style,
        ref = ref,
        actions = {
            on_selection_state_changed = on_selection_state_changed
        }
    }, options or {})
end

function GuiElement.list_box(style, ref, on_selection_state_changed, options)
    return Table.merge({
        type = 'list-box',
        style = style,
        ref = ref,
        actions = {
            on_selection_state_changed = on_selection_state_changed
        }
    }, options or {})
end

function GuiElement.sprite_button(sprite, style, tooltip, ref, on_click, options)
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

function GuiElement.progressbar(style, style_mods, ref, options)
    return Table.merge({
        type = "progressbar",
        style = style,
        style_mods = style_mods,
        ref = ref,
    }, options or {})
end


return GuiElement