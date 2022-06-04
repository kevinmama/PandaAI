--[[
   Written by Soojin Nam. Public Domain.
   The red-black tree code is based on the algorithm described in
   the "Introduction to Algorithms" by Cormen, Leiserson and Rivest.
--]]

-- source from https://github.com/sjnam/lua-rbtree
-- modified by kevinma
-- comparing table in factorio is not safe, so comparing sentinel field instead

--------------------------------------------------------------------


local type = type
--local setmetatable = setmetatable

local RED = 1
local BLACK = 0


local function inorder_tree_walk (x, visitor)
    if not x.sentinel then
        inorder_tree_walk (x.left, visitor)
        if visitor then
            visitor(x)
        end
        inorder_tree_walk (x.right, visitor)
    end
end


local function tree_minimum (x)
    while not x.left.sentinel do
        x = x.left
    end
    return x
end


local function tree_search (x, k)
    while not x.sentinel and k ~= x.key do
        if k < x.key then
            x = x.left
        else
            x = x.right
        end
    end
    return x
end


local function left_rotate (T, x)
    local y = x.right
    x.right = y.left
    if not y.left.sentinel then
        y.left.p = x
    end
    y.p = x.p
    if x.p.sentinel then
        T.root = y
    elseif x == x.p.left then
        x.p.left = y
    else
        x.p.right = y
    end
    y.left = x
    x.p = y
end


local function right_rotate (T, x)
    local y = x.left
    x.left = y.right
    if not y.right.sentinel then
        y.right.p = x
    end
    y.p = x.p
    if x.p.sentinel then
        T.root = y
    elseif x == x.p.right then
        x.p.right = y
    else
        x.p.left = y
    end
    y.right = x
    x.p = y
end


local function rb_insert (T, z)
    local y = T.sentinel
    local x = T.root
    while not x.sentinel do
        y = x
        if z.key < x.key then
            x = x.left
        else
            x = x.right
        end
    end
    z.p = y
    if y.sentinel then
        T.root = z
    elseif z.key < y.key then
        y.left = z
    else
        y.right = z
    end
    z.left = T.sentinel
    z.right = T.sentinel
    z.color = RED
    -- insert-fixup
    while z.p.color == RED do
        if z.p == z.p.p.left then
            y = z.p.p.right
            if y.color == RED then
                z.p.color = BLACK
                y.color = BLACK
                z.p.p.color = RED
                z = z.p.p
            else
                if z == z.p.right then
                    z = z.p
                    left_rotate(T, z)
                end
                z.p.color = BLACK
                z.p.p.color = RED
                right_rotate(T, z.p.p)
            end
        else
            y = z.p.p.left
            if y.color == RED then
                z.p.color = BLACK
                y.color = BLACK
                z.p.p.color = RED
                z = z.p.p
            else
                if z == z.p.left then
                    z = z.p
                    right_rotate(T, z)
                end
                z.p.color = BLACK
                z.p.p.color = RED
                left_rotate(T, z.p.p)
            end
        end
    end
    T.root.color = BLACK
end


local function rb_transplant (T, u, v)
    if u.p.sentinel then
        T.root = v
    elseif u == u.p.left then
        u.p.left = v
    else
        u.p.right = v
    end
    v.p = u.p
end


local function rb_delete (T, z)
    local x, w
    local y = z
    local y_original_color = y.color
    if z.left.sentinel then
        x = z.right
        rb_transplant(T, z, z.right)
    elseif z.right.sentinel then
        x = z.left
        rb_transplant(T, z, z.left)
    else
        y = tree_minimum(z.right)
        y_original_color = y.color
        x = y.right
        if y.p == z then
            x.p = y
        else
            rb_transplant(T, y, y.right)
            y.right = z.right
            y.right.p = y
        end
        rb_transplant(T, z, y)
        y.left = z.left
        y.left.p = y
        y.color = z.color
    end

    if y_original_color ~= BLACK then
        return
    end
    -- delete-fixup
    while x ~= T.root and x.color == BLACK do
        if x == x.p.left then
            w = x.p.right
            if w.color == RED then
                w.color = BLACK
                x.p.color = RED
                left_rotate(T, x.p)
                w = x.p.right
            end
            if w.left.color == BLACK and w.right.color == BLACK then
                w.color = RED
                x = x.p
            else
                if w.right.color == BLACK then
                    w.left.color = BLACK
                    w.color = RED
                    right_rotate(T, w)
                    w = x.p.right
                end
                w.color = x.p.color
                x.p.color = BLACK
                w.right.color = BLACK
                left_rotate(T, x.p)
                x = T.root
            end
        else
            w = x.p.left
            if w.color == RED then
                w.color = BLACK
                x.p.color = RED
                right_rotate(T, x.p)
                w = x.p.left
            end
            if w.right.color == BLACK and w.left.color == BLACK then
                w.color = RED
                x = x.p
            else
                if w.left.color == BLACK then
                    w.right.color = BLACK
                    w.color = RED
                    left_rotate(T, w)
                    w = x.p.left
                end
                w.color = x.p.color
                x.p.color = BLACK
                w.left.color = BLACK
                right_rotate(T, x.p)
                x = T.root
            end
        end
    end
    x.color = BLACK
end


local function rbtree_node (key)
    return { key = key or 0 }
end


-- rbtree module stuffs

local _M = {
    version = '0.0.2'
}


function _M.search(self, key)
    return not tree_search(self.root, key).sentinel
end

function _M.minimum_key(self)
    if self.root.sentinel then
        return nil
    else
        return tree_minimum(self.root).key
    end
end

function _M.minimum_node(self)
    if self.root.sentinel then
        return self.sentinel
    else
        return tree_minimum(self.root)
    end
end

function _M.travel(self, visitor)
    inorder_tree_walk(self.root, visitor)
end


function _M.insert(self, key, data)
    local key = key
    if type(key) == "number" then
        key = rbtree_node(key)
    end
    if (data) then
        key.data = data
    end

    rb_insert(self, key)
end

function _M.delete_key(self, key)
    local z = tree_search(self.root, key)
    if not z.sentinel then
        rb_delete(self, z)
        return z
    end
end

function _M.delete_node(self, node)
    if not node.sentinel then
        rb_delete(self, node)
    end
end

function _M.update_key(self, old_key, new_key)
    local node = _M.delete_key(self, old_key)
    node.key = new_key
    _M.insert(self, node)
end

function _M.update_node(self, old_node, new_node)
    _M.delete_node(self, old_node)
    rb_insert(self, new_node)
end

--local mt = {
--    __index = _M,
--    __call = _M.search
--}


--function _M.new ()
--    local sentinel = rbtree_node()
--    sentinel.color = BLACK
--    return setmetatable({ root = sentinel, sentinel = sentinel }, mt)
--end


return _M
