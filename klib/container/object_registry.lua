local table = require('__stdlib__/stdlib/utils/table')
local Symbols = require 'klib/container/symbols'
local ClassRegistry = require 'klib/container/class_registry'
local IdGenerator = require 'klib/container/id_generator'

local CLASS_NAME = Symbols.CLASS_NAME
local OBJECT_ID = Symbols.OBJECT_ID

local object_registry = {}
local class_indexes = {}

local ObjectRegistry = {
    object_registry = object_registry,
    class_indexes = class_indexes
}


function ObjectRegistry.get_by_id(object_id)
    return object_registry[object_id]
end

function ObjectRegistry.get_id(object)
    return object[OBJECT_ID]
end

function ObjectRegistry.get_singleton(class)
    return object_registry[ClassRegistry.get_class_name(class)]
end

function ObjectRegistry.get_or_new_singleton(class)
    local object = ObjectRegistry.get_singleton(class)
    if not object then
        object = ObjectRegistry.new_singleton(class)
    end
    return object
end

function ObjectRegistry.new_object(class, data)
    local registered_class = ClassRegistry.get_class(class)
    local data = data or {}
    data[CLASS_NAME] = registered_class[CLASS_NAME]
    return setmetatable(data, { __index = registered_class })
end

function ObjectRegistry.register(id, class_name, object)
    object_registry[id] = object
    if nil == class_indexes[class_name] then
        class_indexes[class_name] = {}
    end
    class_indexes[class_name][id] = object
end

function ObjectRegistry.deregister(id, class_name)
    object_registry[id] = nil
    if nil ~= class_indexes[class_name] then
        class_indexes[class_name][id] = nil
    end
end

function ObjectRegistry.new_singleton(class)
    local class_name = ClassRegistry.get_class_name(class)
    local object = ObjectRegistry.new_object(class, nil)
    object[OBJECT_ID] = class_name
    ObjectRegistry.register(class_name, class_name, object)
    return object
end

function ObjectRegistry.new_instance(class, data)
    local object = ObjectRegistry.new_object(class, data)
    local id = IdGenerator:next_id()
    object[OBJECT_ID] = id

    local class_name = ClassRegistry.get_class_name(class)
    ObjectRegistry.register(id, class_name, object)
    return object
end

function ObjectRegistry.load_object(data)
    local class_name = ClassRegistry.get_class(data)
    local object = ObjectRegistry.new_object(class_name)
    table.merge(object, data)
    local id = ObjectRegistry.get_id(object)
    ObjectRegistry.register(id, class_name, object)
    return object
end

function ObjectRegistry.destroy_instance(object)
    local id = ObjectRegistry.get_id(object)
    local class_name = ClassRegistry.get_class_name(object)
    ObjectRegistry.deregister(id, class_name)
    return object
end

function ObjectRegistry.for_each_object(class, handler)
    local class_name = ClassRegistry.get_class_name(class)
    if class_indexes[class_name] then
        for id, object in pairs(class_indexes[class_name]) do
            handler(object)
        end
    end
end

return ObjectRegistry
