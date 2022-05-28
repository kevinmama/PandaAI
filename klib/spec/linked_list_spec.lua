local LinkedList = require 'klib/classes/linked_list'
local IterableLinkedList = require 'klib/classes/iterable_linked_list'


--local l = LinkedList:new_local()
local l = IterableLinkedList:new_local()
local function display()
    local t = {}
    for data in l:iterator() do
        table.insert(t, data)
    end
    log(serpent.line(t))
end

for i = 1,15 do
    l:append(i)
end
display()

local node = l:first_node()
local i = 1
while node do
    local next_node = l:next_node(node)
    if i % 2 == 0 then
        l:remove_node(node)
    end
    if i % 3 == 0 then
        if l:exists(node) then
            l:remove_node(node)
        end
        if next_node then
            l:insert_after_node(next_node, node.data)
            l:insert_before_node(next_node, node.data + 100)
        end
    end

    --display()
    --log(serpent.line(l.nodes))
    node = next_node
    i = i + 1
end

display()
log(serpent.line(l.nodes))
log(serpent.line(l.frees))

l:clear()

for i = 1,15 do
    l:append(i)
end

display()

local i = 0
while (l:has_next()) do
    local v = l:next()
    if i % 2 == 0 then
        l:remove()
    end
    if i % 3 == 0 then
        if i % 2 ~= 0 then
            l:remove()
        end
        l:insert_after(v)
        l:insert_before(v + 100)
    end
    i = i + 1
end

display()
log(serpent.line(l.nodes))
log(serpent.line(l.frees))

while (l:has_prev()) do
    --log(serpent.line({i=i, index=l.index, size = l._size}))
    --display()
    --log(serpent.line(l.nodes))
    --log(serpent.line(l.frees))
    local v = l:prev()
    --log(serpent.line({i=i, index=l.index, size = l._size}))
    --display()
    --log(serpent.line(l.nodes))
    --log(serpent.line(l.frees))
    if i % 2 == 0 then
        l:remove()
    end
    if i % 3 == 0 then
        if i % 2 ~= 0 then
            l:remove()
        end
        l:insert_after(v)
        l:insert_before(v + 100)
    end
    i = i + 1
end

display()
log(serpent.line(l.nodes))
log(serpent.line(l.frees))


