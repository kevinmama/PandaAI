local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'


local ApiInfo = {}

function ApiInfo.get_id(object)
    return ObjectRegistry.get_id(object)
end

function ApiInfo.get_class(object)
    return ClassRegistry.get_class(object)
end

return ApiInfo