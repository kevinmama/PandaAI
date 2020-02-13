local KC = require 'klib/container/container'
local table = require '__stdlib__/stdlib/utils/table'

local RenderingGroup = KC.class('klib.rendering.group', function(self)
    self.render_ids = {}
    self._display = true
end)

function RenderingGroup:reset()
    table.each(self.render_ids, function(id)
        rendering.destroy(id)
    end)
    table.clear(self.render_ids)
end

function RenderingGroup:render(renderer)
    local id = renderer()
    if id then
        table.insert(self.render_ids, id)
    end
    return id
end

function RenderingGroup:hide()
    self._display = false
    table.each(self.render_ids, function(id)
        rendering.set_visible(id, false)
    end)
end

function RenderingGroup:show()
    self._display = true
    table.each(self.render_ids, function(id)
        rendering.set_visible(id, true)
    end)
end

function RenderingGroup:on_destroy()
    self:reset()
end

return RenderingGroup
