local KC = require 'klib/container/container'

local Path = KC.class('pda.path.Path', function(self)
    self.nodes = {}
end)

function Path:add_node(node)
    table.insert(self.nodes, node)
end

return Path