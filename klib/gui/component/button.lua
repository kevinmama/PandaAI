local KC = require 'klib/container/container'
local Component = require 'klib/gui/component/component'
local Event = require 'klib/gui/event/event'

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

return Button