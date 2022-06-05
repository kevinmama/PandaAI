local TypeUtils = require('klib/utils/type')
local Symbols = require('klib/container/symbols')

local is_table = TypeUtils.is_table
local is_string = TypeUtils.is_string


local CLASS_NAME = Symbols.CLASS_NAME
local class_registry = {}

local ClassRegistry = {
    class_registry = class_registry,
    subclass_registry = {},
    class_variable_registry = {},
    class_variable_initializer = {}
}

function ClassRegistry.is_registered(object)
    return is_table(object) and nil ~= object[CLASS_NAME] and nil ~= class_registry[object[CLASS_NAME]]
end

--- check if object is class or its subclass
function ClassRegistry.is_class(object, class)
    -- assume subclass and class both are class
    local class_name = ClassRegistry.get_class_name(class)
    local subclass_name = ClassRegistry.get_class_name(object)
    while subclass_name do
        if class_name == subclass_name then
            return true
        else
            object = ClassRegistry.get_class(subclass_name)
        end
        subclass_name = object[Symbols.BASE_CLASS_NAME]
    end
    return false
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

function ClassRegistry.get_base_class(object)
    local base_class_name = object[Symbols.BASE_CLASS_NAME]
    return base_class_name and ClassRegistry.get_class(base_class_name)
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

function ClassRegistry.set_initial_class_variables(class, definition_table, initializer)
    local class_name = ClassRegistry.get_class_name(class)
    if definition_table then
        ClassRegistry.class_variable_registry[class_name] = definition_table
    end
    if initializer then
        ClassRegistry.class_variable_initializer[class_name] = initializer
    end
end

function ClassRegistry.initialize_class_variables()
    for class_name, initializer in pairs(ClassRegistry.class_variable_initializer) do
        local registry = ClassRegistry.class_variable_registry[class_name]
        if not registry then
            registry = {}
            ClassRegistry.class_variable_registry[class_name] = registry
        end
        local initial_table = initializer(registry, ClassRegistry.get_class(class_name))
        if initial_table then
            for name, value in pairs(initial_table) do
                registry[name] = value
            end
        end
    end
    --- 定义是在 control stage，初始化后不会再用到类初始器
    ClassRegistry.class_variable_initializer = nil
end

return ClassRegistry