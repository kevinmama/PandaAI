local Config = require 'scenario/mobile_factory/config'
local KC = require 'klib/container/container'
local Entity = require 'klib/gmo/entity'
local Position = require 'klib/gmo/position'

local U = {}

function U.find_near_base(player)
    local entities = player.character.surface.find_entities_filtered({
        name = Config.BASE_VEHICLE_NAME,
        force = player.force,
        position = player.position,
        radius = Config.PLAYER_RECHARGE_DISTANCE
    })
    for _, entity in pairs(entities) do
        local base_id = Entity.get_data(entity, "base_id")
        if base_id then
            return KC.get(base_id)
        end
    end
end

function U.freeze_player(player)
    local character = player.character
    if character and character.valid then
        local position, surface = character.position, character.surface
        character.walking_state = {walking = false}
        local preserved_position = Position.from_spiral_index(player.index*2)
        local preserved_surface = game.surfaces[Config.ALT_SURFACE_NAME]
        player.teleport(preserved_position, preserved_surface)
        player.set_controller({type = defines.controllers.spectator})
        player.teleport(position, surface)
        return character, position
    else
        player.set_controller({type = defines.controllers.spectator})
        return nil
    end
end

function U.unfreeze_player(player, character, position, ticks_to_respawn)
    local surface, force = game.surfaces[Config.GAME_SURFACE_NAME], player.force
    if character and character.valid then
        player.teleport(character.position, character.surface)
        character.force = force
    elseif ticks_to_respawn then
        player.ticks_to_respawn = ticks_to_respawn
    else
        character = Entity.create_unit(surface, {
            name = 'character',
            position = position,
            force = force
        })
        player.teleport(position, surface)
    end

    if not ticks_to_respawn then
        player.set_controller({type = defines.controllers.character, character = character})
        return player.teleport(position, surface)
    else
        return true
    end
end

return U