require 'klib/fgui/tweak'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local LazyTable = require 'klib/utils/lazy_table'
local Type = require 'klib/utils/type'
local GE = require 'klib/fgui/gui_element'

local BaseComponent = KC.class('klib.fgui.BaseComponent', function(self)
    self.refs = {}
    self.data = {}
end)

BaseComponent.COMPONENT_ID = "component_id"

local function _define_player_data (self, var_name)
    self['get_' .. var_name] = function(self, player_index)
        return LazyTable.get(self.data, player_index, var_name)
    end
    self['set_' .. var_name] = function(self, player_index, value)
        if value ~= nil then
            LazyTable.set(self.data, player_index, var_name, value)
        else
            LazyTable.remove(self.data, player_index, var_name)
        end
    end
end

function BaseComponent:define_player_data(var_name)
    if Type.is_table(var_name) then
        for _, name in pairs(var_name) do _define_player_data(self, name) end
    else
        _define_player_data(self, var_name)
    end
end

function BaseComponent:set_component_tag(target)
    if GE.is_element(target) then
        -- element
        gui.update_tags(target, {
            [BaseComponent.COMPONENT_ID] = self:get_id()
        })
    elseif Type.is_table(target) then
        -- structure
        local id = self:get_id()
        if id then
            LazyTable.set(target, "tags", BaseComponent.COMPONENT_ID, id)
        else
            LazyTable.remove(target, "tags", BaseComponent.COMPONENT_ID)
        end
    end
end

gui.hook_events(function(event)
    local action = gui.read_action(event)
    if action then
        local tags = gui.get_tags(event.element)
        local component_id = tags[BaseComponent.COMPONENT_ID]
        local component = component_id and KC.get(component_id)
        if component and component[action] then
            local refs = event.player_index and component.refs[event.player_index]
            component[action](component, event, refs)
        end
    end
end)

return BaseComponent
