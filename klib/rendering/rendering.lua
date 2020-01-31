local Rendering = {}
local table = require('__stdlib__/stdlib/utils/table')
local Is = require('__stdlib__/stdlib/utils/is')

-- path is a list of positions
-- opts: {width, color, surface}
function Rendering.draw_path(path, opts)
    Is.assert.table(path)
    local args = table.dictionary_merge(opts or {}, {
        width = 2,
        color = {r=0, g=1, b=0},
    })
    local ids = {}
    for i = 2, #path do
        args.from = path[i-1]
        args.to = path[i]
        local rid = rendering.draw_line(args)
        table.insert(ids, rid)
    end
    return ids
end

return Rendering
