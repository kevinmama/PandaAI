function Team:clear_near_enemies()
    -- 新手保护，删除安全范围里的虫子
    local enemies = base.surface.find_entities_filtered({
        force = game.forces['enemy'],
        position = base.vehicle.position,
        radius = Config.SAFE_AREA_RADIUS}
    )
    for _, enemy in pairs(enemies) do
        enemy.destroy()
    end
    game.print({"mobile_factory.remove_spawn_area_enemy"})
end

