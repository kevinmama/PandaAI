local TypeUtils = require 'klib/utils/type'
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
    return ClassRegistry.get_class(object[Symbols.BASE_CLASS_NAME])
end

function ApiInfo.is_object(object)
    return TypeUtils.is_table(object) and nil ~= ClassRegistry.get_class_name(object) and nil ~= ObjectRegistry.get_id(object)
end

function ApiInfo.is_class(object)
    return TypeUtils.is_table(object) and nil ~= ClassRegistry.get_class_name(object) and nil == ObjectRegistry.get_id(object)
end

function ApiInfo.find_object(class, matcher)
    return ObjectRegistry.find_object(class, matcher)
end

function ApiInfo.filter_objects(class, filter)
    return ObjectRegistry.filter_objects(class, filter)
end

function ApiInfo.for_each_object(class, handler)
    ObjectRegistry.for_each_object(class, handler)
end

return ApiInfo