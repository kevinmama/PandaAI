local Rendering = {}
local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'

local function for_each_valid_id(ids, handler)
    if ids then
        for _, id in pairs(ids) do
            if rendering.is_valid(id) then
                handler(id)
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

return Rendering
