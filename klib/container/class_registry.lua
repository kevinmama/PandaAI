local TypeUtils = require('klib/utils/type_utils')
local Symbols = require('klib/container/symbols')

local is_table = TypeUtils.is_table
local exists = TypeUtils.exists
local is_string = TypeUtils.is_string


local CLASS_NAME = Symbols.CLASS_NAME
local class_registry = {}

local ClassRegistry = {
    class_registry = class_registry
}

function ClassRegistry.is_registered(object)
    return is_table(object) and exists(object[CLASS_NAME]) and exists(class_registry[object[CLASS_NAME]])
end

function ClassRegistry.new_class(name)
    local class = {}
    class[CLASS_NAME] = name
    class_registry[name] = class
    return class
end

function ClassRegistry.get_class(object)
    if is_string(object) then
        return class_registry[object]
    elseif is_table(object) then
        return class_registry[object[CLASS_NAME]]
    else
        return nil
    end
end

function ClassRegistry.get_class_name(object)
    return object[CLASS_NAME]
end

function ClassRegistry.validate(class)
    if not exists(class[CLASS_NAME]) then
        error("table is not a class. A class is a table with key '" .. CLASS_NAME .. "'")
    end
end

return ClassRegistry