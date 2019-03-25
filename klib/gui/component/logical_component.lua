local KC = require 'klib/container/container'
local IntermediateComponent = require 'klib/gui/component/intermediate_component'

local LogicalComponent = KC.singleton('klib.gui.component.LogicalComponent', IntermediateComponent, {

}, function(self)
    IntermediateComponent(self)
end)

function LogicalComponent:get_element(player_index)
    return self.parent:get_element(player_index)
end

function LogicalComponent:create(player_index)
    local ins = KC.get(self)
    ins:create_children(player_index)
    return self
end

return LogicalComponent
