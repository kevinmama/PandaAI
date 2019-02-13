local TableUtils = require 'klib/utils/table_utils'
local Symbols = require 'klib/container/symbols'
local ClassRegistry = require 'klib/container/class_registry'
local IdAllocator = require 'klib/container/id_allocator'

local merge_table = TableUtils.merge_table

local CLASS_NAME = Symbols.CLASS_NAME
local OBJECT_ID = Symbols.OBJECT_ID
local object_registry = {}

local ObjectRegistry = {
    object_registry = object_registry
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

function ObjectRegistry.new_singleton(class)
    local key = ClassRegistry.get_class_name(class)
    local object = ObjectRegistry.new_object(class, nil)
    object[OBJECT_ID] = key
    object_registry[key] = object
    return object
end

function ObjectRegistry.new_instance(class, data)
    local object = ObjectRegistry.new_object(class, data)
    local key = IdAllocator.next_object_id()
    object[OBJECT_ID] = key
    object_registry[key] = object
    return object
end

function ObjectRegistry.load_object(data)
    -- use nil because cannot change global table during load
    local object = ObjectRegistry.new_object(ClassRegistry.get_class(data))
    merge_table(object, data)
    local id = ObjectRegistry.get_id(object)
    object_registry[id] = object
    IdAllocator.update_next_object_id(id)
    return object
end

function ObjectRegistry.destroy_instance(object)
    local key = ObjectRegistry.get_id(object)
    object_registry[key] = nil
    return object
end

return ObjectRegistry
