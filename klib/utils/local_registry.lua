local _M = {
    __index = function(self, k)
        return self.registry[k]
    end,
    __newindex = function(self,k, v)
        self.registry[k] = v
    end
}

local Registry = {
    registry = {},
    __index = _M.__index,
    __newindex = _M.__newindex
}

function Registry.__call()
    return setmetatable({
        registry = {}
    }, _M)
end

setmetatable(Registry, Registry)

return Registry