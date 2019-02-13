local is_int = require('klib/utils/type_utils').is_int

local IdAllocator = {
    _next_object_id = 1
}

function IdAllocator.next_object_id()
    local the_return_id = IdAllocator._next_object_id
    IdAllocator._next_object_id = IdAllocator._next_object_id + 1
    return the_return_id
end

function IdAllocator.update_next_object_id(id)
    if is_int(id) and IdAllocator._next_object_id <= id then
        IdAllocator._next_object_id = id + 1
    end
end

return IdAllocator
