local KC = require 'klib/container/container'

local IndexAllocator = KC.class('scenario.MobileFactory.IndexAllocator', function(self)
    self.next_index = 0
    self.free_indexes = {}
end)

function IndexAllocator:alloc()
    if next(self.free_indexes) then
        return table.remove(self.free_indexes, #self.free_indexes)
    else
        local index = self.next_index
        self.next_index = self.next_index + 1
        return index
    end
end

function IndexAllocator:free(index)
    if index >= 0 and index < self.next_index then
        for _, i in pairs(self.free_indexes) do
            if i == index then return end
        end
        table.insert(self.free_indexes, index)
    end
end

return IndexAllocator
