local KC = require 'klib/container/container'
local Component = require 'klib/gui/component/component'

local Flow = KC.singleton('klib.gui.component.Flow', Component, {
    options = {
        type = 'flow',
        direction = 'vertical'
    }
}, function(self)
    Component(self)
end)

return Flow
