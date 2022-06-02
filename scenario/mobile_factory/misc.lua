local Time = require 'stdlib/utils/defines/time'
local Event = require 'klib/event/event'
local Force = require 'klib/gmo/force'
local Command = require 'klib/gmo/command'
local LazyTable = require 'klib/utils/lazy_table'

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



----------------------------------------
--- !!! 视野共享 !!!
--- 为了性能考虑，每分钟只共享5秒视野
----------------------------------------

local function update_share_chart(event)
    local share_chart = LazyTable.get(global, "mf_settings", "share_chart")
    if share_chart == nil then
        if event.tick % Time.minute == 0 then
            Force.each_player_forces(function(force)
                force.share_chart = true
            end)
        end
        if event.tick % Time.minute == 5 * Time.second then
            Force.each_player_forces(function(force)
                force.share_chart = false
            end)
        end
    elseif event.tick % Time.minute == 0 then
        Force.each_player_forces(function(force)
            force.share_chart = share_chart
        end)
    end
end

Event.on_nth_tick(5 * Time.second, update_share_chart)

Command.add_admin_command("share-chart", {"mobile_factory.share_chart_help"}, function(data)
    local parameter = data.parameter
    if parameter then
        if parameter == 'true' then
            LazyTable.set(global, "mf_settings", "share_chart", true)
            update_share_chart({tick = 0})
            return
        elseif parameter == 'false' then
            LazyTable.set(global, "mf_settings", "share_chart", false)
            update_share_chart({tick = 0})
            return
        elseif parameter == 'auto' then
            LazyTable.remove(global, "mf_settings", "share_chart")
            update_share_chart({tick = 0})
            return
        end
    end
    game.get_player(data.player_index).print({"mobile_factory.share_chart_help"})
end)
