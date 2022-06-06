local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'

local Config = require 'scenario/mobile_factory/config'
local ChunkKeeper = require 'scenario/mobile_factory/mf_chunk_keeper'
local U = require 'scenario/mobile_factory/player/player_utils'

local TeamCenterRegistry = require 'scenario/mobile_factory/base/team_center_registry'

local PlayerSpectator = KC.class(Config.PACKAGE_PLAYER_PREFIX .. "PlayerSpectator", function(self, mf_player)
    self.mf_player = mf_player
    self.player = mf_player.player
    self.character = self.player.character
end)

function PlayerSpectator:is_spectating()
    return self.player.controller_type == defines.controllers.spectator
end

function PlayerSpectator:spectate_position(position)
    if not self:is_spectating() then
        local status, character = U.set_character_playable(self.player, false)
        if status then
            self.character = character
            if ChunkKeeper then KC.get(ChunkKeeper):register_active_entity(character) end
        end
        self:set_bottom_button_visible(false)
        self.player.set_controller({type = defines.controllers.spectator})
    end
    self.player.teleport(position)
end

function PlayerSpectator:spectate_team(team)
    if not team then
        self.player.print({"mobile_factory.team_not_exists"})
        return
    end
    local base = TeamCenterRegistry.get_first_base_by_team_id(team:get_id())
    if base then
        self:spectate_position(base.center)
    end
end

function PlayerSpectator:exit_spectate()
    if not self:is_spectating() or not self.mf_player.team then return end
    local status = U.set_character_playable(self.character, true)
    if not status then
        self.character = Entity.create_unit(self.player.surface, {
            name = 'character',
            position = self.player.force.get_spawn_position(self.player.surface),
            force = self.player.force
        })
    end
    self.player.set_controller({type = defines.controllers.character, character = self.character})
    self:set_bottom_button_visible(true)
end

function PlayerSpectator:toggle_spectator_mode()
    if self:is_spectating() then
        self:exit_spectate()
    else
        self:spectate_position(self.player.position)
    end
end

function PlayerSpectator:set_bottom_button_visible(visible)
    local button = KC.find_object('klib.fgui.BottomButton', function() return true end)
    if button then
        button:set_button_frame_visible(self.player.index,visible)
    end
end

Event.on_player_clicked_gps_tag(function(event)
    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.spectator then
        player.teleport(event.position, event.surface)
    end
end)


return PlayerSpectator