local KC = require 'klib/container/container'
local T = require 'klib/vendor/rbtree'

local RED = 1
local BLACK = 0

local RBTree = KC.class("klib.classes.RBTree", function(self)
    local sentinel = {key = 0, sentinel = true}
    sentinel.color = BLACK
    self.root = sentinel
    self.sentinel = sentinel
end)

RBTree.insert = T.insert
RBTree.search = T.search
RBTree.minimum_key = T.minimum_key
RBTree.minimum_node = T.minimum_node
RBTree.travel = T.travel
RBTree.delete_key = T.delete_key
RBTree.delete_node = T.delete_node
RBTree.update_key = T.update_key
RBTree.update_node = T.update_node

return RBTree
