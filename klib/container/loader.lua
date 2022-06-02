local TypeUtils = require 'klib/utils/type'
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

local stack = {}

function Loader.new_instance_if_not_exists(data, callback)
    local id = ObjectRegistry.get_id(data)
    local object = ObjectRegistry.get_by_id(id)
    if object == nil or object.__index == nil then
        log('loading object ' .. data[CLASS_NAME] .. ' : ' .. (data[OBJECT_ID] or "[local]"))

        object = ObjectRegistry.load_object(data)
        Loader.load_table(object, function()
            --log(inspect(KObjectHelper.get_by_id(id)))
            trigger(object, ON_LOAD)
            trigger(object, ON_READY)
            callback(object)
        end)
    else
        log("object has exists " .. data[CLASS_NAME] .. ' : ' .. (data[OBJECT_ID] or "[local]"))
        --log(inspect(object))
        callback(object)
    end
end

function Loader.load_table(tbl, callback)
    table.insert(stack, {nil, function()
        callback(tbl)
    end})
    local pos = #stack
    local offset = table_size(tbl)
    for _, value in pairs(tbl) do
        offset = offset - 1
        table.insert(stack, pos + offset, {value})
    end
end

--- 加载对象
-- 仅重注册元表及事件，不要修改或创建新对象
function Loader.load_object(data, callback)
    if is_native(data) then
        callback(data)
    elseif ClassRegistry.is_registered(data) then
        Loader.new_instance_if_not_exists(data, callback)
    elseif is_table(data) then
        Loader.load_table(data, callback)
    else
        callback(data)
    end
end

local function check_if_recursive_table(loaded_tables, data)
    if is_table(data) then
        if loaded_tables[data] then
            --log("found recursive table: class=" .. (data[CLASS_NAME] or "[table]") .. ' : ' .. (data[OBJECT_ID] or "[local]"))
            return true
        else
            loaded_tables[data] = true
        end
    end
    return false
end

local function empty_function()  end

function Loader.load(data)
    table.insert(stack, {data})
    local loaded = {}
    repeat
        local item = table.remove(stack, #stack)
        local data, func = item[1], item[2]
        if not check_if_recursive_table(loaded, data) then
            Loader.load_object(data, func or empty_function)
        end
    until #stack == 0
end


return {
    load = Loader.load
}
