local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Gui = require '__flib__.gui'
local Table = require '__stdlib__/stdlib/utils/table'

local GuiManager = KC.singleton('klib.fgui.GuiManager', function(self)
    self.creators = {}
end)

local this = function()
    return KC.get(GuiManager)
end

function GuiManager:register_gui_creator(creator)
    Table.insert(this().creators, creator)
end

local function create_gui_for_player(player)
    for _, creator in pairs(this().creators) do
        creator(player)
    end
end

local function create_gui()
    for _, player in pairs(game.players) do
        create_gui_for_player(player)
    end
end

function GuiManager:refresh_for_player(player)
    player.gui.screen.clear()
    create_gui_for_player(player)
end

function GuiManager:refresh()
    for _, player in pairs(game.players) do
        this():refresh_for_player(player)
    end
end

-- register events

Event.on_init(function()
    Gui.init()
    Gui.build_lookup_tables()
end)

Event.on_configuration_changed(function()
    Gui.init()
    create_gui()
end)

-- 期望 on_load 后能重新生成 UI, 可以通过检查种子号来判断是否需要重启
Event.on_load(function()
    Gui.build_lookup_tables()
end)

Event.on_event(defines.events.on_player_created, function(e)
    create_gui_for_player(game.get_player(e.player_index))
end)

for name, id in pairs(defines.events) do
    if string.sub(name, 1, 6) == 'on_gui' then
        Event.register(id, function(e)
            Gui.dispatch_handlers(e)
        end)
    end
end

-- for debug
Event.on_game_ready(function()
    this().refresh()
end)

GuiManager.gui = Gui
return GuiManager