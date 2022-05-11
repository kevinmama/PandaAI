local Event = require 'klib/event/event'
local Symbols = require 'klib/container/symbols'
local Loader = require 'klib/container/loader'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'
local ClassDefiner = require 'klib/container/class_definer'

local GLOBAL_REGISTRY = Symbols.GLOBAL_REGISTRY
local OBJECT_REGISTRY = Symbols.OBJECT_REGISTRY
local CLASS_REGISTRY = Symbols.CLASS_REGISTRY

local ApiInit = {}

--- init registry to 'global' table
function ApiInit.init(global)
    --registry[CLASS_REGISTRY] = class_registry
    local registry = {}
    global[GLOBAL_REGISTRY] = registry
    registry[OBJECT_REGISTRY] = ObjectRegistry.object_registry
    registry[CLASS_REGISTRY] = ClassRegistry.class_variable_registry
    -- 初始化所有单例，如果单倒需要参数，则要设置不能自动初始化
    ClassRegistry.for_each_singleton(function(class)
        if not class[Symbols.LAZY_INIT] then
            ClassDefiner.singleton(class)
        end
    end)
end

--- used in on_load, rebuild objects of registered class
function ApiInit.load(global)
    if global[GLOBAL_REGISTRY] then
        if global[GLOBAL_REGISTRY][CLASS_REGISTRY] then
            ClassRegistry.class_variable_registry = global[GLOBAL_REGISTRY][CLASS_REGISTRY]
        end
        if global[GLOBAL_REGISTRY][OBJECT_REGISTRY] then
            ObjectRegistry.object_registry = global[GLOBAL_REGISTRY][OBJECT_REGISTRY]
            Loader.load_object(ObjectRegistry.object_registry)
        end
    end
end

function ApiInit.init_container(Container)
    Event.on_init(function()
        Container.init(global)
        --dlog("after KContainer.persist(global): ",global)
    end)

    Event.on_load(function()
        --dlog("before KContainer.load(global): ", global)
        Container.load(global)
        --Container.persist(global)
        --dlog("after KContainer.persist(global): ",global)
    end)
end

return ApiInit
