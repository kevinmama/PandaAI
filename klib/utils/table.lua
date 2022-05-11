local StdTable = require 'stdlib/utils/table'
local FTable = require 'flib/table'
local T = {}

T.insert = StdTable.insert
T.remove = StdTable.remove
T.merge = StdTable.merge
T.filter = StdTable.filter
T.find = StdTable.find
T.each = StdTable.each
T.map = StdTable.map
T.deep_copy = StdTable.deep_copy
T.deepcopy = StdTable.deepcopy
T.is_empty = StdTable.is_empty

T.reduce = FTable.reduce

function T.array_remove_first_value(table, value)
    local _ , k = T.find(table, function(v)
        return value == v
    end)
    T.remove(table, k)
end

function T.array_each_inverse(array, func)
    for i = #array, 1, -1 do
        func(array[i], i)
    end
end

return T
