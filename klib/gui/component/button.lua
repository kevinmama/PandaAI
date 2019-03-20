local KC = require 'klib/container/container'
local Component = require 'klib/gui/component/component'
local Event = require 'klib/gui/event/event'
local TypeUtils = require 'klib/utils/type_utils'

local Button = KC.singleton('klib.gui.component.Button', Component, {
    options = {
        type = 'button'
    }
}, function(self)
    Component(self)
end)

function Component:on_click(handler)
    Event.on_click(self:get_name(), function(event)
        event.component = self
        handler(event)
    end)
    return self
end

function Component:toggle_component(component)
    if TypeUtils.is_function(component) then
        component = component(self)
    end
    self:on_click(function(event)
        local element = component:get_element(event.player_index)
        element.visible = not element.visible
    end)
    return self
end

return Button