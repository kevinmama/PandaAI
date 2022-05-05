local Symbols = require 'klib/container/symbols'
local Loader = require 'klib/container/loader'
local ObjectRegistry = require 'klib/container/object_registry'

local GLOBAL_REGISTRY = Symbols.GLOBAL_REGISTRY
local OBJECT_REGISTRY = Symbols.OBJECT_REGISTRY
local CLASS_REGISTRY = Symbols.CLASS_REGISTRY

local ApiLoad = {}

--- init registry to 'global' table
function ApiLoad.init(global)
    --registry[CLASS_REGISTRY] = class_registry
    local registry = {}
    global[GLOBAL_REGISTRY] = registry
    registry[OBJECT_REGISTRY] = ObjectRegistry.object_registry
end

--- used in on_load, rebuild objects of registered class
function ApiLoad.load(global)
    if global[GLOBAL_REGISTRY] and global[GLOBAL_REGISTRY][OBJECT_REGISTRY] then
        ObjectRegistry.object_registry = global[GLOBAL_REGISTRY][OBJECT_REGISTRY]
        Loader.load_object(ObjectRegistry.object_registry)
    end
end


return ApiLoad
