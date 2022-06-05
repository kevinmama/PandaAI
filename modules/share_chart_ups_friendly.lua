local Time = require 'stdlib/utils/defines/time'
local Event = require 'klib/event/event'
local Force = require 'klib/gmo/force'
local Command = require 'klib/gmo/command'
local LazyTable = require 'klib/utils/lazy_table'

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
