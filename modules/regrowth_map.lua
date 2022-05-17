--- original code: https://github.com/Oarcinae/FactorioScenarioMultiplayerSpawn/commits/master

--- modify by kevinma
--- TODO: 添加命令立即回收地块，立即令所有地块超时

local KC = require('klib/container/container')
local table = require('klib/utils/table')
local Command = require 'klib/gmo/command'
--local dlog = require('klib/utils/dlog')

local CHUNK_SIZE = 32
local TICKS_PER_SECOND = 60
local TICKS_PER_MINUTE = TICKS_PER_SECOND * 60
local TICKS_PER_HOUR = TICKS_PER_MINUTE * 60

-- Code tracks all chunks generated and allows for deleting inactive chunks
-- Relies on some changes to RSO to provide random resource locations the next
-- time the land is regenerated. -- (THIS IS CURRENTLY NOT WORKING IN 0.16,
-- resources always how up in the same spot!)
--
-- Basic rules of regrowth:
-- 1. Area around player is safe for quite a large distance.
-- 2. Rocket silo won't be deleted. - PERMANENT
-- 3. Chunks with pollution won't be deleted.
-- 4. Chunks with railways won't be deleted.
-- 5. Anything within radar range won't be deleted, but radar MUST be active.
--      -- This works by refreshing all chunk timers within radar range using
--      the on_sector_scanned event.
-- 6. Chunks timeout after 1 hour-ish, configurable
-- 7. For now, oarc spawns are deletion safe as well, but only immediate area.

-- Generic Utility Includes


 --Default timeout of generated chunks
--local REGROWTH_TIMEOUT_TICKS = TICKS_PER_HOUR
local REGROWTH_TIMEOUT_TICKS = TICKS_PER_MINUTE * 30
--local REGROWTH_TIMEOUT_TICKS = 15 * TICKS_PER_SECOND-- for debug

-- We can't delete chunks regularly without causing lag.
-- So we should save them up to delete them.
local REGROWTH_CLEANING_INTERVAL_TICKS = REGROWTH_TIMEOUT_TICKS

-- Not used right now.
-- It takes a radar 7 hours and 20 minutes to scan it's whole area completely
-- So I will bump the refresh time of blocks up by 8 hours
-- RADAR_COMPLETE_SCAN_TICKS = TICKS_PER_HOUR*8
-- Additional bonus time for certain things:
-- REFRESH_BONUS_RADAR = RADAR_COMPLETE_SCAN_TICKS

--local GAME_SURFACE_NAME = "nauvis"

-- 实际上可以处理更多的层
local RegrowthMap = KC.class('modules.RegrowthMap', function(self, surface_name)
    --self.surface_name = "nauvis"
    self.surface_name = surface_name
    self.vehicles = {}
    self.check_pollution = true
    self.chunk_regrow = {}
    self.chunk_regrow.map = {}
    self.chunk_regrow.removal_list = {}
    self.chunk_regrow.rso_region_roll_counter = 0
    self.chunk_regrow.player_refresh_index = 1
    self.chunk_regrow.vehicle_refresh_index = 1
    self.chunk_regrow.min_x = 0
    self.chunk_regrow.max_x = 0
    self.chunk_regrow.x_index = 0
    self.chunk_regrow.min_y = 0
    self.chunk_regrow.max_y = 0
    self.chunk_regrow.y_index = 0
    self.chunk_regrow.force_removal_flag = -1000

    --self:OarcRegrowthOffLimits({ x = 0, y = 0 }, 10)
end)

function RegrowthMap:get_chunk_coords_from_pos(pos)
    return { x = math.floor(pos.x / CHUNK_SIZE), y = math.floor(pos.y / CHUNK_SIZE) }
end

-- Broadcast messages to all connected players
function RegrowthMap:send_broadcast_msg(msg)
    for name,player in pairs(game.connected_players) do
        player.print({msg})
    end
end


-- Marks a chunk a position that won't ever be deleted.
function RegrowthMap:regrowth_off_limits_chunk(pos)
    local c_pos = self:get_chunk_coords_from_pos(pos)
    if (self.chunk_regrow.map[c_pos.x] == nil) then
        self.chunk_regrow.map[c_pos.x] = {}
    end
    self.chunk_regrow.map[c_pos.x][c_pos.y] = -1
