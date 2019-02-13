local Component = require('klib/gui/component')

local Button = setmetatable({}, { __index = Component })

Button:_custom({
    type = 'button'
})

return Button
