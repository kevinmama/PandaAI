local KC = require 'klib/container/container'
local T = require 'klib/vendor/rbtree'

local RED = 1
local BLACK = 0

-- TODO: 为了兼容加载时的数据，可以添加 _raw_ 结构，表示加载器不再深入表中

local RBNode = KC.class("klib.ds.RBNode", function(self, key, data)
    self.key = key
    self.data = data
end)

local RBTree = KC.class("klib.ds.RBTree", function(self)
    local sentinel = RBNode:new(0)
    sentinel.color = BLACK
    self.root = sentinel
    self.sentinel = sentinel
end)

function RBNode:on_destroy()
    self:travel(function(node)
        node:destroy()
    end)
end

function RBTree:insert(key, data)
    local node = RBNode:new(key, data)
    T.insert(self, node)
end

RBTree.search = T.search
RBTree.minimum_key = T.minimum_key
RBTree.minimum_node = T.minimum_node
RBTree.travel = T.travel
RBTree.delete_key = T.delete_key
RBTree.delete_node = T.delete_node
RBTree.update_key = T.update_key
RBTree.update_node = T.update_node

return RBTree
