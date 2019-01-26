require 'stdlib/event/event'
require 'stdlib/utils/table'
require 'klib/klib'

local SolderSpawner = require 'solder_spawner'
local SolderSpawnerGui = require 'solder_spawner_gui'

local SolderSpawnerManager = KContainer.define_class('SolderSpawnerManager', function(self)
    self.spawners = {}
    self.guis = {}
end)

function SolderSpawnerManager:on_player_created(player)
    local spawner = SolderSpawner:new(player)
    self.spawners[player.index] = spawner

    local gui = SolderSpawnerGui:new(spawner)
    self.guis[player.index] = gui
end

Event.register(Event.core_events.init, function()
    KContainer.singleton(SolderSpawnerManager)
end)

Event.register(defines.events.on_player_created, function(event)
    local player = KHelper.get_player_by_event(event)
    KContainer.get(SolderSpawnerManager):on_player_created(player)
end)

Event.register(Event.core_events.load, function()
    log(serpent.block(global))
    KContainer.load(global)
end)

KEvent.on_game_ready(function()
    log("persisting KContainer registry to global")
    KContainer.persist(global)
    log(serpent.block(global))
end)

