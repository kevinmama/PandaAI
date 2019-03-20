local KC = require 'klib/container/container'
local AbstractComponent = require 'klib/gui/component/abstract_component'
local LazyTable = require 'klib/utils/lazy_table'
local TypeUtils = require 'klib/utils/type_utils'

-- 所有 ui 组件都用其子类
local Component = KC.singleton('klib.gui.component.Component', AbstractComponent, {
    _visible = true
}, function(self)
    AbstractComponent(self)
end)

function Component:get_options()
    return LazyTable.get_or_create_table(self:get_class(), "options")
end

function Component:get_style()
    return LazyTable.get_or_create_table(self:get_class(), "style")
end

function Component:set_style(name, value)
    if TypeUtils.is_table(name) then
        LazyTable.set(self:get_class(), "style", style)
    else
        self:get_style()[name] = value
    end
    return self
end

function Component:get_name()
    return self:get_options().name
end

function Component:get_parent()
    return self:get_class().parent
end

function Component:set_parent(parent)
    self:get_class().parent = parent
end

function Component:create(player_index)
    local element = self:get_parent():get_element(player_index).add(self:get_options())
    element.visible = self._visible
    table.each(self:get_style(), function(value, key)
        element.style[key] = value
    end)

    local ins = KC.get(self)
    ins.element_registry[player_index] = element
    ins:create_children(player_index)
    return self
end

function Component:attach(parent)
    if parent ~= nil then
        self:set_parent(parent)
        parent:add_child(self)
    end
    return self
end

function Component:with(define_block)
    define_block(self)
    return self
end

function Component:visible(visible)
    self._visible = visible
    return self
end

function Component:toggle_visibility(player_index)
    local element = self:get_element(player_index)
    element.visible = not element.visible
    return self
end

return Component