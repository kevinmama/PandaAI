local Symbols = require 'klib/container/symbols'
local Loader = require 'klib/container/loader'
local ObjectRegistry = require 'klib/container/object_registry'

local GLOBAL_REGISTRY = Symbols.GLOBAL_REGISTRY
local OBJECT_REGISTRY = Symbols.OBJECT_REGISTRY
local CLASS_REGISTRY = Symbols.CLASS_REGISTRY

local ApiLoad = {}
--- used in on_load, rebuild objects of registered class
function ApiLoad.load(global)
    Loader.load_object(global[GLOBAL_REGISTRY][OBJECT_REGISTRY])
end

--- persist registry to 'global' table
function ApiLoad.persist(global)
    local registry = {}
    global[GLOBAL_REGISTRY] = registry
    --registry[CLASS_REGISTRY] = class_registry
    registry[OBJECT_REGISTRY] = ObjectRegistry.object_registry
end

return ApiLoad
