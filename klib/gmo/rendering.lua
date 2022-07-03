local Rendering = {}
local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'
local ColorList = require 'stdlib/utils/defines/color_list'

local function for_each_valid_id(ids, handler)
    if ids then
        if Type.is_table(ids) then
            for _, id in pairs(ids) do
                if rendering.is_valid(id) then
                    handler(id)
                end
            end
        else
            if rendering.is_valid(ids) then
                handler(ids)
            end
        end
    end
end

function Rendering.destroy_all(ids)
    for_each_valid_id(ids, function(id)
        rendering.destroy(id)
    end)
end

function Rendering.show_all(ids)
    for_each_valid_id(ids, function(id)
        rendering.set_visible(id, true)
    end)
end

function Rendering.hide_all(ids)
    for_each_valid_id(ids, function(id)
        rendering.set_visible(id, false)
    end)
end

--- path is a list of positions.
--- @param opts table {width, color, surface}
--- @return list ids of draw path
function Rendering.draw_path(waypoints, opts, on_path_draw)
    local args = Table.dictionary_merge(opts or {}, {
        width = 2,
        color = {r=0, g=1, b=0},
    })
    local ids = {}
    for i = 2, #waypoints do
        args.from = waypoints[i-1].position
        args.to = waypoints[i].position
        local rid = rendering.draw_line(args)
        table.insert(ids, rid)
        if waypoints[i].needs_destroy_to_reach then
            local tid = rendering.draw_text({
                text = 'X',
                surface = args.surface,
                target = waypoints[i].position,
                color = {r=1,g=0,b=0}
            })
            table.insert(ids, tid)
        end
    end
    return ids
end

function Rendering.integer_to_width(integer, width)
    width = width or 0.33
    return width * (math.floor(math.log(integer, 10)) + 1)
end

function Rendering.draw_rich_text_of_item_counts(params)
    local items = params.items
    local sprite_params_getter = params.sprite_params_getter
    local sprite_width = params.sprite_width or 0.5
    local sprite_scale = params.sprite_scale or 0.5
    local digit_width = params.digit_width or 0.33
    local digit_scale = params.digit_scale or 1
    local digit_color = params.digit_color
    local surface = params.surface
    local target = params.target
    local offset_y = params.offset_y or -2
    local sprite_offset_y = offset_y + 0.5 * sprite_scale

    local digits_widths = {}
    for _, count in pairs(items) do
        Table.insert(digits_widths, digit_width * (math.floor(math.log(count, 10)) + 1))
    end
    local total_width = Table.sum(digits_widths) + sprite_width * #digits_widths
    local initial_offset_x = - total_width / 2
    local offset_x = initial_offset_x
    local index = 1
    local display_ids = {}
    for name, count in pairs(items) do
        Table.insert(display_ids, rendering.draw_text({
            text = count,
            surface = surface,
            color = digit_color,
            target = target,
            target_offset = {offset_x, offset_y},
            scale = digit_scale
        }))
        offset_x = offset_x + digits_widths[index]
        local sprite_params = sprite_params_getter and sprite_params_getter(name) or {}
        Table.insert(display_ids, rendering.draw_sprite(Table.merge({
            surface = surface,
            target = target,
            target_offset = {offset_x, sprite_offset_y},
            x_scale = sprite_scale,
            y_scale = sprite_scale,
        }, sprite_params)))
        offset_x = offset_x + sprite_width
    end
    return display_ids
end

function Rendering.draw_small_hint_rectangle(surface, position, player)
    rendering.draw_rectangle({
        color = ColorList.green,
        width = 2,
        left_top = {position.x - 0.5, position.y - 0.5},
        right_bottom = {position.x + 0.5, position.y + 0.5},
        surface = surface,
        time_to_live = 600,
        players = {player},
        draw_on_ground = true,
        only_in_alt_mode = true
    })
end

return Rendering
