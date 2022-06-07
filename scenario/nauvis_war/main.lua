local KC = require 'klib/container/container'
local KPanel = require 'modules/k_panel/k_panel'

require 'scenario/nauvis_war/buy_gui'
require 'scenario/nauvis_war/formation_gui'

local Event = require 'klib/event/event'
local Table = require 'klib/utils/table'
local Entity = require 'klib/gmo/entity'
local Player = require 'klib/gmo/player'

local Group = require 'kai/agent/group'
local Behaviors = require 'kai/behavior/behaviors'
local Commands = require 'kai/command/commands'
local Formations = require 'kai/formation/formations'

local InfantryGroup = require 'scenario/nauvis_war/infantry_group'

--- TODO: 能自定义装备，载具

Event.on_init(function()
    local kp = KC.get(KPanel)
    kp.map_info_main_caption = "异星战场"
    kp.map_info_sub_caption = "打虫子，买士兵"
    kp.map_info_text = "左键点开金币按钮买兵，右键点金币按钮收集金币和发子弹。By Kevinma Q群:780980177"

    game.forces['player'].research_queue_enabled = true
    global.research_point = 0
end)

Event.register(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    Entity.give_unit_armoury(player.character, {
        ["submachine-gun"] = 1,
        ["firearm-magazine"] = 200,
        ["shotgun"] = 1,
        ["shotgun-shell"] = 100,
        ["modular-armor"] = 1,
        ['personal-roboport-equipment'] = 1,
        ['battery-mk2-equipment'] = 1,
        ['energy-shield-equipment'] = 1,
        ['solar-panel-equipment'] = 15,
        ['construction-robot'] = 50
    })
    Entity.give_entity_items(player.character, {
        coin = 1000
    })

    --local group = Group:new({
    --    surface = player.surface,
    --    position = player.position,
    --    force = player.force,
    --    bounding_box = player.character.bounding_box
    --})
    --group:set_leader(player)
    --group:set_command(Commands.Follow, player)
    --group:set_formation(Formations.Spiral)
    --group:set_formation(Formations.SingleLine)
    --group:set_formation(Formations.SingleRow)
    --group:set_formation(Formations.Snake)

    local group = InfantryGroup:new({
        surface = player.surface,
        position = player.position,
        force = player.force,
        bounding_box = player.character.bounding_box
    }, player)

    Player.set_data(player.index, "group_id", group:get_id())

end)

Event.register(defines.events.on_pre_player_died, function(event)
    Player.set_data(event.player_index, "died_position", game.get_player(event.player_index).position)
end)

Event.register(defines.events.on_player_respawned, function(event)
    local player = game.get_player(event.player_index)
    Entity.give_unit_armoury(player.character, {
        ["submachine-gun"] = 1,
        ["firearm-magazine"] = 50
    })
    Entity.give_entity_items(player.character, {
        coin = 200
    })
    local died_position = Player.get_data(event.player_index, "died_position")
    Entity.safe_teleport(player, died_position,player.surface,8, 1)
end)

local REQUIRE_POINT_MAP = {
    ['automation-science-pack'] = 1,
    ['logistic-science-pack'] = 2,
    ['military-science-pack'] = 5,
    ['chemical-science-pack'] = 10,
    ['production-science-pack'] = 20,
    ['utility-science-pack'] = 50,
    ['space-science-pack'] = 100,
}

local function apply_research_point(force)
    local current_research = force.current_research

    if current_research then
        local require_point = Table.reduce(current_research.research_unit_ingredients, function(require_point, ingredient)
            return require_point + REQUIRE_POINT_MAP[ingredient.name] * ingredient.amount
        end, 0)
        local total_point = require_point * current_research.research_unit_count
        local progress = math.floor(global.research_point * 100 / total_point) / 100.0
        if progress > 0 then
            if progress > 1 - force.research_progress then
                progress = 1 - force.research_progress
            end
            global.research_point = global.research_point - progress * total_point
            force.research_progress = force.research_progress + progress
        end
    end
end

local ENEMY_REWARD_MAP = {
    small = {1,1, 2, 2},
    medium = {2,2,4,4},
    big = {4,4,8,8},
    behemoth = {8,8,16,16}
}

Event.register(defines.events.on_entity_died, function(event)
    -- 用 beam 没有 event.cause
    local entity = event.entity
    if entity.force.name == 'enemy' then
        if entity.type == 'unit' then
            local prefix = string.match(entity.name, '(%w+)-')
            local coin, research_point = ENEMY_REWARD_MAP[prefix][1], ENEMY_REWARD_MAP[prefix][2]
            if event.cause then
                Entity.give_entity_items(event.cause, { coin = coin })
            end
            if event.force then
                global.research_point = global.research_point + research_point
                apply_research_point(event.force)
            end
        elseif entity.type == 'turret' then
            local prefix = string.match(entity.name, '(%w+)-')
            local coin, research_point = ENEMY_REWARD_MAP[prefix][3], ENEMY_REWARD_MAP[prefix][4]
            if event.cause then
                Entity.give_entity_items(event.cause, { coin = coin })
            end
            if event.force then
                global.research_point = global.research_point + research_point
                apply_research_point(event.force)
            end
        elseif entity.type == 'unit-spawner' then
            local coin, research_point = 50, 50
            if event.cause then
                Entity.give_entity_items(event.cause, { coin = coin })
            end
            if event.force then
                global.research_point = global.research_point + research_point
                apply_research_point(event.force)
            end
        end
    end
end)

Event.on_nth_tick(60, function()
    Table.each(game.connected_players, function(player)
        Entity.give_entity_items(player.character, {
            coin = 1
        })
    end)
end)

