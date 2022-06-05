local Config = require 'scenario/mobile_factory/config'
local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
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

function U.set_character_playable(character, enable)
    if character and character.object_name == 'LuaPlayer' then
        character = character.character
    end
    if character and character.valid then
        Entity.set_indestructible(character, not enable)
        Entity.set_frozen(character, not enable)
        character.walking_state = {walking = false}
        return true, character
    end
    return false
end

return U