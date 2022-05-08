-- 当玩家进入游戏时，给予玩家初始物品

local Event = require 'klib/event/event'
require 'modules/k_panel/k_panel'

require 'scenario/mobile_factory/mobile_base_manager'
require 'scenario/mobile_factory/team_gui'

Event.on_init(function()
    if remote.interfaces['freeplay'] then
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_created_items", {})
    end
end)

-- For each other player force, share a chat msg.
local function share_chat_between_forces(player, msg)
    for _, force in pairs(game.forces) do
        if (force ~= nil) then
            if ((force.name ~= 'enemy') and (force.name ~= 'neutral') and
                    (force.name ~= player) and (force ~= player.force)) then
                force.print(player.name .. ": " .. msg, player.chat_color)
            end
        end
    end
end

-- Simple way to write to a file. Always appends. Only server.
-- Has a global setting for enable/disable
local function server_write_file(filename, msg)
    --if (global.ocfg.enable_server_write_files) then
        game.write_file(filename, msg, true, 0)
    --end
end

----------------------------------------
-- Shared chat, so you don't have to type /s
-- But you do lose your player colors across forces.
----------------------------------------
Event.register(defines.events.on_console_chat, function(event)
    if (event.player_index) then
        server_write_file("mobile_factory_server_chat", game.players[event.player_index].name ..
                ": " .. event.message .. "\n")
    end
    --if (global.ocfg.enable_shared_chat) then
        if (event.player_index ~= nil) then
            share_chat_between_forces(game.players[event.player_index],
                    event.message)
        end
    --end
end)

-- Map loaders to logistics tech for unlocks.
local loaders_technology_map = {
    ['logistics'] = 'loader',
    ['logistics-2'] = 'fast-loader',
    ['logistics-3'] = 'express-loader'
}

local function enable_loaders(event)
    local research = event.research
    local recipe = loaders_technology_map[research.name]
    if recipe then research.force.recipes[recipe].enabled = true end
end

----------------------------------------
-- On Research Finished
-- This is where you can permanently remove researched techs
----------------------------------------
Event.register(defines.events.on_research_finished, function(event)
    enable_loaders(event)
end)
