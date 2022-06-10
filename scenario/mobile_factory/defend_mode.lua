local Table = require 'klib/utils/table'
local Event = require 'klib/event/event'
local Tasks = require 'klib/task/tasks'

local Config = require 'scenario/mobile_factory/config'
local TeamRegistry = require('scenario/mobile_factory/player/team_registry')
local Player = require 'scenario/mobile_factory/player/player'
local Team = require 'scenario/mobile_factory/player/team'
local TeamCenterRegistry = require ('scenario/mobile_factory/base/team_center_registry')

local WATER_TILES = { "water", "deepwater", "water-green", "deepwater-green", "water-shallow", "water-mud", "water-wube"}
--------------------------------------------------------------------------------
--- 无水
--------------------------------------------------------------------------------
Event.on_chunk_generated(function(event)
    if event.surface == game.surfaces[Config.GAME_SURFACE_NAME] then
        local tiles = event.surface.find_tiles_filtered({ name = WATER_TILES, area = event.area })
        local tiles_to_set = Table.map(tiles, function(tile)
            return {name = 'landfill', position = tile.position}
        end)
        event.surface.set_tiles(tiles_to_set)
    end
end)

--------------------------------------------------------------------------------
--- 用户强制加入主团队
--------------------------------------------------------------------------------

Event.on_player_created(function(event)
    local main_team = TeamRegistry.get_main_team()
    if main_team then
        game.get_player(event.player_index).print({"mobile_factory.welcome_to_mobile_base_defend_mode"})
        main_team:request_join(event.player_index)
    end
end)

Event.on_player_joined_game(function(event)
    local main_team = TeamRegistry.get_main_team()
    if main_team then
        main_team:request_join(event.player_index)
    end
end)

--------------------------------------------------------------------------------
--- 失败重置
--------------------------------------------------------------------------------

local EndingTask = Tasks.register_scheduled_task(
        Config.PACKAGE_BASE_PREFIX .. 'DefendModeEndingTask',
        3600, function(self)
            Team:reset_main_team()
            game.forces['enemy'].evolution_factor = 0
            local surface = game.surfaces[Config.GAME_SURFACE_NAME]
            local map_gen_settings = surface.map_gen_settings
            map_gen_settings.seed = math.random(2147483648)
            surface.map_gen_settings = map_gen_settings
            surface.clear()
            surface.regenerate_entity()
            surface.regenerate_decorative()
        end)

Event.register(Config.ON_BASE_VEHICLE_DIED, function(event)
    -- 如果所有蜘蛛进入重伤状态，将会重置
    local bases = TeamCenterRegistry.get_bases_by_team_id(Team.get_main_team():get_id())
    local ending = not Table.find(bases, function(base)
        return not base:is_heavy_damaged()
    end)
    if ending then
        game.print({"mobile_factory.defend_mode_bad_ending"})
        EndingTask:new()
    end
end)
