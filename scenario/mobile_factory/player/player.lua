local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Command = require 'klib/gmo/command'
local KPlayer = require 'klib/gmo/player'
local String = require 'stdlib/utils/string'

local Config = require 'scenario/mobile_factory/config'
local U = require 'scenario/mobile_factory/player/player_utils'
local PlayerRegistry = require 'scenario/mobile_factory/player/player_registry'
local PlayerSpectator = require 'scenario/mobile_factory/player/player_spectator'

local Player = KC.class(Config.PACKAGE_PLAYER_PREFIX .. 'Player', function(self, player)
    self.player = player
    self.team_id = nil
    self.never_reset = true
    self.initialized = false
    self.team = nil
    self.player.character.destroy()
    self.spectator = PlayerSpectator:new_local(self)
    self.spectator:spectate_position(self.player.position)
    self.visiting_base = nil
end)

Player:delegate_method("spectator", {"is_spectating", "spectate_position", "spectate_team", "exit_spectate", "toggle_spectator_mode"})

function Player.get(index)
    return PlayerRegistry[index]
end

function Player:on_ready()
    PlayerRegistry[self.player.index] = self
end

function Player:init_on_create_or_join_team()
    if self.team then
        local _, character = U.set_character_playable(self.player, true)
        if self.never_reset then
            Entity.give_unit_armoury(character, Table.dictionary_combine(
                    Config.PLAYER_INIT_ITEMS,
                    Config.Player_INIT_GRID_ITEMS
            ))
        end
        self.initialized = true
    end
end

function Player:is_new()
    return self.player.online_time < Config.RESET_TICKS_LIMIT
end

--- 加入 15 分钟前，自己是团员，且团队只有自己时，可以重置
function Player:can_reset()
    if not self:is_new() then
        return false
    end

    if self.team then
        return self.team.captain ~= self.player or #self.team:get_members() == 1
    else
        return false
    end
end

function Player:do_reset()
    self.spectator:exit_spectate()
    local team_id = self.team:get_id()
    self.team = nil
    local x,y = self.player.position.x, self.player.position.y
    local character = self.player.character
    if character then
        character.die()
    end
    self.player.force = "player"
    self.never_reset = false
    self.initialized = false
    self.spectator:spectate_position(self.player.position)
    self.player.ticks_to_respawn = nil
    game.print({"mobile_factory.player_reset", self.player.name, x, y})

    Event.raise_event(Config.ON_PLAYER_LEFT_TEAM, {
        player_index = self.player.index,
        team_id = team_id
    })
end

function Player:reset(force, never_reset)
    if not self.initialized then return end

    if force or self:can_reset() then
        if self.team and self.team.captain == self.player then
            self.team:destroy()
        else
            self:do_reset()
        end
        self.never_reset = never_reset and true or false
    end
end

function Player:recharge_equipment()
    local character = self.player.character
    local grid = character and character.valid and character.grid
    if not grid then return end
    local base = U.find_near_base(self.player)
    if not base then
        self.player.print({"mobile_factory.too_far_from_base_for_recharging"})
        return
    end
    -- 执行充电
    base:recharge_equipment_for_character(character)
end

function Player:set_visiting_base(base)
    if base ~= self.visiting_base then
        local left_base = self.visiting_base
        self.visiting_base = base
        if left_base then
            Event.raise_event(Config.ON_PLAYER_LEFT_BASE, {
                player_index = self.player.index,
                base_id = left_base:get_id()
            })
        end
        if self.visiting_base then
            Event.raise_event(Config.ON_PLAYER_ENTER_BASE, {
                player_index = self.player.index,
                base_id = self.visiting_base:get_id()
            })
        end
    end
end

function Player:set_selection_state(mode, tag)
    self.selection_mode = mode
    self.selection_tag = tag
end

function Player:get_selection_state()
    return self.selection_mode, self.selection_tag
end

KPlayer.register_auto_destroy_selection_tool_event()

Event.register(defines.events.on_player_created, function(event)
    Player:new(game.get_player(event.player_index))
end)

--Event.register(defines.events.on_player_removed, function(event)
--    Player.players[event.player_index]:destroy()
--    Player.players[event.player_index] = nil
--end)

Event.register(defines.events.on_pre_player_left_game, function(event)
    local mf_player = Player.get(event.player_index)
    mf_player:exit_spectate()
    if mf_player:is_new() then
        game.print({"mobile_factory.reset_quick_quit", mf_player.player.name})
        mf_player:reset()
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