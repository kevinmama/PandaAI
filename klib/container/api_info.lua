local Type = require 'klib/utils/type'
local Symbols = require 'klib/container/symbols'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'

local ApiInfo = {}

function ApiInfo.get_object_id(object)
    return ObjectRegistry.get_id(object)
end

function ApiInfo.get_class(object)
    return ClassRegistry.get_class(object)
end

function ApiInfo.get_base_class(object)
    return ClassRegistry.get_base_class(object)
end

function ApiInfo.is_object(object, class)
    return Type.is_table(object) and Type.has(object, Symbols.CLASS_NAME) and (
            (not class and nil ~= ClassRegistry.get_class_name(object)) or
            ClassRegistry.is_class(object, class)
    ) and nil ~= ObjectRegistry.get_id(object)
end

function ApiInfo.is_class(object, class)
    return Type.is_table(object) and Type.has(object, Symbols.CLASS_NAME) and (
            (not class and nil ~= ClassRegistry.get_class_name(object)) or
            ClassRegistry.is_class(object, class)
    ) and nil == ObjectRegistry.get_id(object)
end

function ApiInfo.find_object(class, matcher)
    class = ClassRegistry.get_class(class)
    return class and ObjectRegistry.find_object(class, matcher)
end

function ApiInfo.filter_objects(class, filter)
    class = ClassRegistry.get_class(class)
    return class and ObjectRegistry.filter_objects(class, filter)
end

function ApiInfo.for_each_object(class, handler)
    class = ClassRegistry.get_class(class)
    if class then
        ObjectRegistry.for_each_object(class, handler)
    end
end

return ApiInfo