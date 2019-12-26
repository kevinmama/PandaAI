local KC = require('klib/container/container')

local EnemySpawner = KC.class('EnemySpawner', function()

end)

function EnemySpawner:spawn_around_target(target)
    local surface = target.surface
    local position = target.position
    local pos = surface.find_non_colliding_position("character", position, 100, 5)
    local entity = surface.create_entity({
        name = "medium-biter",
        position = pos,
        force = "enemy"
    })
    entity.set_command({
        type = defines.command.attack_area,
        destination = pos,
        radius = 200,
        distraction = defines.distraction.by_enemy
    })
end

return EnemySpawner
