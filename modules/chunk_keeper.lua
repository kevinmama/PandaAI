local KC = require 'klib/container/container'
local PriorityQueue = require 'klib/classes/priority_queue'
local IterableLinkedList = require 'klib/classes/iterable_linked_list'
local Position = require 'klib/gmo/position'
local Command = require 'klib/gmo/command'
local ColorList = require 'stdlib/utils/defines/color_list'

local SECOND = 60
local MINUTE = 60 *  SECOND

--- 更新频率
local UPDATE_INTERVAL = 30
--- 块生命周期
local TTL = 30 * MINUTE
-- 调试用
--local TTL = 15 * SECOND
--- 玩家/实体更新块范围
local ENTITY_CHUNK_RADIUS = 4
--- 是否显示块生命周期
local DISPLAY = false
--- 雷达范围
local RADAR_RANGE = 7

--- 长期块，块里有实体就不会被回收
local TAG_LONG_TERM = -1
--- 永久块，永远不被回收
local TAG_PERMANENT = -2
local TAG_DESTROYED = -3

local ChunkKeeper = KC.class('modules.ChunkKeeper', function(self, surface)
    self.surface = surface
    self.ttl = TTL
    self.check_pollution = true
    self.entity_chunk_radius = ENTITY_CHUNK_RADIUS

    -- 块标记，记录块真实的过期时间，是否已经在队列内等
    -- 可以二维转一维存储
    self.chunk_tags = {}
    -- 优先队列，记录将到期的块，用过期时间做键，块索引做值
    self.active_chunk_queue = PriorityQueue:new_local()
    self.active_entities = IterableLinkedList:new_local()
    self.active_player_index = 1
    self:update_active_forces()
    self.display = DISPLAY
end)

--- 活跃的块会被回收
function ChunkKeeper:register_active_chunk(chunk_pos, force_level)
    local chunk_index = Position.to_spiral_index(chunk_pos)
    local tag = self.chunk_tags[chunk_index]
    if tag then
        force_level = force_level or 0
        if force_level <= tag.tick then
            tag.tick = game.tick
            if not tag.in_queue then
                self.active_chunk_queue:push(tag.tick, chunk_index)
                tag.in_queue = true
            end
        end
    else
        tag = { tick = game.tick, in_queue = true }
        self.chunk_tags[chunk_index] = tag
        self.active_chunk_queue:push(tag.tick, chunk_index)
    end
    self:update_display(chunk_pos, tag)
end

--- 长期块不会被回收
function ChunkKeeper:register_long_term_chunk(chunk_pos, force_level)
    local chunk_index = Position.to_spiral_index(chunk_pos)
    local tag = self.chunk_tags[chunk_index]
    if not tag then
        tag = { in_queue = false, tick = TAG_LONG_TERM}
        self.chunk_tags[chunk_index] = tag
    end
    force_level = force_level or TAG_LONG_TERM
    if force_level <= tag.tick then
        tag.tick = TAG_LONG_TERM
    end
    self:update_display(chunk_pos, tag)
end

function ChunkKeeper:register_permanent_chunk(chunk_pos)
    local chunk_index = Position.to_spiral_index(chunk_pos)
    local tag = self.chunk_tags[chunk_index]
    if not tag then
        tag = { in_queue = false}
        self.chunk_tags[chunk_index] = tag
    end
    tag.tick = TAG_PERMANENT
    self:update_display(chunk_pos, tag)
end

--- 活跃的实体会更新周围块的活跃时间
function ChunkKeeper:register_active_entity(entity)
    -- 防重复检查
    for e in self.active_entities:iterator() do
        if e == entity then
            return
        end
    end
    self.active_entities:append(entity)
end

function ChunkKeeper:each_chunk_position_in_radius(chunk_pos, chunk_radius, func)
    for offset_x = -chunk_radius, chunk_radius do
        for offset_y = -chunk_radius, chunk_radius do
            func({x=chunk_pos.x+offset_x, y=chunk_pos.y+offset_y})
        end
    end
end

function ChunkKeeper:register_active_area_in_radius(chunk_pos, chunk_radius)
    self:each_chunk_position_in_radius(chunk_pos, chunk_radius, function(pos)
        self:register_active_chunk(pos)
    end)
end

function ChunkKeeper:register_long_term_area_in_radius(chunk_pos, chunk_radius)
    self:each_chunk_position_in_radius(chunk_pos, chunk_radius, function(pos)
        self:register_long_term_chunk(pos)
    end)
