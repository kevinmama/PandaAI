local Event = require 'klib/event/event'
local LazyTable = require 'klib/utils/lazy_table'
local Config = require 'klib/config'

local KLIB, REGISTRIES = Config.KLIB, Config.REGISTRIES

Event.on_init(function()
    LazyTable.set(global, KLIB, REGISTRIES, {})
end)

local registries = {}
return function(name, metatable)
    if registries[name] then
        return registries[name]
    else
        Event.on_init(function()
            global[KLIB][REGISTRIES][name] = {}
        end)
        local metatable = metatable or {}
        local registry = setmetatable(metatable, {
            __index = function(self, k)
                return global[KLIB][REGISTRIES][name][k]
            end,
            __newindex = function(self,k, v)
                global[KLIB][REGISTRIES][name][k] = v
            end
        })
        registries[name] = registry
        return registry
    end
end
