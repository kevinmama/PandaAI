local KC = require('klib/container/container')
local gui = {}

gui.GuiManager = require 'klib/gui/gui_manager'
gui.RootComponent = require 'klib/gui/component/root_component'
gui.top = gui.RootComponent.Top
gui.left = gui.RootComponent.Left
gui.center = gui.RootComponent.Center

local function define_component_creator(method_name, component_class)
    gui[method_name] = function(options)
        local name = options.name
        if name == nil then
            error('name cannot be nil')
        end
        local internal_class_name = component_class:get_class_name() .. '$' .. name
        local internal_class = KC.singleton(internal_class_name, component_class, function(self)
            component_class(self)
        end)

        internal_class.options = table.merge(table.deepcopy(component_class:get_options()), options)
        return internal_class
    end
end

gui.Button = require 'klib/gui/component/button'
define_component_creator('button', gui.Button)

gui.Flow = require 'klib/gui/component/flow'
define_component_creator('flow', gui.Flow)

gui.Label = require 'klib/gui/component/Label'
define_component_creator('label', gui.Label)

return gui
