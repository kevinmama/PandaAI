local KC = require 'klib/container/container'
local LogicalComponent = require 'klib/gui/component/logical_component'

local ButtonTab = KC.class('klib.gui.component.ButtonTab', LogicalComponent, {

}, function(self)
    LogicalComponent(self)
end)

function ButtonTab:add_child(child)
    self.super:add_child(child)
    child:on_click(function(event)
        -- 这里修改了子类的点击事件，导致多重触发
        self:perform_active_child(event.player_index, child)
    end)
    return self
end

function ButtonTab:perform_active_child(player_index, active_child)
    self:each_child(function(child)
        if active_child ~= child and child.perform_toggle_component then
            child:perform_toggle_component(player_index, false)
        end
    end)
end

return ButtonTab
