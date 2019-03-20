local KC = require 'klib/container/container'
local ScriptHelper = require 'klib/helper/script_helper'

local LEVEL_STEP = 2000
local function init_level(...)
    local args = {...}
    return {
        character_running_speed_modifier = args[1],
        character_mining_speed_modifier = args[2],
        character_reach_distance_bonus = args[3],
        character_resource_reach_distance_bonus = args[4],
        character_build_distance_bonus = args[5]
    }
end

local Levels = {}
Levels[1] = init_level(0,0,0,0,0)
Levels[2] = init_level(1,1,10,10,10)
Levels[3] = init_level(2,2,20,20,10)
Levels[4] = init_level(3,3,30,30,30)
Levels[5] = init_level(4,4,40,40,40)
Levels[6] = init_level(5,5,50,50,50)

local PlayerModifierInPollution = KC.singleton('addon.PlayerModifierInPollution', function(self)
    self.indexes = {}
end)

function PlayerModifierInPollution:get_level_index(pollution)
    local index = 1 + math.floor(pollution / LEVEL_STEP)
    if index > #Levels then
        index = #Levels
    end
    return index
end

function PlayerModifierInPollution:apply_level(player, level_index)
    local player_index = player.index
    if self.indexes[player_index] ~= level_index then
        local level = Levels[level_index]
        self:_apply_level(player, level)
        self.indexes[player_index] = level_index
    end
end

function PlayerModifierInPollution:_apply_level(player, level)
    player.character.character_running_speed_modifier = level.character_running_speed_modifier
    player.character.character_mining_speed_modifier = level.character_mining_speed_modifier
    player.character.character_reach_distance_bonus = level.character_resource_reach_distance_bonus
    player.character.character_resource_reach_distance_bonus = level.character_resource_reach_distance_bonus
    player.character.character_build_distance_bonus = level.character_build_distance_bonus
end

PlayerModifierInPollution:on(defines.events.on_tick, function(event, self)
    ScriptHelper.each_alive_player(function(player)
        local pollution = player.surface.get_pollution(player.position)
        local level_index
        if player.character.in_combat then
            level_index = 1
        else
            level_index = self:get_level_index(pollution)
        end
        self:apply_level(player, level_index)
    end)
end)

return PlayerModifierInPollution
