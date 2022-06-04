--local log = (require('stdlib/misc/logger'))('kc_object_registry', DEBUG)
local Table = require('klib/utils/table')
local Symbols = require 'klib/container/symbols'
local ClassRegistry = require 'klib/container/class_registry'
local IdGenerator = require 'klib/container/id_generator'

local CLASS_NAME = Symbols.CLASS_NAME
local OBJECT_ID = Symbols.OBJECT_ID

local ObjectRegistry = {
    --- 在 init 事件中赋值给 global 对应对象，在 load 事件中赋值为存在 global 的对应对象
    --- @see event_binder.lua
    object_registry = {},
    class_indexes = {}
}

function ObjectRegistry.get_by_id(object_id)
    return ObjectRegistry.object_registry[object_id]
end

function ObjectRegistry.get_id(object)
    return object[OBJECT_ID]
end

function ObjectRegistry.get_singleton(class)
    return ObjectRegistry.object_registry[ClassRegistry.get_class_name(class)]
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
    --log("register " .. class_name .. "@" .. id)
    ObjectRegistry.object_registry[id] = object
    if nil == ObjectRegistry.class_indexes[class_name] then
        ObjectRegistry.class_indexes[class_name] = {}
    end
    ObjectRegistry.class_indexes[class_name][id] = object
end

function ObjectRegistry.deregister(id, class_name)
    ObjectRegistry.object_registry[id] = nil
    if nil ~= ObjectRegistry.class_indexes[class_name] then
        ObjectRegistry.class_indexes[class_name][id] = nil
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
    local class = ClassRegistry.get_class(data)
    --local class_name = ClassRegistry.get_class_name(class)
    local object = ObjectRegistry.new_object(class, data)
    --local id = ObjectRegistry.get_id(object)
    -- 从全局表加载时，不能修改 global 表
    --if id then
    --    ObjectRegistry.register(id, class_name, object)
    --end
    return object
end

function ObjectRegistry.destroy_instance(object)
    local id = ObjectRegistry.get_id(object)
    -- 如果无 id 表示是私有实例，不注册到全局对象表
    if id then
        local class_name = ClassRegistry.get_class_name(object)
        ObjectRegistry.deregister(id, class_name)
    end
    return object
end

function ObjectRegistry.for_each_object(class, handler)
    local class_name = ClassRegistry.get_class_name(class)
    if ObjectRegistry.class_indexes[class_name] then
        for _, object in pairs(ObjectRegistry.class_indexes[class_name]) do
            handler(object)
        end
    end
    for _, subclass in pairs(ClassRegistry.get_subclasses(class)) do
        ObjectRegistry.for_each_object(subclass, handler)
    end
end

function ObjectRegistry.find_object(class, matcher)
    local class_name = ClassRegistry.get_class_name(class)
    local objects = ObjectRegistry.class_indexes[class_name]
    local object = objects and Table.find(objects, matcher)
    if object then return object end
    return Table.find(ClassRegistry.get_subclasses(class), function(subclass)
        return ObjectRegistry.find_object(subclass, matcher)
    end)
end

function ObjectRegistry.filter_objects(class, filter)
    local class_name = ClassRegistry.get_class_name(class)
    local result = {}
    if ObjectRegistry.class_indexes[class_name] then
        Table.merge(result, Table.filter(ObjectRegistry.class_indexes[class_name], filter))
        Table.each(ClassRegistry.get_subclasses(class), function(subclass)
            Table.merge(result, ObjectRegistry.filter_objects(subclass, filter))
        end)
    end
    return result
end

return ObjectRegistry
