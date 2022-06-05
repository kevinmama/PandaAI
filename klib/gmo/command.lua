local Command = {}

function Command.add_admin_command(name, help, func)
    commands.add_command(name, help, function(data)
        if data.player_index then
            local player = game.get_player(data.player_index)
            if not player.admin then
                player.print({"klib.require_admin_permission"})
                return
            end
        end

        func(data)
    end)
end

return Command