local KC = require 'klib/container/container'
local Component = require 'klib/gui/component/component'

local Label = KC.singleton('klib.gui.component.Label', Component, {
    options = {
        type = 'label'
    }
},function(self)
    Component(self)
end)

return Label
