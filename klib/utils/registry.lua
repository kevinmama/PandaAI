local Event = require 'klib/event/event'
local LazyTable = require 'klib/utils/lazy_table'
local Config = require 'klib/config'

local KLIB, REGISTRIES = Config.KLIB, Config.REGISTRIES

local registries = {}
Event.on_init(function()
    LazyTable.set(global, KLIB, REGISTRIES, {})
end)

local Registry = {}

function Registry.new_local(accessor, registry)
    local registry = registry or {}
    local _M = {
        __index = function(_, k)
            return registry[k]
        end,
        __newindex = function(_,k, v)
            registry[k] = v
        end
    }
    if accessor then
        return setmetatable(accessor, _M)
    else
        return registry
    end
end

function Registry.new_global(name, accessor)
    if registries[name] then
        return registries[name]
    else
        Event.on_init(function()
            global[KLIB][REGISTRIES][name] = {}
        end)
        local metatable = setmetatable(accessor or {}, {
            __index = function(self, k)
                return global[KLIB][REGISTRIES][name][k]
            end,
            __newindex = function(self,k, v)
                global[KLIB][REGISTRIES][name][k] = v
            end
        })
        registries[name] = metatable
        return metatable
    end
end

return Registry