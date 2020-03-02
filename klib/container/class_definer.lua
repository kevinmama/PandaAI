local Symbols = require 'klib/container/symbols'
local Helper = require 'klib/container/helper'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'
local EventBinder = require 'klib/container/event_binder'
local dlog = require 'klib/container/dlog'
local table = require('__stdlib__/stdlib/utils/table')

local trigger = Helper.trigger

local ClassDefiner = {}

function ClassDefiner.define_singleton(class, singleton)
    class[Symbols.SINGLETON] = singleton
end

function ClassDefiner.define_class_variables(class, definition_table)
    table.merge(class, definition_table)
end

function ClassDefiner.define_class_functions(class)
    class[Symbols.GET_CLASS_NAME] = function()
        return ClassRegistry.get_class_name(class)
    end
    class[Symbols.GET_CLASS] = function()
        return ClassRegistry.get_class(class)
    end
    class[Symbols.GET_ID] = function(self)
        return ObjectRegistry.get_id(self)
    end
end

function ClassDefiner.define_base_class(class, base_class)
    if base_class ~= nil then
        getmetatable(class).__index = base_class
        class[Symbols.BASE_CLASS_NAME] = base_class[Symbols.CLASS_NAME]
        class[Symbols.GET_BASE_CLASS_NAME] = function(self)
            return self[Symbols.BASE_CLASS_NAME]
        end
        class[Symbols.SUPER] = base_class
    end
end

function ClassDefiner.define_constructor(class, constructor)
    class[Symbols.CONSTRUCTOR] = constructor
    class[Symbols.NEW] = function(self, ...)
        local object = ObjectRegistry.new_instance(class, {})
        ClassDefiner.initialize_object(object, ...)
        return object
    end
    --getmetatable(class).__call = function(class, object, ...)
    --    constructor(object, ...)
    --end
end

function ClassDefiner.define_destroyer(class)
    class[Symbols.DESTROY] = function(self)
        trigger(self, Symbols.ON_DESTROY)
        ObjectRegistry.destroy_instance(self)
    end
end

function ClassDefiner.define_event_binder(class)
    class[Symbols.BIND_EVENT] = function(self, event_id, handler, for_singleton)
        if for_singleton == nil then
            for_singleton = class[Symbols.SINGLETON]
        end

        if for_singleton then
            EventBinder.bind_singleton_event(function()
                return ClassDefiner.singleton(self)
            end, event_id, handler)
        else
            EventBinder.bind_class_event(class, event_id, handler)
        end
        return self
    end
end

function ClassDefiner.initialize_object(object, ...)
    if object[Symbols.CONSTRUCTOR] then
        object[Symbols.CONSTRUCTOR](object, ...)
    end
    trigger(object, Symbols.ON_READY)
end

--- get singleton, create it if not exists
function ClassDefiner.singleton(class, ...)
    local object = ObjectRegistry.get_singleton(class)
    if object == nil then
        object = ObjectRegistry.new_singleton(class)
        ClassDefiner.initialize_object(object, ...)
    end
    return object
end

return ClassDefiner

