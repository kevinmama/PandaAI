local table = require '__stdlib__/stdlib/utils/table'
local KC = require 'klib/container/container'
local LazyTable = require 'klib/utils/lazy_table'
local dlog = require 'klib/utils/dlog'

-- 定义子类来控制 UI, 每个子类都应该是单例

local AbstractComponent = KC.class('klib.gui.component.AbstractComponent', function(self)
    self.element_registry = {}
    self.data_registry = {}
end)

function AbstractComponent:get_element(player_index)
    return KC.get(self).element_registry[player_index]
end

function AbstractComponent:get_data(player_index, key)
    return LazyTable.get(KC.get(self).data_registry, player_index, key)
end

function AbstractComponent:set_data(player_index, key, value)
    LazyTable.set(KC.get(self).data_registry, player_index, key, value)
    return self
end

function AbstractComponent:get_children()
    return LazyTable.get_or_create_table(self:get_class(), "children")
end

function AbstractComponent:add_child(child)
    LazyTable.add(self:get_class(), "children", child)
    return self
end

function AbstractComponent:each_child(handler)
    table.each(self:get_children(), handler)
    return self
end

function AbstractComponent:set_class_attr(key, value)
    self:get_class()[key] = value
    return self
end

function AbstractComponent:get_class_attr(key)
    return self:get_class()[key]
end

function AbstractComponent:create()
    error("should implement by subclass")
end

function AbstractComponent:create_children(player_index)
    dlog("creating children of component " .. self:get_name() .. " for player " .. player_index)
    self:each_child(function(child)
        KC.get(child):create(player_index)
    end)
end

function AbstractComponent:with(define_block)
    define_block(self)
    return self
end


return AbstractComponent
