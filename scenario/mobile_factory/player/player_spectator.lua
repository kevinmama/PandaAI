local KC = require 'klib/container/container'
local Event = require 'klib/event/event'
local Entity = require 'klib/gmo/entity'
local Chunk = require 'klib/gmo/chunk'
local Area = require 'klib/gmo/area'
local Surface = require 'klib/gmo/surface'

local Config = require 'scenario/mobile_factory/config'
local U = require 'scenario/mobile_factory/player/player_utils'
local ChunkKeeper = require 'scenario/mobile_factory/mf_chunk_keeper'

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
        local character = self.player.character
        self.player.set_controller({type = defines.controllers.spectator})
        local success, position = U.freeze_character(character)
        if success then
            self.character_position = position
        end
        self:set_bottom_button_visible(false)
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
    local force = self.player.force
    local unfrozen = U.unfreeze_character(self.character, self.character_position or force.get_spawn_position(self.player.surface))
    if not unfrozen then
        self.character = Entity.create_unit(self.player.surface, {
            name = 'character',
            position = force.get_spawn_position(self.player.surface),
            force = force
        })
    end
    self.character_position = nil
    self.character.force = self.player.force
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


Event.on_init(function()
    local surface = game.surfaces[Config.GAME_SURFACE_NAME]
    log(Config.CHARACTER_PRESERVING_POSITION)
    local area = Config.CHARACTER_PRESERVING_AREA
    Chunk.request_to_generate_chunks(surface, area)
    surface.force_generate_chunk_requests()
    Surface.clear_entities_in_area(surface, Config.CHARACTER_PRESERVING_AREA)
    Surface.set_tiles(surface, "concrete", Config.CHARACTER_PRESERVING_AREA)
    if ChunkKeeper then KC.singleton(ChunkKeeper):register_permanent_area(Area.expand(area, 16)) end
end)

return PlayerSpectator