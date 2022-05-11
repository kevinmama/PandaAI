local TypeUtils = require('klib/utils/type')
local Symbols = require('klib/container/symbols')

local is_table = TypeUtils.is_table
local is_string = TypeUtils.is_string


local CLASS_NAME = Symbols.CLASS_NAME
local class_registry = {}

local ClassRegistry = {
    class_registry = class_registry,
    subclass_registry = {},
    class_variable_registry = {}
}

function ClassRegistry.is_registered(object)
    return is_table(object) and nil ~= object[CLASS_NAME] and nil ~= class_registry[object[CLASS_NAME]]
end

function ClassRegistry.new_class(name)
    local class = setmetatable({}, {})
    class[CLASS_NAME] = name
    class_registry[name] = class
    return class
end

function ClassRegistry.add_subclass(class, subclass)
    local class_name = ClassRegistry.get_class_name(class)
    local subclasses = ClassRegistry.subclass_registry[class_name]
    if not subclasses then
        subclasses = {}
        ClassRegistry.subclass_registry[class_name] = subclasses
    end
    table.insert(subclasses, subclass)
end

function ClassRegistry.get_class(object)
    if is_string(object) then
        return class_registry[object]
    elseif is_table(object) then
        return class_registry[object[CLASS_NAME]]
    else
        error('object must be a string or a class table', 3)
    end
end

function ClassRegistry.get_subclasses(object)
    local class_name = ClassRegistry.get_class(object)[CLASS_NAME]
    return ClassRegistry.subclass_registry[class_name] or {}
end

function ClassRegistry.get_class_name(object)
    return object[CLASS_NAME]
end

function ClassRegistry.validate(class)
    if nil == class[CLASS_NAME] then
        error("table is not a class. A class is a table with key '" .. CLASS_NAME .. "'", 3)
    end
end

function ClassRegistry.for_each_singleton(handler)
    for _, class in pairs(class_registry) do
        if class[Symbols.SINGLETON] then
            handler(class)
        end
    end
end

function ClassRegistry.get_class_variable(class, name)
    local class_name = ClassRegistry.get_class_name(class)
    return ClassRegistry.class_variable_registry[class_name][name]
end

function ClassRegistry.set_class_variable(class, name, value)
    local class_name = ClassRegistry.get_class_name(class)
    ClassRegistry.class_variable_registry[class_name][name] = value
end

function ClassRegistry.set_initial_class_variables(class, definition_table)
    local class_name = ClassRegistry.get_class_name(class)
    ClassRegistry.class_variable_registry[class_name] = definition_table
end

return ClassRegistry