local U = {}

function U.is_table(object)
    return type(object) == 'table'
end

function U.is_number(object)
    return type(object) == 'number'
end

function U.is_int(object)
    return type(object) == 'number' and object == math.floor(object)
end

function U.is_string(object)
    return type(object) == 'string'
end

function U.exists(var)
    return var ~= nil
end

function U.is_native(object)
    return type(object) == 'table' and type(object.__self) == 'userdata'
end

return U
