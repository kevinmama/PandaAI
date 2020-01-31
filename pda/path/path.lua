local Log = require('__stdlib__/stdlib/misc/logger').new("path", true)
local table = require('__stdlib__/stdlib/utils/table')
local Is = require('__stdlib__/stdlib/utils/is')
local KC = require 'klib/container/container'
local Rendering = require 'klib/rendering/rendering'

local Path = KC.class('pda.path.Path', function(self, surface, nodes)
    --    node is position
    self.nodes = {}
    self.surface = surface
    self._rendering_ids = {}
    if Is.table(nodes) then
        table.merge(self.nodes, nodes, true)
    end
end)

function Path:add_node(node)
    table.insert(self.nodes, node)
end

function Path:display(opts)
    self:erase()
    self._rendering_ids = Rendering.draw_path(self.nodes, table.dictionary_merge(opts or {}, {
        color = {r=0, g=1, b=0},
        width = 2,
        surface = self.surface
    }))
end

function Path:erase()
    table.each(self._rendering_ids, function(id)
        rendering.destroy(id)
    end)
    self._rendering_ids = {}
end

function Path:show()
    table.each(self._rendering_ids, function(id)
        rendering.set_visible(id, true)
    end)
end

function Path:hide()
    table.each(self._rendering_ids, function(id)
        rendering.set_visible(id, false)
    end)
end

function Path:on_destroy()
    self:erase()
end

return Path
