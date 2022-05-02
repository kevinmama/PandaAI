local Is = require 'stdlib/utils/is'
local ColorList = require 'stdlib/utils/defines/color_list'
local Position = require 'stdlib/area/position'
local M = {}

-- 画出给定区域的碰撞物体边缘
local function render_collision_box(opts)
    Is.assert.object(opts.surface)
    Is.assert.table(opts.collision_mask)
    local area
    if Is.area(opts.area) then
        area = opts.area
    elseif (Is.position(opts.position) and Is.positive(opts.radius)) then
        area = Position.expand_to_area(opts.position, opts.radius)
    else
        error("area or (position, radius) must be given.")
    end
    local time_to_live = opts.time_to_live

    local entities = opts.surface.find_entities_filtered({
        area = opts.area,
        collision_mask = opts.collision_mask
    })
    for _, entity in pairs(entities) do
        rendering.draw_rectangle({
            color = ColorList.darkgreen,
            left_top = entity.bounding_box.left_top,
            right_bottom = entity.bounding_box.right_bottom,
            surface = opts.surface,
            filled = false,
            time_to_live = time_to_live
        })
    end

    local tiles = opts.surface.find_tiles_filtered({
        area = opts.area,
        collision_mask = opts.collision_mask
    })
    for _, tile in pairs(tiles) do
        local bounding_box = Position.expand_to_area(tile.position, 0.5)
        rendering.draw_rectangle({
            color = ColorList.lightgreen,
            left_top = bounding_box.left_top,
            right_bottom = bounding_box.right_bottom,
            surface = opts.surface,
            filled = false,
            time_to_live = time_to_live
        })
    end
end
M.render_collision_box = render_collision_box

return M
