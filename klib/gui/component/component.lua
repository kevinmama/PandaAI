local table = require 'stdlib/utils/table'
local KC = require 'klib/container/container'
local IntermediateComponent = require 'klib/gui/component/intermediate_component'
local LazyTable = require 'klib/utils/lazy_table'
local TypeUtils = require 'klib/utils/type'

-- 所有 ui 组件都用其子类
local Component = KC.singleton('klib.gui.component.Component', IntermediateComponent, {
    _visible = true
}, function(self)
    IntermediateComponent(self)
end)

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

function Component:visible(visible)
    self._visible = visible
    return self
end

function Component:toggle_visibility(player_index, visible)
    local element = self:get_element(player_index)
    if visible == true then
        element.visible = true
    elseif visible == false then
        element.visible = false
    else
        element.visible = not element.visible
    end
    return self
end

return Component
