local Rendering = {}
local table = require('stdlib/utils/table')
local Is = require('stdlib/utils/is')

function Rendering.clear(ids)
    if ids then
        for _, id in pairs(ids) do
            if rendering.is_valid(id) then
                rendering.destroy(id)
            end
        end
    end
end

-- path is a list of positions
-- opts: {width, color, surface}
function Rendering.draw_path(path, opts)
    -- path is collection of nodes
    -- nodes in format: { position, needs_destroy_to_reach }
    Is.assert.table(path)
    local args = table.dictionary_merge(opts or {}, {
        width = 2,
        color = {r=0, g=1, b=0},
    })
    local ids = {}
    for i = 2, #path do
        args.from = path[i-1].position
        args.to = path[i].position
        local rid = rendering.draw_line(args)
        table.insert(ids, rid)
        if path[i].needs_destroy_to_reach then
            local tid = rendering.draw_text({
                text = 'X',
                surface = args.surface,
                target = path[i].position,
                color = {r=1,g=0,b=0}
            })
            table.insert(ids, tid)
        end
    end
    return ids
end

return Rendering
