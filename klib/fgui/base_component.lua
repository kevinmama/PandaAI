require 'klib/fgui/tweak'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local LazyTable = require 'klib/utils/lazy_table'
local Type = require 'klib/utils/type'

local BaseComponent = KC.class('klib.fgui.BaseComponent', function(self)
    self.refs = {}
    self.data = {}
    self.force_check_action = true
end)

function BaseComponent:handle_event(event)
    local action = gui.read_action(event)
    if action then
        local handler = self[action]
        if Type.is_function(handler) then
            local checker = self['is_' .. action]
            local refs = event.player_index and self.refs[event.player_index]
            -- 强制检查情况下，只有当检查函数存在并返回真，才执行事件处理函数
            if self.force_check_action then
                if Type.is_function(checker) and checker(self, event, refs) then
                    handler(self, event, refs)
                end
            else
            -- 不强制检查，则只有当检查函数存在时才执行，否则全当真
                if Type.is_function(checker) then
                    if not checker(self, event, refs) then return end
                end
                handler(self, event, refs)
            end
        end
    end
end

local function _define_player_data (self, var_name)
    self['get_' .. var_name] = function(self, player_index)
        return LazyTable.get(self.data, player_index, var_name)
    end
    self['set_' .. var_name] = function(self, player_index, value)
        LazyTable.set(self.data, player_index, var_name, value)
    end
end

function BaseComponent:define_player_data(var_name)
    if Type.is_table(var_name) then
        for _, name in pairs(var_name) do _define_player_data(self, name) end
    else
        _define_player_data(self, var_name)
    end
end

function BaseComponent:on_ready()
    gui.hook_events(function(event)
        self:handle_event(event)
    end)
end

return BaseComponent
