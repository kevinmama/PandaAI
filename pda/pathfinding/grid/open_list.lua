local RbTree = require 'klib/vendor/rbtree'
local pkey = require 'pda/pathfinding/grid/pkey'

local OpenList = {}

function OpenList.new(engine)
    return setmetatable({
        wtree = RbTree.new(),
        ptable = engine.ptable
    }, {__index = OpenList})
end

function OpenList:push(node)
   self.wtree:insert(node)
   self.ptable[pkey(node)] = node
end

function OpenList:replace(old_node, new_node)
    self.wtree:delete_node(old_node)
    self.wtree:insert(new_node)
    self.ptable[pkey(new_node)] = new_node
end

function OpenList:pop()
    local node = self.wtree:minimum_node()
    if node ~= self.wtree.sentinel then
        self.wtree:delete_node(node)
        return node
    else
        return nil
    end
end

return OpenList
