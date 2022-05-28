local KC = require 'klib/container/container'
local LinkedList = require 'klib/classes/linked_list'

local HEAD, TAIL = LinkedList.HEAD, LinkedList.TAIL

local IterableLinkedList = KC.class('klib.classes.IterableLinkedList', LinkedList, function(self)
    LinkedList(self)
    self.index = HEAD
end)

function IterableLinkedList:clear()
    LinkedList.clear(self)
    self.index = HEAD
end

function IterableLinkedList:first()
    local node = self:first_node()
    return node and node.data
end

function IterableLinkedList:last()
    local node = self:last_node()
    return node and node.data
end

function IterableLinkedList:current_node()
    return self.index > 0 and self.nodes[self.index] or nil
end

function IterableLinkedList:current()
    local node = self:current_node()
    return node and node.data
end

function IterableLinkedList:has_next()
    local node = self:current_node()
    if node then
        return node.next > 0
    else
        return self._size > 0 and self.index ~= TAIL
    end
end

function IterableLinkedList:next()
    if self._size > 0 and self.index ~= TAIL then
        if self.index == HEAD then
            self.index = self._first
        else
            local node = self.nodes[self.index]
            self.index = node.next
        end
        return self:current()
    else
        return nil
    end
end

function IterableLinkedList:has_prev()
    local node = self:current_node()
    if node then
        return node.prev > 0
    else
        return self._size > 0 and self.index ~= HEAD
    end
end

function IterableLinkedList:prev()
    if self._size > 0 and self.index ~= HEAD then
        if self.index == TAIL then
            self.index = self._last
        else
            local node = self.nodes[self.index]
            self.index = node.prev
        end
        return self:current()
    else
        return nil
    end
end

function IterableLinkedList:rewind()
    self.index = self._first
    return self:current()
end

function IterableLinkedList:insert_before(data)
    if self.index == HEAD then
        self:prepend(data)
    elseif self.index == TAIL then
        self:append(data)
    else
        local node = self:current_node()
        self:insert_before_node(node, data)
    end
end

function IterableLinkedList:insert_after(data)
    if self.index == HEAD then
        self:prepend(data)
    elseif self.index == TAIL then
        self:append(data)
    else
        local node = self:current_node()
        self:insert_after_node(node, data)
    end
end

function IterableLinkedList:remove()
    local node = self:current_node()
    if node then
        self.index = node.next
        self:remove_node(node)
        return node.data
    else
        error("node has been removed")
    end
end

return IterableLinkedList
