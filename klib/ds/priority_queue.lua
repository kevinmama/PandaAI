local KC = require 'klib/container/container'
local RBTree = require 'klib/ds/rbtree'

local function __call(self, ...)
    if ... then
        self:push(...)
    else
        return self:pop()
    end
end

local Q = KC.class('klib.ds.PriorityQueue', function(self)
    self.tree = RBTree:new()
    getmetatable(self).__call = __call
end)

function Q:on_load()
    getmetatable(self).__call = __call
end

function Q:on_destroy()
    self.tree:destroy()
end

function Q:push(priority, data)
    self.tree:insert(priority, data)
end

function Q:pop()
    local node = self.tree:minimum_node()
    if node ~= self.tree.sentinel then
        self.tree:delete_node(node)
        return node.data
    else
        return nil
    end
end

return Q
