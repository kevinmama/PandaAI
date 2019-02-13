local Component = require('klib/gui/component')

local Flow = setmetatable({}, { __index = Component })

Flow:_custom({
    type = 'flow',
    direction = 'vertical'
})

function Flow:_init(element)
    if self._item_constructor then
        self._item_constructor(self, element.player_index)
    end
end


function Flow:items(item_constructor)
    self._item_constructor = item_constructor
    return self
end

return Flow
