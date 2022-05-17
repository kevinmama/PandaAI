local KC = require 'klib/container/container'
local table = require('klib/utils/table')
local Type = require 'klib/utils/type'
local Rendering = require 'klib/gmo/rendering'

local Path = KC.class('ai.Path', function(self, surface, waypoints)
    self.surface = surface
    -- waypoints is a list of { position, needs_destroy_to_reach }
    self.waypoints = {}
    if Type.is_table(waypoints) then
        table.merge(self.waypoints, waypoints, true)
    end
end)

function Path:add_position(position, needs_destroy_to_reach)
    table.insert(self.waypoint, {
        position = position,
        needs_destroy_to_reach = needs_destroy_to_reach and true or false
    })
end

function Path:display(opts)
    self:destroy_display()
    self._rendering_ids = Rendering.draw_path(self.waypoints, table.dictionary_merge(opts or {}, {
        color = {r=0, g=1, b=0},
        width = 5,
        surface = self.surface
    }))
end

function Path:destroy_display()
    Rendering.destroy_all(self._rendering_ids)
    self._rendering_ids = nil
end

function Path:show_display()
    Rendering.show_all(self._rendering_ids)
end

function Path:hide_display()
    Rendering.hide_all(self._rendering_ids)
end

function Path:on_destroy()
    self:destroy_display()
end

return Path
