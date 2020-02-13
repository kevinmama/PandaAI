local pkey = require 'pda/pathfinding/grid/pkey'
local SuccessorGenerator = {}

local step = 0.4
local d_step = 1.44 * step

function SuccessorGenerator.generate(engine, node)
    local p = node.position
    local possible_position = {
        {x= p.x, y= p.y -step},
        {x= p.x, y= p.y +step},
        {x= p.x-step, y= p.y},
        {x= p.x+step, y= p.y},

        {x= p.x-step, y= p.y-step},
        {x= p.x-step, y= p.y+step},
        {x= p.x+step, y= p.y-step},
        {x= p.x+step, y= p.y+step}
    }
    local successors = {}
    for i, position in ipairs(possible_position) do
        local d
        if i <= 4 then d = step else d = d_step end
        local successor = {
            g = node.g + d,
            position= position,
            parent= pkey(node),
            open= true,
        }
        table.insert(successors, successor)
    end
    return successors
end

return SuccessorGenerator
