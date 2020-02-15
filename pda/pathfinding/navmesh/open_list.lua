local RbTree = require 'klib/vendor/rbtree'

local OpenList = {}

function OpenList.new(algorithm)
    return setmetatable({
        wtree = RbTree.new()
    }, {__index = OpenList})
end

function OpenList:push(node)
   self.wtree:insert(node)
end

function OpenList:replace(old_node, new_node)
    self.wtree:delete_node(old_node)
    self.wtree:insert(new_node)
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
