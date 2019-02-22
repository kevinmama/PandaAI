local LazyTable = {}

local function fetch_sub_table(tbl, keys, limit, handler)
    local key_trace = ""
    local sub_table = tbl
    if handler then
        handler(sub_table)
    end
    for i = 1, limit do
        local key = keys[i]
        key_trace = key_trace .. "->" .. key
        if sub_table[key] == nil then
            sub_table[key] = {}
        elseif type(sub_table[key]) ~= 'table' then
            error("table[" .. key_trace .. "] should be a table")
        end

        sub_table = sub_table[key]
        if handler then
            handler(sub_table, i)
        end
    end
    return sub_table
end

function LazyTable.set(tbl, ...)
    local args = { ... }
    assert(#args >= 2, "argument length must greater than 2, at least specify a key and a value")
    local sub_table = fetch_sub_table(tbl, args, #args - 2)
    sub_table[args[#args - 1]] = args[#args]
    return tbl
end

function LazyTable.get(tbl, ...)
    local args = { ... }
    local sub_table = fetch_sub_table(tbl, args, #args - 1)
    return sub_table[args[#args]]
end

function LazyTable.remove(tbl, ...)
    local args = { ... }
    local stack = {}
    local sub_table = fetch_sub_table(tbl, args, #args - 1, function(t)
        table.insert(stack, t)
    end)
    local value = sub_table[args[#args]]
    sub_table[args[#args]] = nil

    local index = #args
    while index > 0 and nil == next(sub_table) do
        sub_table = stack[index]
        sub_table[args[index]] = nil
        index = index - 1
    end
    return value
end

function LazyTable.get_or_create_table(tbl, ...)
    local args = { ... }
    return fetch_sub_table(tbl, args, #args)
end

function LazyTable.add(tbl, ...)
    local args = {...}
    local parent = fetch_sub_table(tbl, args, #args - 1)
    table.insert(parent, args[#args])
    return tbl
end

-- tests
--local t = {}
--LazyTable.insert(t, 'a', 'b', 'c', 'hello')
--LazyTable.insert(t, 'a', 'b', 'd', 'world')
--print(LazyTable.get(t, 'a', 'b'))
--print(LazyTable.get(t, 'a', 'b', 'd'))
--
--print(LazyTable.remove_key(t, 'a', 'b', 'c'))
--print(LazyTable.get(t, 'a', 'b', 'c'))
--print(LazyTable.get(t, 'a', 'b'))
--print(LazyTable.remove_key(t, 'a', 'b', 'd'))
--print(LazyTable.get(t, 'a')) -- nil

--local tbl = {}
--print(LazyTable.get(tbl, "a", "b", "c"))
--print(LazyTable.get_or_create_table(tbl, "a", "b", "c"))
--print(LazyTable.get(tbl, "a", "b"))
--print(LazyTable.get(tbl, "a", "b", "c"))
--
--local tbl = {}
--print(LazyTable.get(tbl, "a", "b", "c"))
--print(LazyTable.add(tbl, "a", "b", "c"))
--print(LazyTable.get(tbl, "a", "b"))
--print(LazyTable.get(tbl, "a", "b", 1))


return LazyTable
