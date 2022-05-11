local Force = {}

function Force.each_player_forces(func)
    for _, force in pairs(game.forces) do
        if (force.name ~= 'enemy') and (force.name ~= 'neutral') then
            func(force)
        end
    end
end

return Force