local KC = require 'klib/container/container'
local RBTree = require 'klib/classes/rbtree'

local function __call(self, ...)
    if ... then
        self:push(...)
    else
        return self:pop()
    end
end

local Q = KC.class('klib.classes.PriorityQueue', function(self)
    self.tree = RBTree:new_local()
end)

function Q:on_ready()
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
    if not node.sentinel then
        self.tree:delete_node(node)
        return node.data, node.key
    else
        return nil
    end
end

function Q:peek()
    local node = self.tree:minimum_node()
    if not node.sentinel then
        return node.data, node.key
    else
        return nil
    end
end

return Q
