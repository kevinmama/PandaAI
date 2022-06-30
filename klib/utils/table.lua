local StdTable = require 'stdlib/utils/table'
local FTable = require 'flib/table'
local T = {}

T.insert = StdTable.insert
T.remove = StdTable.remove
T.merge = StdTable.merge
T.dictionary_merge = StdTable.dictionary_merge
T.filter = StdTable.filter
T.find = StdTable.find
T.each = StdTable.each
T.map = StdTable.map
T.deep_copy = StdTable.deep_copy
T.deepcopy = StdTable.deepcopy
T.is_empty = StdTable.is_empty
T.sort = StdTable.sort
T.pack = StdTable.pack
T.unpack = StdTable.unpack
T.concat = StdTable.concat
T.array_combine = StdTable.array_combine
T.dictionary_combine = StdTable.dictionary_combine
T.invert = StdTable.invert
T.keys = StdTable.keys
T.unique_values = StdTable.unique_values
T.flatten = StdTable.flatten
T.clear = StdTable.clear
T.size = StdTable.size
T.sum = StdTable.sum

T.reduce = FTable.reduce

function T.array_remove_first_value(table, value)
    local _ , k = T.find(table, function(v)
        return value == v
    end)
    T.remove(table, k)
end

function T.array_each_reverse(array, func)
    for i = #array, 1, -1 do
        func(array[i], i)
    end
end

--- 如果 initial 为空，则初始值默认为 {}
function T.get_or_create(tbl, k, initial)
    local v = tbl[k]
    if v then
        return v
    else
        tbl[k] = initial or {}
        return tbl[k]
    end
end

function T.add(...)
    local tables = {...}
    local new = {}
    for _, tab in pairs(tables) do for k, v in pairs(tab) do new[k] = (new[k] or 0) + v end end
    return new
end

function T.added(tbl, ...)
    local tables = {...}
    for _, tab in pairs(tables) do for k, v in pairs(tab) do tbl[k] = (tbl[k] or 0) + v end end
    return tbl
end

return T
