local KC = require 'klib/container/container'
local Queue = require 'stdlib/misc/queue'

local function delegate_meta(self)
    local meta = getmetatable(self)
    meta.__call = function(self, ...)
        return self.q(...)
    end
end

local Q = KC.class('klib.classes.Queue', function(self, options)
    self.q = Queue()
    options = options or {}
    self.auto_destroy_elements = options.auto_destroy_elements
    delegate_meta(self)
end)

function Q:on_load()
    Queue.load(self.q)
    delegate_meta(self)
end

function Q:on_destroy()
    if self.auto_destroy_elements then
        local e = self.q()
        while e ~= nil do
            if e.destroy then
                e:destroy()
            end
            e = self.q()
        end
    end
end

-- delegate method from Queue
for name, method in pairs(Queue) do
    if not Q[name] then
        Q[name] = function(self, ...)
            return method(self.q, ...)
        end
    end
end

return Q
