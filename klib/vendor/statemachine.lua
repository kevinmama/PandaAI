---
--- Modified by kevinma
--- 修改以使符合工厂的设定
--- 把过度方法名设置为 on_xxx
---

local machine = {}
machine.__index = machine

local NONE = "none"
local ASYNC = "async"

local function call_handler(handler, params)
    if handler then
        return handler(unpack(params))
    end
end

local function create_transition(name)
    local can, to, from, params

    local function transition(self, ...)
        if self.asyncState == NONE then
            can, to = self:can(name)
            from = self.current
            params = { self, name, from, to, ...}

            if not can then return false end
            self.currentTransitioningEvent = name

            local beforeReturn = call_handler(self["on_before" .. name], params)
            local leaveReturn = call_handler(self["on_leave" .. from], params)

            if beforeReturn == false or leaveReturn == false then
                return false
            end

            self.asyncState = name .. "WaitingOnLeave"

            if leaveReturn ~= ASYNC then
                transition(self, ...)
            end

            return true
        elseif self.asyncState == name .. "WaitingOnLeave" then
            self.current = to

            local enterReturn = call_handler(self["on_enter" .. to] or self["on_" .. to], params)

            self.asyncState = name .. "WaitingOnEnter"

            if enterReturn ~= ASYNC then
                transition(self, ...)
            end

            return true
        elseif self.asyncState == name .. "WaitingOnEnter" then
            call_handler(self["on_after" .. name] or self["on_" .. name], params)
            call_handler(self["on_state_change"], params)
            self.asyncState = NONE
            self.currentTransitioningEvent = nil
            return true
        else
            if string.find(self.asyncState, "WaitingOnLeave") or string.find(self.asyncState, "WaitingOnEnter") then
                self.asyncState = NONE
                transition(self, ...)
                return true
            end
        end

        self.currentTransitioningEvent = nil
        return false
    end

    return transition
end

local function add_to_map(map, event)
    if type(event.from) == 'string' then
        map[event.from] = event.to
    else
        for _, from in ipairs(event.from) do
            map[from] = event.to
        end
    end
end

function machine.create(options)
    assert(options.events)

    local fsm = {}
    setmetatable(fsm, machine)

    fsm.options = options
    fsm.current = options.initial or 'none'
    fsm.asyncState = NONE
    fsm.events = {}

    for _, event in ipairs(options.events or {}) do
        local name = event.name
        fsm[name] = fsm[name] or create_transition(name)
        fsm.events[name] = fsm.events[name] or { map = {} }
        add_to_map(fsm.events[name].map, event)
    end

    for name, callback in pairs(options.callbacks or {}) do
        fsm[name] = callback
    end

    return fsm
end

function machine.load(callbacks)
    for _, event in ipairs(self.events or {}) do
        local name = event.name
        self[name] = self[name] or create_transition(name)
    end
    for name, callback in pairs(callbacks) do
        self[name] = callback
    end
end

function machine:is(state)
    return self.current == state
end

function machine:can(e)
    local event = self.events[e]
    local to = event and event.map[self.current] or event.map['*']
    return to ~= nil, to
end

function machine:cannot(e)
    return not self:can(e)
end

function machine:todot(filename)
    local dotfile = io.open(filename,'w')
    dotfile:write('digraph {\n')
    local transition = function(event,from,to)
        dotfile:write(string.format('%s -> %s [label=%s];\n',from,to,event))
    end
    for _, event in pairs(self.options.events) do
        if type(event.from) == 'table' then
            for _, from in ipairs(event.from) do
                transition(event.name,from,event.to)
            end
        else
            transition(event.name,event.from,event.to)
        end
    end
    dotfile:write('}\n')
    dotfile:close()
end

function machine:transition(event)
    if self.currentTransitioningEvent == event then
        return self[self.currentTransitioningEvent](self)
    end
end

function machine:cancelTransition(event)
    if self.currentTransitioningEvent == event then
        self.asyncState = NONE
        self.currentTransitioningEvent = nil
    end
end

machine.NONE = NONE
machine.ASYNC = ASYNC

return machine