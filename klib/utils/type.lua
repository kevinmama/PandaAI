local U = {}

local ERROR_LEVEL = 2

function U.is_nil(object)
    return nil == object
end

function U.assert_nil(object)
    if nil ~= object then
        error((name or 'object')..' must be nil', ERROR_LEVEL)
    end
end

function U.is_not_nil(object)
    return nil ~= object
end

function U.assert_not_nil(object, name)
    if nil == object then
        error((name or 'object')..' cannot be nil', ERROR_LEVEL)
    end
end

function U.is_table(object)
    return type(object) == 'table'
end

function U.assert_is_table(object, name)
    if not U.is_table(object) then
        error((name or 'object') .. ' must be a table.', ERROR_LEVEL)
    end
end

function U.is_number(object)
    return type(object) == 'number'
end

function U.assert_is_number(object, name)
    if not U.is_number(object) then
        error((name or 'object') .. ' must be a number.', ERROR_LEVEL)
    end
end

function U.is_int(object)
    return type(object) == 'number' and object == math.floor(object)
end

function U.assert_is_int(object, name)
    if not U.is_int(object) then
        error((name or 'object') .. ' must be an integer', ERROR_LEVEL)
    end
end

function U.is_string(object)
    return type(object) == 'string'
end

function U.assert_is_string(object, name)
    if not U.is_string(object) then
        error((name or 'object') .. ' must be a string', ERROR_LEVEL)
    end
end

function U.is_native(object)
    return type(object) == 'table' and type(object.__self) == 'userdata'
end

function U.assert_is_native(object, name)
    if not U.is_native(object) then
        error((name or 'object') .. ' must be a native object', ERROR_LEVEL)
    end
end

function U.is_function(object)
    return type(object) == 'function'
end

function U.assert_is_function(object, name)
    if not U.is_function(object) then
        error((name or 'object') .. ' must be a function', ERROR_LEVEL)
    end
end

function U.assert_nil_or_function(object, name)
    if nil ~= object and not U.is_function(object) then
        error((name or 'object') .. ' must be nil or a function', ERROR_LEVEL)
    end
end

function U.is_boolean(object)
    return type(object) == 'boolean'
end

function U.assert_is_boolean(object, name)
    if not U.is_boolean(object) then
        error((name or 'object') .. ' must be boolean', ERROR_LEVEL)
    end
end

function U.has(object, field_name)
    return pcall( function() return object[field_name] end )
end

return U
