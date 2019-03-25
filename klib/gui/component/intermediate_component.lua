local KC = require 'klib/container/container'
local AbstractComponent = require 'klib/gui/component/abstract_component'
local LazyTable = require 'klib/utils/lazy_table'

local IntermediateComponent = KC.singleton('klib.gui.component.IntermediateComponent', AbstractComponent, {

}, function(self)
    AbstractComponent(self)
end)

function IntermediateComponent:get_options()
    return LazyTable.get_or_create_table(self:get_class(), "options")
end

function IntermediateComponent:get_name()
    return self:get_options().name
end

function IntermediateComponent:get_parent()
    return self:get_class().parent
end

function IntermediateComponent:set_parent(parent)
    self:get_class().parent = parent
end

function IntermediateComponent:attach(parent)
    if parent ~= nil then
        self:set_parent(parent)
        parent:add_child(self)
    end
    return self
end

return IntermediateComponent

