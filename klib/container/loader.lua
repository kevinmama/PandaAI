local table = require('__stdlib__/stdlib/utils/table')
local TypeUtils = require 'klib/utils/type_utils'
local Symbols = require 'klib/container/symbols'
local Helper = require 'klib/container/helper'
local ClassRegistry = require 'klib/container/class_registry'
local ObjectRegistry = require 'klib/container/object_registry'

local is_native = TypeUtils.is_native
local is_table = TypeUtils.is_table
local trigger = Helper.trigger

local CLASS_NAME = Symbols.CLASS_NAME
local OBJECT_ID = Symbols.OBJECT_ID
local ON_LOAD = Symbols.ON_LOAD
local ON_READY = Symbols.ON_READY


local Loader = {}
function Loader.new_instance_if_not_exists(data)
    local id = ObjectRegistry.get_id(data)
    local object = ObjectRegistry.get_by_id(id)
    if object == nil then
        log('loading object ' .. data[CLASS_NAME] .. ' : ' .. data[OBJECT_ID])

        object = ObjectRegistry.load_object(data)
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
    if is_native(data) then
        return data
    elseif ClassRegistry.is_registered(data) then
        return Loader.new_instance_if_not_exists(data)
    elseif is_table(data) then
        local object = table.merge({}, data)
        setmetatable(object, getmetatable(data))
        return Loader.load_table(object)
    else
        return data
    end
end

return Loader
