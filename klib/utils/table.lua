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

return T
