local TableUtils = require 'klib/utils/table_utils'
local Symbols = require 'klib/container/symbols'
local Helper = require 'klib/container/helper'
local ObjectRegistry = require 'klib/container/object_registry'

local merge_table = TableUtils.merge_table

local trigger = Helper.trigger

local SUPER = Symbols.SUPER
local ORIGINAL_NEW = Symbols.ORIGINAL_NEW
local NEW = Symbols.NEW
local ON_READY = Symbols.ON_READY
local DESTROY = Symbols.DESTROY
local ON_DESTROY = Symbols.ON_DESTROY

local Creator = {}

function Creator.define_class_variables(class, definition_table)
    merge_table(class, definition_table)
end

function Creator.define_base_class(class, base_class)
    if base_class ~= nil then
        setmetatable(class, {__index = base_class})
        class[SUPER] = base_class[ORIGINAL_NEW]
    end
end

function Creator.define_new_function(class, new_function)
    class[ORIGINAL_NEW] = new_function
    class[NEW] = function(self, ...)
        local object = ObjectRegistry.new_instance(class, {})
        Creator.initialize_object(object, ...)
        return object
    end
end

function Creator.define_destroy_function(class)
    class[DESTROY] = function(self)
        trigger(self, ON_DESTROY)
        ObjectRegistry.destroy_instance(self)
    end
end

function Creator.initialize_object(object, ...)
    if object[ORIGINAL_NEW] then
        object[ORIGINAL_NEW](object, ...)
    end
    trigger(object, ON_READY)
end

return Creator
