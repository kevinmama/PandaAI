local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local H = require 'scenario.mobile_factory.player_helper'
local Config = require 'scenario.mobile_factory.config'
local Command = require 'klib/gmo/command'

-- local player index

local Player = KC.class('scenario.MobileFactory.Player', function(self, player)
    self.player = player
    self.team_id = nil
    self.first_init = true
    self.initialized = false
end)

Player:refs("team")

Player.players = {}

function Player.get(index)
    return Player.players[index]
end

function Player:on_load()
    Player.players[self.player.index] = self
end

function Player:get_base()
    local team = self:get_team()
    return team and team:get_base()
end

function Player:init()
    Entity.set_indestructible(self.player.character, true)
    Entity.set_frozen(self.player.character, true)
    self.initialized = false
end

function Player:init_on_create_or_join_team()
    local team = self:get_team()
    if not team then
        return
    end

    Entity.set_indestructible(self.player.character, false)
    Entity.set_frozen(self.player.character, false)
    if self.first_init then
        H.give_player_init_items(self.player)
        self.first_init = false
    end
    self.initialized = true
end

function Player:is_new()
    return self.player.online_time < Config.RESET_TICKS_LIMIT
end

--- 加入 15 分钟前，自己是团员，且团队只有自己时，可以重置
function Player:can_reset()
    if not self:is_new() then
        return false
    end

    local team = self:get_team()
    if team then
        return team.captain ~= self.player.index or #team:get_members() == 1
    else
        return false
    end
end

function Player:do_reset()
    local team_id = self:get_team():get_id()
    self:set_team(nil)
    Event.raise_event(Config.ON_PLAYER_LEFT_TEAM_EVENT, {
        player_index = self.player.index,
        team_id = team_id
    })
    local x,y = self.player.position.x, self.player.position.y
    self.player.character.die()
    self.player.force = "player"
    self.player.ticks_to_respawn = nil
    self:init()
    game.print({"mobile_factory.player_reset", self.player.name, x, y})
end

function Player:reset(force)
    if not self.initialized then
        return
    end

    if force or self:can_reset() then
        local team = self:get_team()
        if team and team.captain == self.player.index then
            team:destroy()
        else
            self:do_reset()
        end
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

Event.register(defines.events.on_pre_player_left_game, function(event)
    local k_player = Player.players[event.player_index]
    if k_player:is_new() then
        k_player:reset()
        game.print({"mobile_factory.reset_quick_quit", k_player.player.name})
    end
end)


Command.add_admin_command("force-reset-player", {"mobile_factory.force_reset_player"}, function(data)
    local player = game.get_player(data.parameter)
    if not player then
        player.print({"mobile_factory.player_not_exist"})
    else
        game.print({"mobile_factory.force_reset_player_message", player.name, data.player_index})
        Player.get(player.index):reset(true)
    end
end)

return Player