--------------------------------------------------------------------------------
--- KContainer.lua (by kevinma)
--- a simple IOC container, help to manage object's lifecycle
--------------------------------------------------------------------------------

local KContainer = {}

--------------------------------------------------------------------------------
--- constants
--------------------------------------------------------------------------------

local GLOBAL_REGISTRY = "kcontainer"
local CLASS_REGISTRY = "classes"
local OBJECT_REGISTRY = "objects"

local CLASS_NAME = "__kclass"
local OBJECT_ID = "__kid"
local EXTEND = "__extend"

local SUPER = "super"
local NEW = "new"
local ORIGINAL_NEW = "_new"
local ON_LOAD = "on_load"
local ON_READY = "on_ready"
local DESTROY = "destroy"
local ON_DESTROY = "on_destroy"

KContainer.CLASS_NAME = CLASS_NAME
KContainer.OBJECT_ID = OBJECT_ID

local class_registry = {}
local object_registry = {}

--------------------------------------------------------------------------------
--- helper functions
--------------------------------------------------------------------------------

local function is_table(object)
    return type(object) == 'table'
end

local function is_number(object)
    return type(object) == 'number'
end

local function is_int(object)
    return type(object) == 'number' and object == math.floor(object)
end

local function is_string(object)
    return type(object) == 'string'
end

local function exists(var)
    if var then
        return true
    else
        return false
    end
end

local function is_native_class(object)
    return type(object) == 'table' and type(object.__self) == 'userdata'
end

local function merge_table(to, from)
    for k, v in pairs(from) do
        to[k] = v
    end
    return to
end

--------------------------------------------------------------------------------
--- id manager
--------------------------------------------------------------------------------

local IdAllocator = {
    _next_object_id = 1
}
function IdAllocator.next_object_id()
    local the_return_id = IdAllocator._next_object_id
    IdAllocator._next_object_id = IdAllocator._next_object_id + 1
    return the_return_id
end

function IdAllocator.update_next_object_id(id)
    if is_int(id) and IdAllocator._next_object_id <= id then
        IdAllocator._next_object_id = id + 1
    end
end

--------------------------------------------------------------------------------
--- errors
--------------------------------------------------------------------------------

local Error = {}
function Error.table_is_not_a_class_error()
    error("table is not a class. A class is a table with key '" .. CLASS_NAME .. "'")
end

function Error.class_not_registered_error()
    error("before get a object, you should register it")
end

function Error.get_object_error(variants)
    error("variants should be a class or a integer id, but was ".. serpent.block(variants))
end

--------------------------------------------------------------------------------
--- class helper functions
--------------------------------------------------------------------------------

local KClassHelper = {}

function KClassHelper.is_registered(object)
    return is_table(object) and exists(object[CLASS_NAME]) and exists(class_registry[object[CLASS_NAME]])
    --return is_table(object) and safe_contains_key(object, CLASS_NAME) and exists(class_registry[object[CLASS_NAME]])
end

function KClassHelper.get_class(object)
    return class_registry[object[CLASS_NAME]]
end

function KClassHelper.get_class_name(object)
    return object[CLASS_NAME]
end

function KClassHelper.validate(class)
    return exists(class[CLASS_NAME])
end

--------------------------------------------------------------------------------
--- object helper functions
--------------------------------------------------------------------------------

local KObjectHelper = {}

function KObjectHelper.get_by_id(object_id)
    return object_registry[object_id]
end

function KObjectHelper.get_id(object)
    return object[OBJECT_ID]
end

function KObjectHelper.get_singleton(class)
    return object_registry[KClassHelper.get_class_name(class)]
end

function KObjectHelper.get_or_new_singleton(class)
    local object = KObjectHelper.get_singleton(class)
    if not object then
        object = KObjectHelper.new_singleton(class)
    end
    return object
end

function KObjectHelper.new_object(class, data)
    local registered_class = KClassHelper.get_class(class)
    local data = data or {}
    data[CLASS_NAME] = registered_class[CLASS_NAME]
    return setmetatable(data, { __index = registered_class })
end

function KObjectHelper.new_singleton(class)
    local key = KClassHelper.get_class_name(class)
    local object = KObjectHelper.new_object(class, nil)
    object[OBJECT_ID] = key
    object_registry[key] = object
    return object
end

function KObjectHelper.new_instance(class, data)
    local object = KObjectHelper.new_object(class, data)
    local key = IdAllocator.next_object_id()
    object[OBJECT_ID] = key
    object_registry[key] = object
    return object
end

function KObjectHelper.load_object(data)
    -- use nil because cannot change global table during load
    local object = KObjectHelper.new_object(KClassHelper.get_class(data))
    merge_table(object, data)
    local id = KObjectHelper.get_id(object)
    object_registry[id] = object
    IdAllocator.update_next_object_id(id)
    return object
