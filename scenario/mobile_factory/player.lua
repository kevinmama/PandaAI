local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Config = require 'scenario.mobile_factory.config'
local Command = require 'klib/gmo/command'
local String = require 'stdlib/utils/string'

local H = require 'scenario.mobile_factory.player_helper'
local RegrowthMap = require 'scenario.mobile_factory.regrowth_map_nauvis'

-- local player index

local Player = KC.class('scenario.MobileFactory.Player', function(self, player)
    self.player = player
    self.character = player.character
    self.team_id = nil
    self.never_reset = true
    self.initialized = false
end)

Player:reference_objects("team")

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
    local character = self.player.character
    if character and character.valid then
        Entity.set_indestructible(character, true)
        Entity.set_frozen(character, true)
    end
    self.initialized = false
end

function Player:init_on_create_or_join_team()
    local team = self:get_team()
    if not team then
        return
    end
    local character = self.player.character
    if character and character.valid then
        Entity.set_indestructible(character, false)
        Entity.set_frozen(character, false)
    end
    if self.never_reset then
        H.give_player_init_items(self.player)
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
    self:exit_spectate()
    local team_id = self:get_team():get_id()
    self:set_team(nil)
    Event.raise_event(Config.ON_PLAYER_LEFT_TEAM, {
        player_index = self.player.index,
        team_id = team_id
    })
    local x,y = self.player.position.x, self.player.position.y
    local character = self.player.character
    if character then
        character.die()
    end
    self.player.force = "player"
    self.player.ticks_to_respawn = nil
    self.never_reset = false
    self:init()
    game.print({"mobile_factory.player_reset", self.player.name, x, y})
end

function Player:reset(force, never_reset)
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
        self.never_reset = never_reset and true or false
    end
end

function Player:is_spectating()
    return self.player.controller_type == defines.controllers.spectator
end

function Player:spectate_position(position)
    if not self:is_spectating() then
        local character = self.player.character
        if character and character.valid then
            self.character = character
            character.walking_state = {walking = false}
            KC.get(RegrowthMap):add_vehicle(character)
            Entity.set_indestructible(character, true)
        else
            self.player.print({'mobile_factory.need_character_to_be_a_spectator'})
            return
        end
    end
    self.player.set_controller({type = defines.controllers.spectator})
    self.player.teleport(position)
end

function Player:spectate_team(team_id)
    local team = KC.get(team_id)
    if not team then
        self.player.print({"mobile_factory.team_not_exists"})
        return
    end
    self:spectate_position(team:get_base().center)
    team.force.print({"mobile_factory.player_spectate_team", self.player.name})
end

function Player:exit_spectate()
    if not self:is_spectating() then return end
    if self.character and self.character.valid then
        -- 无队伍的玩家无敌
        if self:get_team() then
            Entity.set_indestructible(self.character, false)
        end
        self.player.set_controller({type = defines.controllers.character, character = self.character})
    else
        game.print("!!! Character not exists when exiting spectator mode, Please Report To kevinma !!! player_name: " .. self.player.name)
    end
end

function Player:toggle_spectator_mode()
    if self:is_spectating() then
        self:exit_spectate()
    else
        self:spectate_position(self.player.position)
    end
end

function Player:recharge_equipment()
    local character = self.player.character
    local grid = character and character.valid and character.grid
    if not grid then return end
    local base = H.find_near_base(self.player)
    if not base then
        self.player.print({"mobile_factory.too_far_from_base_for_recharging"})
        return
    end
    -- 执行充电
    base:recharge_equipment_for_character(character)
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
    local name, never_reset_flag = Table.unpack(String.split(data.parameter, " +", true))
    local player = game.get_player(name)
    if not player then
        local player = game.get_player(data.player_index)
        player.print({"mobile_factory.player_not_exists"})
    else
        game.print({"mobile_factory.force_reset_player_message", player.name, game.get_player(data.player_index).name})
        Player.get(player.index):reset(true, never_reset_flag == "with-item")
    end
end)

return Player