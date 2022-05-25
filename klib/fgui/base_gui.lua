require 'klib/fgui/tweak'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local Type = require 'klib/utils/type'

local BaseGui = KC.class('klib.fgui.BaseGui', function(self)
    self.refs = {}
end)

function BaseGui:build(player_index)
end

function BaseGui:remove(player_index)
end

function BaseGui:hook_events()
    gui.hook_events(function(e)
        local action = gui.read_action(e)
        if action then
            local refs = e.player_index and self.refs[e.player_index]

            local ensure_func = self['ensure_' .. action]
            if Type.is_function(ensure_func) then
                if not ensure_func(self, e, refs) then
                    return
                end
            end

            if Type.is_function(self[action]) then
                self[action](self, e, refs)
            end
        end
    end)
end

function BaseGui:on_ready()
    self:on(defines.events.on_player_created, function(self, event)
        self:build(event.player_index)
    end)
    self:on(defines.events.on_player_removed, function(self, event)
        self:remove(event.player_index)
    end)
    self:hook_events()
end

return BaseGui
