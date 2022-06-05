local TypeUtils = require 'klib/utils/type'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'
local ClassDefiner = require 'klib/container/class_definer'
local ClassBuilder = require 'klib/container/class_builder'
local Vargs = require 'klib/utils/vargs'

local is_table, is_int, is_string, is_boolean, is_function = TypeUtils.is_table, TypeUtils.is_int, TypeUtils.is_string, TypeUtils.is_boolean, TypeUtils.is_function

local ApiNew = {}

function ApiNew.class_builder(class_name)
    return ClassBuilder.new(class_name)
end

local function create_builder(vargs)
    local builder = ClassBuilder.new(vargs:next())
    vargs:next_if(is_string, function(base_class)
        builder:extend(base_class)
    end)
    vargs:next_if(ClassRegistry.is_registered, function(base_class)
        builder:extend(base_class)
    end)
    vargs:next_if(is_boolean, function(singleton)
        if (singleton) then
            builder:singleton()
        end
    end)

    vargs:next_if(is_table, function(class_variables)
        builder:variables(class_variables)
    end)

    vargs:next_if(is_function, function(constructor)
        builder:constructor(constructor)
    end)

    return builder
end


--- KC.class('Foo')   : open class Foo
--- KC.class('Foo', 'Bar', singleton, {}, function(...) ... end)   : define class Foo extend Bar with class variables and constructor
function ApiNew.class(...)
    local vargs = Vargs(...)
    if vargs:length() == 1 then
        return ClassRegistry.get_class(vargs:next())
    else
        return create_builder(vargs):build()
    end
end

-- KC.singleton('Foo') : get the singleton
-- KC.singleton('Foo', 'Bar', {}, function(...) ... end)   : define the singleton class
function ApiNew.singleton(...)
    local vargs = Vargs(...)
    if vargs:length() == 1 then
        return ClassDefiner.singleton(vargs:next())
    else
        local builder = create_builder(vargs)
        builder:singleton()
        return builder:build()
    end
end

--- if variants is a class, get or create its singleton
--- if variants is a string id, try to retrieve the object with the give id
function ApiNew.get(...)
    local args = {...}
    local identity = args[1]
    if ClassRegistry.is_registered(identity) then
        return ClassDefiner.singleton(...)
    elseif is_int(identity) or is_string(identity) then
        return ObjectRegistry.get_by_id(identity)
    else
        error("variants should be a class or a object id, but was ".. serpent.block(variants))
    end
end

return ApiNew