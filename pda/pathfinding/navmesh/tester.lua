local NavMesh = require 'pda/pathfinding/pasfv/algorithm'
local PathFinding = require 'pda/pathfinding/navmesh/algorithm'
local Rendering = require 'klib/rendering/rendering'

local Tester = {}

local navmesh, start, goal

function Tester.init_mesh(surface, position)
    navmesh = NavMesh.new({
        surface = surface,
        position = position
    })
    navmesh:display()
end

function Tester.set_start(p)
    start = p
end

function Tester.set_goal(p)
    goal = p
end

function Tester.compute_path(bounding_box)
    if start == nil then
        game.print("start is not set")
        return
    elseif goal == nil then
        game.print("goal is not set")
        return
    end
    local pf = PathFinding.new({
        navmesh = navmesh,
        bounding_box = bounding_box,
        start = start,
        goal = goal
    })
    local path = pf:run()
    if path ~= nil then
        path:display()
    else
        game.print(string.format('cannot find a path from (%s,%s) to (%s,%s)', start.x, start.y, goal.x, goal.y))
    end
end

return Tester
