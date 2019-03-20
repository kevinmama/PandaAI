local KC = require 'klib/container/container'
local Component = require 'klib/gui/component/component'
local Label = require 'klib/gui/component/label'

local Table = KC.singleton('klib.gui.component.Table', Component, {
    options = {
        type = 'table'
    }
},function(self)
    Component(self)
end)

function Table:row(...)
    for _, component in pairs({...}) do
        component:attach(self)
    end
    return self
end


return Table
