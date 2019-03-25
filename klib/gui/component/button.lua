local KC = require 'klib/container/container'
local Component = require 'klib/gui/component/component'
local Event = require 'klib/gui/event/event'
local TypeUtils = require 'klib/utils/type_utils'
local LazyTable = require 'klib/utils/lazy_table'

local Button = KC.singleton('klib.gui.component.Button', Component, {
    options = {
        type = 'button'
    }
}, function(self)
    Component(self)
end)

function Button:on_click(handler)
    Event.on_click(self:get_name(), function(event)
        event.component = self
        handler(event)
    end)
    return self
end

function Button:toggle_component(component)
    if TypeUtils.is_function(component) then
        component = component(self)
    end
    --log("register toggle component " .. component:get_name() .. " to " .. self:get_name())
    self:_add_toggle_component(component)
    self:on_click(function(event)
        self:perform_toggle_component(event.player_index)
    end)
    return self
end

function Button:_add_toggle_component(component)
    LazyTable.add(self:get_class(), "_toggle_components", component)
    return self
end

function Button:perform_toggle_component(player_index, visible)
    local components = self:get_class_attr("_toggle_components")
    if components ~= nil then
        for name, component in ipairs(components) do
            --log("the toggle component name is " .. name)
            local element = component:get_element(player_index)
            if visible == true or visible == false then
                element.visible = visible
            else
                element.visible = not element.visible
            end
        end
    end
end

return Button

