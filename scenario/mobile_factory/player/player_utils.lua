local Config = require 'scenario/mobile_factory/config'
local KC = require 'klib/container/container'
local Entity = require 'klib/gmo/entity'

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

function U.freeze_character(character)
    if character and character.valid then
        local position = character.position
        character.walking_state = {walking = false}
        if Entity.safe_teleport(character, Config.CHARACTER_PRESERVING_POSITION, nil,
                Config.CHARACTER_PRESERVING_RADIUS, 1, true) then
            return true, position
        end
    end
    return false
end

function U.unfreeze_character(character, position)
    if character and character.valid then
        if Entity.safe_teleport(character, position, nil , 8, 1, true) then
            return true
        end
    end
    return false
end

return U