end

function ChunkKeeper:register_long_term_area(area)
    local lt = Position.to_chunk_position(area.left_top)
    local rb = Position.to_chunk_position(area.right_bottom)
    for x = lt.x, rb.x do
        for y = lt.y, rb.y do
            self:register_long_term_chunk({x=x,y=y})
        end
    end
end

function ChunkKeeper:register_permanent_area(area)
    local lt = Position.to_chunk_position(area.left_top)
    local rb = Position.to_chunk_position(area.right_bottom)
    for x = lt.x, rb.x do
        for y = lt.y, rb.y do
            self:register_permanent_chunk({x=x,y=y})
        end
    end
end

--- 更新需要查找的势力
function ChunkKeeper:update_active_forces()
    self.active_force_names = {}
    for name, _ in pairs(game.forces) do
        if name ~= 'enemy' and name ~= 'neutral' then
            table.insert(self.active_force_names, name)
        end
    end
end

--- 检查块是否活跃
function ChunkKeeper:check_long_term_chunk(chunk_pos, ignore_mined_entity)
    if self:is_empty_chunk(chunk_pos, ignore_mined_entity) then
        self:register_active_chunk(chunk_pos, TAG_LONG_TERM)
    end
end

function ChunkKeeper:check_long_term_chunk_in_radius(chunk_pos, radius, ignore_mined_entity_in_center)
    self:each_chunk_position_in_radius(chunk_pos, radius, function(pos)
        self:check_long_term_chunk(pos, ignore_mined_entity_in_center and Position.equals(pos, chunk_pos) or false)
    end)
end

function ChunkKeeper:is_empty_chunk(chunk_pos, ignore_mined_entity)
    local search_area = Position.chunk_position_to_chunk_area(chunk_pos)
    local entities = self.surface.find_entities_filtered({
        area = search_area,
        force = self.active_force_names
    })
    local total = #entities
    for _, e in pairs(entities) do
        if ((e.type == "character") or
                (e.type == "car") or
                (e.type == "spider-vehicle") or
                (e.type == "logistic-robot") or
                (e.type == "construction-robot")) then
            total = total - 1
        end
    end
    -- A destroyed entity is still found during the event check.
    return (ignore_mined_entity and total == 1) or total == 0
end

--- 检查活跃块的生存时间
function ChunkKeeper:update()
    self:update_active_players()
    self:update_active_entities()
    self:update_active_chunks()
end

function ChunkKeeper:update_active_players()
    local players = game.connected_players
    if #players > 0 then
        if self.active_player_index > #players then
            self.active_player_index = 1
        end
        local player = players[self.active_player_index]
        self.active_player_index = self.active_player_index + 1
        if player and player.character and player.character.valid then
            self:register_active_area_in_radius(Position.to_chunk_position(player.position), self.entity_chunk_radius)
        end
    end
end

function ChunkKeeper:update_active_entities()
    if not self.active_entities:is_empty() then
        local entity = self.active_entities:next()
        if not entity then entity = self.active_entities:rewind() end
        if entity.valid then
            --local range = entity.type == 'radar' and RADAR_RANGE or self.entity_chunk_radius
            self:register_active_area_in_radius(Position.to_chunk_position(entity.position), self.entity_chunk_radius)
        else
            self.active_entities:remove()
        end
    end
end

function ChunkKeeper:update_active_chunks()
    local check_next = false
    repeat
        local chunk_index, tick = self.active_chunk_queue:peek()
        --game.print(serpent.line({chunk_index=chunk_index, tick=tick}))
        if chunk_index then
            if game.tick > tick + self.ttl then
                self.active_chunk_queue:pop()
                self:update_active_chunk(chunk_index)
                check_next = true
            else
                check_next = false
            end
        else
            check_next = false
        end
    until not check_next
end

function ChunkKeeper:update_active_chunk(chunk_index)
    local tag = self.chunk_tags[chunk_index]
    --game.print(serpent.line(tag))
    if not tag then return end -- 可能由其它原因已经删除块
    if tag.tick < 0 then
        tag.in_queue = false
    elseif game.tick > tag.tick + self.ttl then
        local chunk_pos = Position.from_spiral_index(chunk_index)
        if self.check_pollution and self.surface.get_pollution(chunk_pos) > 0 then
            tag.tick  = game.tick
            self.active_chunk_queue:push(tag.tick, chunk_index)
            self:update_display(chunk_pos, tag)
        else
            self:delete_chunk(chunk_pos, chunk_index, tag)
        end
    else
        self.active_chunk_queue:push(tag.tick, chunk_index)
    end