end

-- Marks a safe area around a position that won't ever be deleted.
function RegrowthMap:regrowth_off_limits(pos, chunk_radius)
    local c_pos = self:get_chunk_coords_from_pos(pos)
    for i = -chunk_radius, chunk_radius do
        for k = -chunk_radius, chunk_radius do
            local x = c_pos.x + i
            local y = c_pos.y + k

            if (self.chunk_regrow.map[x] == nil) then
                self.chunk_regrow.map[x] = {}
            end
            self.chunk_regrow.map[x][y] = -1
        end
    end
end

-- Marks a safe area around a position that won't ever be deleted.
function RegrowthMap:regrowth_off_limits_of_center(center, size)
    for offset_x = -size.width/2, size.width/2, CHUNK_SIZE do
        for offset_y = -size.height/2, size.height/2, CHUNK_SIZE do
            self:regrowth_off_limits_chunk({x=center.x+offset_x, y=center.y+offset_y})
        end
    end
end

-- Adds new chunks to the global table to track them.
-- This should always be called first in the chunk generate sequence
-- (Compared to other RSO & Oarc related functions...)
function RegrowthMap:regrowth_chunk_generate(pos)

    local c_pos = self:get_chunk_coords_from_pos(pos)

    -- If this is the first chunk in that row:
    if (self.chunk_regrow.map[c_pos.x] == nil) then
        self.chunk_regrow.map[c_pos.x] = {}
    end

    -- Confirm the chunk doesn't already have a value set:
    if (self.chunk_regrow.map[c_pos.x][c_pos.y] == nil) then
        self.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick
    end

    -- Store min/max values for x/y dimensions:
    if (c_pos.x < self.chunk_regrow.min_x) then
        self.chunk_regrow.min_x = c_pos.x
    end
    if (c_pos.x > self.chunk_regrow.max_x) then
        self.chunk_regrow.max_x = c_pos.x
    end
    if (c_pos.y < self.chunk_regrow.min_y) then
        self.chunk_regrow.min_y = c_pos.y
    end
    if (c_pos.y > self.chunk_regrow.max_y) then
        self.chunk_regrow.max_y = c_pos.y
    end
end

