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

function U.freeze_character(player, character)
    if character and character.valid then
        local position = character.position
        character.walking_state = {walking = false}
        local cloned = character.clone({
            surface = game.surfaces[Config.ALT_SURFACE_NAME],
            position = Position.from_spiral_index(player.index*2),
            force = player.force
        })
        character.destroy()
        return cloned, position
    end
    return false
end

function U.unfreeze_character(player, character, position)
    if character and character.valid then
        local cloned = character.clone({
            surface = game.surfaces[Config.GAME_SURFACE_NAME],
            position = position,
            force = player.force
        })
        character.destroy()
        return cloned
    end
    return false
end

return U