end

--- chunk_index 和 tag 都不是必要的
function ChunkKeeper:delete_chunk(chunk_pos, chunk_index, tag)
    if not self.lock_delete_chunk then
        chunk_index = chunk_index or Position.to_spiral_index(chunk_pos)
        tag = tag or self.chunk_tags[chunk_index]
        if tag then
            tag.tick = TAG_DESTROYED
            self.chunk_tags[chunk_index] = nil
            self:update_display(chunk_pos, tag)
        end
        if self.surface.is_chunk_generated(chunk_pos) then
            self.lock_delete_chunk = true
            self.surface.delete_chunk(chunk_pos)
            self.lock_delete_chunk = false
        end
    end
end

function ChunkKeeper:on_chunk_generated(event)
    if self.surface.index == event.surface.index then
        self:register_active_chunk(Position.to_chunk_position(event.area.left_top))
    end
end

function ChunkKeeper:on_chunk_deleted(event)
    if self.surface.index == event.surface_index then
        for _, chunk_pos in pairs(event.positions) do
            self:delete_chunk(chunk_pos)
        end
    end
end

function ChunkKeeper:on_sector_scanned(event)
    local radar = event.radar
    if radar.surface.index == self.surface.index then
        self:register_active_chunk(event.chunk_position)
        self:register_active_area_in_radius(Position.to_chunk_position(radar.position), RADAR_RANGE)
    end
end

function ChunkKeeper:on_built_entity(event)
    local entity = event.created_entity
    if entity.surface.index == self.surface.index then
        if entity.type ~= 'car' and entity.type ~= 'spider-vehicle' then
            self:register_long_term_chunk(Position.to_chunk_position(entity.position))
        else
            self:register_active_entity(entity)
        end
    end
end

function ChunkKeeper:on_mined_entity(event)
    local entity = event.entity
    if entity.surface.index == self.surface.index then
        --if ((event.entity.force ~= nil) and (event.entity.force ~= "neutral") and (event.entity.force ~= "enemy")) then
        self:check_long_term_chunk(Position.to_chunk_position(event.entity.position), true)
        --end
    end
end

function ChunkKeeper:update_display(chunk_pos, tag)
    if tag.text_id then
        rendering.destroy(tag.text_id)
    end
    if self.display and tag.tick ~= TAG_DESTROYED then
        tag.text_id = rendering.draw_text({
            text = string.format('%d %s', tag.tick, tag.in_queue and "(Q)" or ""),
            surface = self.surface,
            target = Position.from_chunk_position(chunk_pos) + {16,16},
            color = ColorList.green
        })
    end
end

ChunkKeeper:on_nth_tick(UPDATE_INTERVAL, function(self)
    self:update()
end)

ChunkKeeper:on(defines.events.on_chunk_generated, function(self, event)
    self:on_chunk_generated(event)
end)

ChunkKeeper:on(defines.events.on_chunk_deleted, function(self, event)
   self:on_chunk_deleted(event)
end)

ChunkKeeper:on(defines.events.on_sector_scanned, function(self, event)
    self:on_sector_scanned(event)
end)

ChunkKeeper:on({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
    defines.events.on_entity_cloned,
}, function(self, event)
    self:on_built_entity(event)
end)

ChunkKeeper:on({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    -- die/destroy ?
    defines.events.script_raised_destroy
}, function(self, event)
    self:on_mined_entity(event)
end)

ChunkKeeper:on({
    defines.events.on_force_created,
    defines.events.on_forces_merged,
}, function(self, event)
    self:update_active_forces(event)
end)

Command.add_admin_command("clean-map", {"chunk_keeper.force_cleanup_help"}, function(data)
    KC.for_each_object(ChunkKeeper, function(self)
        local timeout_ticks = tonumber(data.parameter) or 18000
        if timeout_ticks < 600 then
            game.get_player(data.player_index).print({"chunk_keeper.force_cleanup_timeout_too_fast"})
        else
            game.print({"chunk_keeper.force_cleanup_message", timeout_ticks})
            local ttl = self.ttl
            self.ttl = timeout_ticks
            self:update()
            self.ttl = ttl
        end
    end)
end)

Command.add_admin_command("display-chunk-keeper", {"chunk_keeper.display_help"}, function(data)
    KC.for_each_object(ChunkKeeper, function(self)
        self.display = not self.display
    end)
end)

return ChunkKeeper