end

function KObjectHelper.destroy_instance(object)
    local key = KObjectHelper.get_id(object)
    object_registry[key] = nil
    return object
end

--------------------------------------------------------------------------------
--- lifecycle functions
--------------------------------------------------------------------------------

local function trigger(object, func)
    if object[func] then
        object[func](object)
    end
end

--------------------------------------------------------------------------------
--- Creator
--------------------------------------------------------------------------------

local Creator = {}

function Creator.define_class_variables(class, definition_table)
    merge_table(class, definition_table)
end

function Creator.define_base_class(class, base_class)
    setmetatable(class, {__index = base_class})
    if base_class ~= nil then
        class[SUPER] = base_class[ORIGINAL_NEW]
    end
end

function Creator.define_new_function(class, new_function)
    class[ORIGINAL_NEW] = new_function
    class[NEW] = function(self, ...)
        local object = KObjectHelper.new_instance(class, {})
        Creator.initialize_object(object, ...)
        return object
    end
end

function Creator.define_destroy_function(class)
    class[DESTROY] = function(self)
        trigger(self, ON_DESTROY)
        KObjectHelper.destroy_instance(self)
    end
end

function Creator.initialize_object(object, ...)
    if object[ORIGINAL_NEW] then
        object[ORIGINAL_NEW](object, ...)
    end
    if object[ON_READY] then
        object[ON_READY](object)
    end
end


--------------------------------------------------------------------------------
--- KContainer functions -- new part
--------------------------------------------------------------------------------

local function find_base_class(base_class)
    if base_class then
        if is_table(base_class) then
            return base_class
        else
            return class_registry[base_class]
        end
    else
        return nil
    end
end

function KContainer.define_class(class_name, definition_table, new_function)
    local class = {}
    class[CLASS_NAME] = class_name
    class_registry[class_name] = class

    local base_class = nil
    if is_table(definition_table) then
        Creator.define_class_variables(class, definition_table)
        base_class = definition_table[EXTEND]
    else
        new_function = definition_table
    end

    base_class = find_base_class(base_class)
    Creator.define_base_class(class, base_class)
    Creator.define_new_function(class, new_function)
    Creator.define_destroy_function(class)
    return class
end

function KContainer.register_class(class)
    if KClassHelper.validate(class) then
        class_registry[KClassHelper.get_class_name(class)] = class
    else
        return Error.table_is_not_a_class_error()
    end
end

--- get singleton, create it if not exists
function KContainer.singleton(class, ...)
    local object = KObjectHelper.get_singleton(class)
    if not exists(object) then
        object = KObjectHelper.new_singleton(class)
        Creator.initialize_object(object, ...)
    end
    return object
end

--- if variants is a class, get or create its singleton
--- if variants is a integer id, try to retrieve the object with the give id
function KContainer.get(variants)
    if KClassHelper.is_registered(variants) then
        return KContainer.singleton(variants)
    elseif is_int(variants) then
        return KObjectHelper.get_by_id(variants)
    else
        Error.get_object_error()
    end
end

--------------------------------------------------------------------------------
--- Loader
--------------------------------------------------------------------------------

local Loader = {}
function Loader.new_instance_if_not_exists(data)
    local id = KObjectHelper.get_id(data)
    local object = KObjectHelper.get_by_id(id)
    if not exists(object) then
        log('loading object ' .. data[CLASS_NAME] .. ' : ' .. data[OBJECT_ID])

        object = KObjectHelper.load_object(data)
        Loader.load_table(object)

        --log(inspect(KObjectHelper.get_by_id(id)))
        trigger(object, ON_LOAD)
        trigger(object, ON_READY)
    else
        log("object has exists " .. data[CLASS_NAME] .. ' : ' .. data[OBJECT_ID])
        --log(inspect(object))
    end
    return object
end

function Loader.load_table(table)
    for key, value in pairs(table) do
        table[key] = Loader.load_object(value)
    end
    return table
end

function Loader.load_object(data)
    if is_native_class(data) then
        return data
    elseif KClassHelper.is_registered(data) then
        return Loader.new_instance_if_not_exists(data)
    elseif is_table(data) then
        local object = merge_table({}, data)
        setmetatable(object, getmetatable(data))
        return Loader.load_table(object)
    else
        return data
    end
end

--- used in on_load, rebuild objects of registered class
function KContainer.load(global)
    Loader.load_object(global[GLOBAL_REGISTRY][OBJECT_REGISTRY])
end

--- persist registry to 'global' table
function KContainer.persist(global)
    local registry = {}
    global[GLOBAL_REGISTRY] = registry
    --registry[CLASS_REGISTRY] = class_registry
    registry[OBJECT_REGISTRY] = object_registry
end

return KContainer
