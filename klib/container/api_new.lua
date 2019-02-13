local TypeUtils = require 'klib/utils/type_utils'
local Symbols = require 'klib/container/symbols'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'
local Creator = require 'klib/container/creator'

local is_table = TypeUtils.is_table
local is_int = TypeUtils.is_int
local EXTEND = Symbols.EXTEND

local ApiNew = {}

function ApiNew.define_class(class_name, definition_table, new_function)
    local class = ClassRegistry.new_class(class_name)
    local base_class = nil
    if is_table(definition_table) then
        Creator.define_class_variables(class, definition_table)
        base_class = definition_table[EXTEND]
    else
        new_function = definition_table
    end

    base_class = ClassRegistry.get_class(base_class)
    Creator.define_base_class(class, base_class)
    Creator.define_new_function(class, new_function)
    Creator.define_destroy_function(class)
    return class
end

--- get singleton, create it if not exists
function ApiNew.singleton(class, ...)
    local object = ObjectRegistry.get_singleton(class)
    if object == nil then
        object = ObjectRegistry.new_singleton(class)
        Creator.initialize_object(object, ...)
    end
    return object
end

--- if variants is a class, get or create its singleton
--- if variants is a integer id, try to retrieve the object with the give id
function ApiNew.get(variants)
    if ClassRegistry.is_registered(variants) then
        return ApiNew.singleton(variants)
    elseif is_int(variants) then
        return ObjectRegistry.get_by_id(variants)
    else
        error("variants should be a class or a integer id, but was ".. serpent.block(variants))
    end
end

return ApiNew