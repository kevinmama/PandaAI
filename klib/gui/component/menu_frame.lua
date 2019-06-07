-- 只会显示其中一个子组件

local KC = require 'klib/container/container'
local LogicalComponent = require 'klib/gui/component/logical_component'

local MenuFrame = KC.class('klib.gui.component.MenuFrame', LogicalComponent, function(self)
    LogicalComponent(self)
end)

function MenuFrame.set_active(player_index, component)
    local active_index = self:get_data(player_index, "active_index")
    self:each_child(function(child, index)
        if component == child then
            local next_active_index = index
            if active_index ~= next_active_index then
                self.get_children()[active_index]:toggle_visibility(player_index)
            end
            component:toggle_visibility(player_index)
            self:set_data(player_index, "active_index", next_active_index)
        end
    end)
end

return LogicalComponent
