local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario/mobile_factory/config'

-- local player index

local Player = KC.class('scenario.MobileFactory.Player', function(self, player)
    self.player = player
    self.team_id = nil
end)

Player.players = {}

function Player.get(index)
    return Player.players[index]
end

function Player:on_load()
    Player.players[self.player.index] = self
end

local function give_quick_start_modular_armor(player)
    player.insert{name="modular-armor", count = 1}
    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
        if p_armor ~= nil then
            p_armor.put({name = "personal-roboport-equipment"})
            p_armor.put({name = "battery-mk2-equipment"})
            p_armor.put({name = "personal-roboport-equipment"})
            for _ =1,15 do
                p_armor.put({name = "solar-panel-equipment"})
            end
        end
        player.insert{name="construction-robot", count = 50}
    end
end

local function give_player_init_items(player)
    for name,count in pairs(Config.PLAYER_INIT_ITEMS) do
        player.insert({name=name, count=count})
    end
    give_quick_start_modular_armor(player)
end

function Player:init()
    Entity.set_indestructible(self.player.character, true)
    Entity.set_frozen(self.player.character, true)
end

function Player:init_on_create_or_join_team()
    Entity.set_indestructible(self.player.character, false)
    Entity.set_frozen(self.player.character, false)
    give_player_init_items(self.player)
    local team = KC.get(self.team_id)
    local MobileBaseManager = KC.get_class('scenario.MobileFactory.MobileBaseManager')
    local mgr = KC.get(MobileBaseManager)
    if self.player.index == team.captain then
        mgr:init(team)
    else
        local base = mgr:get_by_player(self.player.index)
        Entity.safe_teleport(self.player, self.player.surface, base.vehicle.position, 4, 1)
    end
end


Event.register(defines.events.on_player_created, function(event)
    local k_player = Player:new(game.get_player(event.player_index))
    Player.players[event.player_index] = k_player
    k_player:init()
end)

Event.register(defines.events.on_player_removed, function(event)
    Player.players[event.player_index]:destroy()
    Player.players[event.player_index] = nil
end)

Event.register(defines.events.on_player_changed_force, function(event)
    Player.get(event.player_index):init_on_create_or_join_team()
end)

return Player