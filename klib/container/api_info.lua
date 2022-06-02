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
    return ObjectRegistry.find_object(ClassRegistry.get_class(class), matcher)
end

function ApiInfo.filter_objects(class, filter)
    return ObjectRegistry.filter_objects(ClassRegistry.get_class(class), filter)
end

function ApiInfo.for_each_object(class, handler)
    ObjectRegistry.for_each_object(ClassRegistry.get_class(class), handler)
end

return ApiInfo