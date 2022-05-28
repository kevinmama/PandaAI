local KC = require 'klib/container/container'

local HEAD = -1
local TAIL = -2

local LinkedList = KC.class('klib.classes.LinkedList', function(self)
    self:clear()
end)

LinkedList.HEAD = HEAD
LinkedList.TAIL = TAIL

function LinkedList:clear()
    self.nodes = {}
    self.frees = {}
    self._first = HEAD
    self._last = TAIL
    self._size = 0
end

function LinkedList:is_empty()
    return self._size == 0
end

function LinkedList:size()
    return self._size
end

function LinkedList:first_node()
    return self._size > 0 and self.nodes[self._first] or nil
end

function LinkedList:last_node()
    return self._size > 0 and self.nodes[self._last] or nil
end

function LinkedList:next_node(node)
    return node.next ~= TAIL and self.nodes[node.next]
end

function LinkedList:prev_node(node)
    return node.prev ~= HEAD and self.nodes[node.prev]
end

function LinkedList:prepend(data)
    return self:insert_before_node(self:first_node(), data)
end

function LinkedList:append(data)
    return self:insert_after_node(self:last_node(), data)
end

function LinkedList:_alloc_node(data)
    local index
    local size = #self.frees
    if size > 0 then
        index = table.remove(self.frees, size)
    else
        index = #self.nodes + 1
    end
    local node = {
        index = index,
        data = data
    }
    self.nodes[index] = node
    return node
end

function LinkedList:insert_after_node(node, data)
    local new_node = self:_alloc_node(data)
    if node then
        new_node.prev = node.index
        new_node.next = node.next
        node.next = new_node.index
        if new_node.next == TAIL then
            self._last = new_node.index
        else
            self.nodes[new_node.next].prev = new_node.index
        end
    elseif self._size == 0 then
        new_node.prev = HEAD
        new_node.next = TAIL
        self._first = new_node.index
        self._last = new_node.index
    else
        error("node cannot be empty when list is not empty")
    end
    self._size = self._size + 1
    return new_node
end

function LinkedList:append(data)
    return self:insert_after_node(self:last_node(), data)
end

function LinkedList:insert_before_node(node, data)
    local new_node = self:_alloc_node(data)
    if node then
        new_node.prev = node.prev
        new_node.next = node.index
        node.prev = new_node.index
        if new_node.prev == HEAD then
            self._first = new_node.index
        else
            self.nodes[new_node.prev].next = new_node.index
        end
    elseif self._size == 0 then
        new_node.prev = HEAD
        new_node.next = TAIL
        self._first = new_node.index
        self._last = new_node.index
    else
        error("node cannot be empty when list is not empty")
    end
    self._size = self._size + 1
    return new_node
end

function LinkedList:prepend(data)
    return self:insert_before_node(self:first_node(), data)
end

function LinkedList:exists(node)
    return self.nodes[node.index] == node
end

function LinkedList:remove_node(node)
    if self.nodes[node.index] ~= node then
        error("node has been removed")
    end
    local prev_node = node.prev ~= HEAD and self.nodes[node.prev]
    local next_node = node.next ~= TAIL and self.nodes[node.next]
    if prev_node then
        if prev_node.next ~= node.index then
            error("node has been removed")
        end
        prev_node.next = node.next
        if self._last == node.index then
            self._last = prev_node.index
        end
    end
    if next_node then
        if next_node.prev ~= node.index then
            error("node has been removed")
        end
        next_node.prev = node.prev
        if self._first == node.index then
            self._first = next_node.index
        end
    end
    self._size = self._size - 1
    if self._size == 0 then
        self._first = HEAD
        self._last = TAIL
    end
    table.insert(self.frees, node.index)
    node.index = nil
    node.prev = nil
    node.next = nil
    return node
end


function LinkedList:iterator()
    local next = self._first
    local index = 0
    return function()
        if next > 0 then
            local node = self.nodes[next]
            next = node.next or 0
            index = index + 1
            return node.data, index
        else
            return nil
        end
    end
end

return LinkedList