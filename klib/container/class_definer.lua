local Symbols = require 'klib/container/symbols'
local Helper = require 'klib/container/helper'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'
local EventBinder = require 'klib/container/event_binder'
local Type = require 'klib/utils/type'

local trigger = Helper.trigger

local ClassDefiner = {}

function ClassDefiner.define_singleton(class, singleton)
    class[Symbols.SINGLETON] = singleton
end

local function parse_class_variable_definitions(definition_table)
    local variable_names = {}
    local variables = {}
    local initializer
    for key, value in pairs(definition_table) do
        if Type.is_number(key) then
            if Type.is_function(value) then
                initializer = value
            else
                table.insert(variable_names, value)
            end
        else
            table.insert(variable_names, key)
            variables[key] = value
        end
    end
    return variable_names, variables, initializer
end

function ClassDefiner.define_class_variables(class, definition_table)
    local variable_names, variables, initializer = parse_class_variable_definitions(definition_table)
    -- class variables are storage in global
    ClassRegistry.set_initial_class_variables(class, variables, initializer)
    for _, name in pairs(variable_names) do
        local getter_name = 'get_' .. name
        local setter_name = 'set_' .. name
        class[getter_name] = function(self)
            return ClassRegistry.get_class_variable(class, name)
        end
        class[setter_name] = function(self,value)
            return ClassRegistry.set_class_variable(class, name, value)
        end
    end
end

function ClassDefiner.define_class_functions(class)
    class[Symbols.GET_CLASS_NAME] = function()
        return ClassRegistry.get_class_name(class)
    end
    class[Symbols.GET_CLASS] = function()
        return ClassRegistry.get_class(class)
    end
    class[Symbols.GET_OBJECT_ID] = function(self)
        return ObjectRegistry.get_id(self)
    end
    class[Symbols.GET_OBJECT_ID_SHORT] = class[Symbols.GET_OBJECT_ID]
end

function ClassDefiner.define_base_class(class, base_class)
    if base_class ~= nil then
        getmetatable(class).__index = base_class
        class[Symbols.BASE_CLASS_NAME] = base_class[Symbols.CLASS_NAME]
        class[Symbols.GET_BASE_CLASS_NAME] = function(self)
            return self[Symbols.BASE_CLASS_NAME]
        end
        class[Symbols.SUPER] = base_class
        ClassRegistry.add_subclass(base_class, class)
    end
end

function ClassDefiner.define_constructor(class, constructor)
    class[Symbols.CONSTRUCTOR] = constructor
    class[Symbols.NEW] = function(self, ...)
        local object = ObjectRegistry.new_instance(class, {})
        ClassDefiner.initialize_object(object, ...)
        return object
    end
    class[Symbols.NEW_LOCAL] = function(self, ...)
        local object = ObjectRegistry.new_object(class, {})
        ClassDefiner.initialize_object(object, ...)
        return object
    end
    getmetatable(class).__call = function(class, object, ...)
        constructor(object, ...)
    end
end

function ClassDefiner.define_destroyer(class)
    class[Symbols.DESTROY] = function(self)
        trigger(self, Symbols.ON_DESTROY)
        ObjectRegistry.destroy_instance(self)
        self[Symbols.DESTROYED] = true
    end
end

function ClassDefiner.define_object_references_definer(class)
    class[Symbols.REFERENCE_OBJECTS] = function(self, ...)
        for _, name in pairs({...}) do
            Type.assert_is_string(name, "reference name")
            local field_name = name .. '_id'
            local getter_name = 'get_' .. name
            local setter_name = 'set_' .. name
            class[getter_name] = function(self)
                return self[field_name] and ObjectRegistry.get_by_id(self[field_name])
            end
            class[setter_name] = function(self, object)
                self[field_name] = object and ObjectRegistry.get_id(object)
            end
        end
    end
end

function ClassDefiner.define_event_binder(class)
    class[Symbols.BIND_EVENT] = function(self, event_id, handler,for_singleton)
        EventBinder.bind_class_event(class, event_id, handler)
        --if for_singleton == nil then
        --    for_singleton = class[Symbols.SINGLETON]
        --end

        --if for_singleton then
        --    EventBinder.bind_singleton_event(function()
        --        return ClassDefiner.singleton(self)
        --    end, event_id, handler)
        --else
        --    EventBinder.bind_class_event(class, event_id, handler)
        --end
        return self
    end

    class[Symbols.BIND_NTH_TICK] = function(self, tick, handler, for_singleton)
        return class[Symbols.BIND_EVENT](self, -tick, handler, for_singleton)
    end
end

function ClassDefiner.define_delegate_method(class, instance_name, method_name, alias_name)
    class[alias_name or method_name] = function(self, ...)
        local instance = self[instance_name]
        return instance[method_name](instance, ...)
    end
end

function ClassDefiner.define_delegate_field_getter(class, instance_name, field_name, alias_name)
    class[alias_name or ('get_' .. field_name)] = function(self)
        local instance = self[instance_name]
        return instance[field_name]
    end
end

function ClassDefiner.define_delegate_field_setter(class, instance_name, field_name, alias_name)
    class[alias_name or ('set' .. field_name)] = function(self, value)
        local instance = self[instance_name]
        instance[field_name] = value
    end
end

local function parse_delegate_binder(class, instance_name, method_name, alias_name, definer)
    if Type.is_table(method_name) then
        for _, name in pairs(method_name) do
            local alias = Type.is_function(alias_name) and alias_name(name) or name
            definer(class, instance_name, name, alias)
        end
    elseif Type.is_string(method_name) then
        definer(class, instance_name, method_name, alias_name)
    else
        error("method name must be a string or table of string")
    end
end

function ClassDefiner.define_delegate_binder(class)
    class[Symbols.DELEGATE_METHOD] = function(class, instance_name, method_name, alias_name)
        parse_delegate_binder(class, instance_name, method_name, alias_name, ClassDefiner.define_delegate_method)
    end
    class[Symbols.DELEGATE_FIELD] = function(class, instance_name, field_name, alias_name)
        parse_delegate_binder(class, instance_name, field_name, alias_name, ClassDefiner.define_delegate_field_getter)
        parse_delegate_binder(class, instance_name, field_name, alias_name, ClassDefiner.define_delegate_field_setter)
    end
    class[Symbols.DELEGATE_GETTER] = function(class, instance_name, field_name, alias_name)
        parse_delegate_binder(class, instance_name, field_name, alias_name, ClassDefiner.define_delegate_field_getter)
    end
    class[Symbols.DELEGATE_SETTER] = function(class, instance_name, field_name, alias_name)
        parse_delegate_binder(class, instance_name, field_name, alias_name, ClassDefiner.define_delegate_field_setter)
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

