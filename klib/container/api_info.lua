local TypeUtils = require 'klib/utils/type_utils'
local Symbols = require 'klib/container/symbols'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'

local ApiInfo = {}

function ApiInfo.get_id(object)
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

return ApiInfo