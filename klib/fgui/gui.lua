local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local FGui = require 'flib.gui'
local Table = require 'klib/utils/table'

local Gui = KC.singleton('klib.fgui.Gui', function(self)
    self.builders = {}
end)

function Gui:builder(builder)
    Table.insert(self, builder)
end

Gui:on(defines.events.on_player_created, function(self, event)
    for _, builder in ipairs(self.builders) do
        builder(game.get_player(event.player_index))
    end
end)

local gui_event_defines = {}
for name, id in pairs(defines.events) do
    if string.find(name, "^on_gui") then
        gui_event_defines[name] = id
    end
end

function Gui.hook_events(callback)
    for _, id in pairs(gui_event_defines) do
        Event.register(id, callback)
    end
end


Gui.read_action = FGui.read_action
Gui.build = FGui.build
Gui.add = FGui.add
Gui.update = FGui.update
Gui.get_tags = FGui.get_tags
Gui.set_tags = FGui.set_tags
Gui.delete_tags = FGui.delete_tags
Gui.update_tags = FGui.update_tags
Gui.set_action = FGui.set_action
Gui.get_action = FGui.get_action

return Gui