-- This is the main work function, it checks a single chunk in the list
-- per tick. It works according to the rules listed in the header of this
-- file.
function RegrowthMap:regrowth_on_tick(force_timeout_ticks)
    -- Every half a second, refresh all chunks near a single player
    -- Cyles through all players. Tick is offset by 2
    if ((game.tick % (30)) == 2) then
        self:regrowth_refresh_player_area()
        self:regrowth_refresh_vehicle_area()
    end

    -- Every tick, check a few points in the 2d array
    -- According to /measured-command this shouldn't take more
    -- than 0.1ms on average
    for _ = 1, force_timeout_ticks and 20000 or 20 do
        self:regrowth_check_array(force_timeout_ticks)
    end

    -- Send a broadcast warning before it happens.
    if ((game.tick % REGROWTH_CLEANING_INTERVAL_TICKS) == REGROWTH_CLEANING_INTERVAL_TICKS - 601) then
        if (#self.chunk_regrow.removal_list > 100) then
            self:send_broadcast_msg("regrowth_map.prepare_cleanup")
        end
    end

    ---- Delete all listed chunks
    if (force_timeout_ticks or (game.tick % REGROWTH_CLEANING_INTERVAL_TICKS) == REGROWTH_CLEANING_INTERVAL_TICKS - 1) then
        if (force_timeout_ticks or (#self.chunk_regrow.removal_list > 100)) then
            self:regrowth_remove_all_chunks()
            self:send_broadcast_msg("regrowth_map.cleanup")
        end
    end
end


-- Refresh all chunks near a single player. Cycles through all connected players.
function RegrowthMap:regrowth_refresh_player_area()
    self.chunk_regrow.player_refresh_index = self.chunk_regrow.player_refresh_index + 1
    if (self.chunk_regrow.player_refresh_index > #game.connected_players) then
        self.chunk_regrow.player_refresh_index = 1
    end
    if (game.connected_players[self.chunk_regrow.player_refresh_index]) then
        self:regrowth_refresh_area(game.connected_players[self.chunk_regrow.player_refresh_index].position, 4, 0)
    end
end

-- 实际上可以当成 entity 用
function RegrowthMap:add_vehicle(vehicle)
    if vehicle then
        local found = table.find(self.vehicles, function(v)
            return v.unit_number == vehicle.unit_number
        end)
        --game.print("found=" .. (found and "true" or "false") .. " count " ..#self.vehicles)
        if not found then
            table.insert(self.vehicles, vehicle)
        end
    end
end

function RegrowthMap:regrowth_refresh_vehicle_area()
    self.chunk_regrow.vehicle_refresh_index = self.chunk_regrow.vehicle_refresh_index + 1
    if (self.chunk_regrow.vehicle_refresh_index > #self.vehicles) then
        self.chunk_regrow.vehicle_refresh_index = 1
    end

    local vehicle = self.vehicles[self.chunk_regrow.vehicle_refresh_index]
    if vehicle then
        if vehicle.valid then
            self:regrowth_refresh_area(vehicle.position, 4, 0)
        else
            table.remove(self.vehicles, self.chunk_regrow.vehicle_refresh_index)
        end
    end
end

-- Refreshes timers on all chunks around a certain area
function RegrowthMap:regrowth_refresh_area(pos, chunk_radius, bonus_time)
    local c_pos = self:get_chunk_coords_from_pos(pos)

    for i = -chunk_radius, chunk_radius do
        for k = -chunk_radius, chunk_radius do
            local x = c_pos.x + i
            local y = c_pos.y + k

            if (self.chunk_regrow.map[x] == nil) then
                self.chunk_regrow.map[x] = {}
            end
            if (self.chunk_regrow.map[x][y] ~= -1) then
                self.chunk_regrow.map[x][y] = game.tick + bonus_time
            end
        end
    end
end

-- Check each chunk in the 2d array for a timeout value
function RegrowthMap:regrowth_check_array(timeout_ticks)

    -- Increment X
    if (self.chunk_regrow.x_index > self.chunk_regrow.max_x) then
        self.chunk_regrow.x_index = self.chunk_regrow.min_x

        -- Increment Y
        if (self.chunk_regrow.y_index > self.chunk_regrow.max_y) then
            self.chunk_regrow.y_index = self.chunk_regrow.min_y
            --dlog("Finished checking regrowth array." .. self.chunk_regrow.min_x .. " " .. self.chunk_regrow.max_x .. " " .. self.chunk_regrow.min_y .. " " .. self.chunk_regrow.max_y)
        else
            self.chunk_regrow.y_index = self.chunk_regrow.y_index + 1
        end
    else
        self.chunk_regrow.x_index = self.chunk_regrow.x_index + 1
    end

    -- Check row exists, otherwise make one.
    if (self.chunk_regrow.map[self.chunk_regrow.x_index] == nil) then
        self.chunk_regrow.map[self.chunk_regrow.x_index] = {}
    end

    -- If the chunk has timed out, add it to the removal list
    local c_timer = self.chunk_regrow.map[self.chunk_regrow.x_index][self.chunk_regrow.y_index]
    if ((c_timer ~= nil) and (c_timer ~= -1) and ((c_timer + (timeout_ticks or REGROWTH_TIMEOUT_TICKS)) < game.tick)) then

        -- Check chunk actually exists
        local surface = game.surfaces[self.surface_name]
        if (surface.is_chunk_generated({ x = (self.chunk_regrow.x_index),
                                                                  y = (self.chunk_regrow.y_index) })) then
            table.insert(self.chunk_regrow.removal_list, { x = self.chunk_regrow.x_index,
                                                             y = self.chunk_regrow.y_index })
            self.chunk_regrow.map[self.chunk_regrow.x_index][self.chunk_regrow.y_index] = nil
        end
    end
end

local function is_player_vehicle_exists(chunk_pos, surface)
    --local find_forces = table.filter(game.forces, function(force)
    --     return force ~= 'enemy' and force ~= 'neutral'
    --end)

    local entities = surface.find_entities_filtered({
        type = {"car", "spider-vehicle"},
        area = {
            left_top = {x = chunk_pos.x * CHUNK_SIZE - 8, y = chunk_pos.y * CHUNK_SIZE - 8},
            right_bottom = { x = chunk_pos.x * CHUNK_SIZE + CHUNK_SIZE + 8, y = chunk_pos.y * CHUNK_SIZE + CHUNK_SIZE + 8}
        }
    })
    local total = #entities
    for _, entity in ipairs(entities) do
        if entity.force == "enemy" or entity.force == "neutral" then
            total = total - 1
        end
    end
    return total > 0
end

-- Remove all chunks at same time to reduce impact to FPS/UPS
function RegrowthMap:regrowth_remove_all_chunks()
    while (#self.chunk_regrow.removal_list > 0) do
        local c_pos = table.remove(self.chunk_regrow.removal_list)
        local c_timer = self.chunk_regrow.map[c_pos.x][c_pos.y]

        -- Confirm chunk is still expired
        if (c_timer == nil) then

            -- Check for pollution
            local surface = game.surfaces[self.surface_name]
            if (self.check_pollution and surface.get_pollution({ c_pos.x * CHUNK_SIZE, c_pos.y * CHUNK_SIZE }) > 0) then
                self.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick
            -- Check vehicle
            --elseif is_player_vehicle_exists(c_pos, surface) then
            --    --game.print("发现玩家的载具" .. serpent.line(c_pos))
            --    self:regrowth_refresh_area({x=c_pos.x*CHUNK_SIZE,y=c_pos.y*CHUNK_SIZE}, 4, 0)
            --    -- Else delete the chunk
            else
                surface.delete_chunk(c_pos)
                self.chunk_regrow.map[c_pos.x][c_pos.y] = nil
            end
        else
            -- DebugPrint("Chunk no longer expired?")
        end
    end
end

-- Refreshes timers on all chunks near an ACTIVE radar
function RegrowthMap:regrowth_sector_scan(event)
    self:regrowth_refresh_area(event.radar.position, 14, 0)
    self:regrowth_refresh_chunk(event.chunk_position, 0)
end

-- Refreshes timers on a chunk containing position
function RegrowthMap:regrowth_refresh_chunk(pos, bonus_time)
    local c_pos = self:get_chunk_coords_from_pos(pos)

    if (self.chunk_regrow.map[c_pos.x] == nil) then
        self.chunk_regrow.map[c_pos.x] = {}
    end
    if (self.chunk_regrow.map[c_pos.x][c_pos.y] ~= -1) then
        self.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick + bonus_time
    end
end

-- self.surface.find_entities_filtered{area = {game.player.position, {game.player.position.x+32, game.player.position-`32}}, type= "resource"}

-- If an entity is mined or destroyed, then check if the chunk
-- is empty. If it's empty, reset the refresh timer.
function RegrowthMap:regrowth_check_chunk_empty(event)
    if ((event.entity.force ~= nil) and (event.entity.force ~= "neutral") and (event.entity.force ~= "enemy")) then
        if self:check_chunk_empty(event.entity.position) then
            -- dlog("Resetting chunk timer." .. event.entity.position.x .. " " .. event.entity.position.y)
            self:regrowth_force_refresh_chunk(event.entity.position, 0)
        end
    end
end

-- This complicated function checks that if a chunk
function RegrowthMap:check_chunk_empty(pos)
    local chunkPos = self:get_chunk_coords_from_pos(pos)
    local search_top_left = { x = chunkPos.x * CHUNK_SIZE, y = chunkPos.y * CHUNK_SIZE }
    local search_area = { search_top_left, { x = search_top_left.x + CHUNK_SIZE, y = search_top_left.y + CHUNK_SIZE } }
    local total = 0
    local surface = game.surfaces[self.surface_name]
    for f, _ in pairs(game.forces) do
        if f ~= "neutral" and f ~= "enemy" then
            local entities = surface.find_entities_filtered({ area = search_area, force = f })
            total = total + #entities
            if (#entities > 0) then
                for _, e in pairs(entities) do
                    if ((e.type == "player") or
                            (e.type == "car") or
                            (e.type == "spider-vehicle") or
                            (e.type == "logistic-robot") or
                            (e.type == "construction-robot")) then
                        total = total - 1
                    end
                end
            end
        end
    end

    -- A destroyed entity is still found during the event check.
    return (total == 1)
end


-- Forcefully refreshes timers on a chunk containing position
-- Will overwrite -1 flag.
function RegrowthMap:regrowth_force_refresh_chunk(pos, bonus_time)
    local c_pos = self:get_chunk_coords_from_pos(pos)

    if (self.chunk_regrow.map[c_pos.x] == nil) then
        self.chunk_regrow.map[c_pos.x] = {}
    end
    self.chunk_regrow.map[c_pos.x][c_pos.y] = game.tick + bonus_time
end

function RegrowthMap:regrowth_force_refresh_center(center, size, bonus_time)
    for offset_x = -size.width/2, size.width/2, CHUNK_SIZE do
        for offset_y = -size.height/2, size.height/2, CHUNK_SIZE do
            self:regrowth_force_refresh_chunk({x=center.x+offset_x, y=center.y+offset_y}, size, bonus_time)
        end
    end
end

-- Refreshes timers on all chunks around a certain area
function RegrowthMap:regrowth_refresh_area(pos, chunk_radius, bonus_time)
    local c_pos = self:get_chunk_coords_from_pos(pos)

    for i = -chunk_radius, chunk_radius do
        for k = -chunk_radius, chunk_radius do
            local x = c_pos.x + i
            local y = c_pos.y + k

            if (self.chunk_regrow.map[x] == nil) then
                self.chunk_regrow.map[x] = {}
            end
            if (self.chunk_regrow.map[x][y] ~= -1) then
                self.chunk_regrow.map[x][y] = game.tick + bonus_time
            end
        end
    end
end

function RegrowthMap:regrowth_refresh_center(center, size, bonus_time)
    for offset_x = -size.width/2, size.width/2, CHUNK_SIZE do
        for offset_y = -size.height/2, size.height/2, CHUNK_SIZE do
            local c_pos = self:get_chunk_coords_from_pos({x=center.x+offset_x, y=center.y+offset_y})
            local x = c_pos.x
            local y = c_pos.y
            if (self.chunk_regrow.map[x] == nil) then
                self.chunk_regrow.map[x] = {}
            end
            if (self.chunk_regrow.map[x][y] ~= -1) then
                self.chunk_regrow.map[x][y] = game.tick + bonus_time
            end
        end
    end
end

function RegrowthMap:on_ready()
    --- Hook Events

    --RegrowthMap:on(defines.events.on_surface_created, function(event)
    --    -- surface_index
    --    GAME_SURFACE_NAME = game.surfaces[1]
    --end)

    self:on(defines.events.on_chunk_generated, function(self, event)
        self:regrowth_chunk_generate(event.area.left_top)
    end)

    self:on(defines.events.on_tick, function(self, event)
        self:regrowth_on_tick()
    end)


    self:on(defines.events.on_sector_scanned, function(self, event)
        self:regrowth_sector_scan(event)
    end)

    self:on(defines.events.on_built_entity, function(self, event)
        if event.created_entity.type ~= 'car' and event.created_entity.type ~= 'spider-vehicle' then
            self:regrowth_off_limits_chunk(event.created_entity.position)
        else
            table.insert(self.vehicles, event.created_entity)
        end
    end)

    self:on(defines.events.on_robot_built_entity, function(self, event)
        if event.created_entity.type ~= 'car' and event.created_entity.type ~= 'spider-vehicle' then
            self:regrowth_off_limits_chunk(event.created_entity.position)
        else
            table.insert(self.vehicles, event.created_entity)
        end
    end)

    self:on(defines.events.script_raised_built, function(self, event)
        if event.entity.type ~= 'car' and event.entity.type ~= 'spider-vehicle' then
            self:regrowth_off_limits_chunk(event.entity.position)
        else
            table.insert(self.vehicles, event.entity)
        end
    end)

    self:on(defines.events.on_player_mined_entity, function(self, event)
        self:regrowth_check_chunk_empty(event)
    end)

    self:on(defines.events.on_robot_mined_entity, function(self, event)
        self:regrowth_check_chunk_empty(event)
    end)

    Command.add_admin_command("clean-map", {"regrowth_map.force_cleanup_help"}, function(data)
        local timeout_ticks = tonumber(data.parameter) or 18000
        if timeout_ticks < 600 then
            game.get_player(data.player_index).print({"regrowth_map.force_cleanup_timeout_too_fast"})
        else
            game.print({"regrowth_map.force_cleanup_message", timeout_ticks})
            self:regrowth_on_tick(timeout_ticks)
        end
    end)
end


return RegrowthMap
