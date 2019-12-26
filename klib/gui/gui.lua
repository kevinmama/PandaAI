local table = require('__stdlib__/stdlib/utils/table')
local KC = require('klib/container/container')
local TypeUtil = require('klib/utils/type_utils')
local gui = {}

gui.GuiManager = require 'klib/gui/gui_manager'
gui.RootComponent = require 'klib/gui/component/root_component'
gui.top = gui.RootComponent.Top
gui.left = gui.RootComponent.Left
gui.center = gui.RootComponent.Center

local function define_component_creator(method_name, component_class, convenient_constructor)
    local constructor = function(options)
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

    gui[method_name] = function(first, ...)
        if TypeUtil.is_table(first) then
            return constructor(first)
        else
            return convenient_constructor(constructor, first, ...)
        end
    end
end

gui.Button = require 'klib/gui/component/button'
define_component_creator('button', gui.Button, function(constructor, name, caption, parent)
    return constructor({
        name = name,
        caption = caption
    }):attach(parent)
end)

gui.Flow = require 'klib/gui/component/flow'
define_component_creator('flow', gui.Flow, function(constructor, name, direction, parent)
    if TypeUtil.is_table(direction) then
        parent = direction
        direction = gui.Flow.options.direction
    end
    return constructor({
        name = name,
        direction = direction
    }):attach(parent)
end)

gui.Label = require 'klib/gui/component/label'
define_component_creator('label', gui.Label, function(constructor, name, caption, parent)
    return constructor({
        name = name,
        caption = caption,
    }):attach(parent)
end)

gui.Table = require 'klib/gui/component/table'
define_component_creator('table', gui.Table, function(constructor, name, column_count, parent)
    return constructor({
        name = name,
        column_count = column_count
    }):attach(parent)
end)

function gui.Table:label_item(name, label, value)
    local label_name = name .. '_label'
    local value_name = name .. '_value'
    local label_component, value_component
    if TypeUtil.is_function(label) then
        label_component = gui.label(label_name, '')
        label(label_component)
    else
        label_component = gui.label(label_name, label)
    end
    if TypeUtil.is_function(value) then
        value_component = gui.label(value_name, '')
        value(value_component)
    else
        value_component = gui.label(value_name, value)
    end
    return self:row(label_component, value_component)
end

gui.ButtonTab = require 'klib/gui/component/button_tab'
define_component_creator('button_tab', gui.ButtonTab, function(constructor, name, parent)
    return constructor({
        name = name
    }):attach(parent)
end)

return gui
