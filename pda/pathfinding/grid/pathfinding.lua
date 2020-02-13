local Engine = require 'pda/pathfinding/grid/engine'
return function (args)
    local engine = Engine.new(args)
    return engine:run()
end

