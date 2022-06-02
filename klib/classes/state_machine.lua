local KC = require 'klib/container/container'

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

            --local callReturn = call_handler(self["on_event_call"], params)
            --local beforeReturn = call_handler(self["on_before_" .. name], params)
            --local leaveReturn = call_handler(self["on_leave_" .. from], params)

            if call_handler(self["on_event_call"], params) == false or
                    call_handler(self["on_before_" .. name], params) == false then
                return false
            end

            local leaveReturn = call_handler(self["on_leave_" .. from], params)
            if leaveReturn == false then return false end

            self.asyncState = name .. "WaitingOnLeave"

            if leaveReturn ~= ASYNC then
                transition(self, ...)
            end

            return true
        elseif self.asyncState == name .. "WaitingOnLeave" then
            self.current = to

            local enterReturn = call_handler(self["on_enter_" .. to] or self["on_" .. to], params)

            self.asyncState = name .. "WaitingOnEnter"

            if enterReturn ~= ASYNC then
                transition(self, ...)
            end

            return true
        elseif self.asyncState == name .. "WaitingOnEnter" then
            call_handler(self["on_after_" .. name] or self["on_" .. name], params)
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

local StateMachine = KC.class("klib.classes.StateMachine", function(self, initial)
    local class = self:get_class()
    self.current = initial or class.initial or 'none'
    self.events = {}
    self.asyncState = NONE
    for _, event in pairs(class.events) do
        local name = event.name
        self.events[name] = self.events[name] or { map = {} }
        add_to_map(self.events[name].map, event)
    end
end)

function StateMachine.create(class, initial, events)
    class.initial = initial
    class.events = events or {}
    for _, event in ipairs(class.events) do
        local name = event.name
        class[name] = class[name] or create_transition(name)
    end
end

function StateMachine:is(state)
    return self.current == state
end

function StateMachine:can(e)
    local event = self.events[e]
    local to = event and event.map[self.current] or event.map['*']
    return to ~= nil, to
end

function StateMachine:cannot(e)
    return not self:can(e)
end

function StateMachine:todot(filename)
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

function StateMachine:transition(event)
    if self.currentTransitioningEvent == event then
        return self[self.currentTransitioningEvent](self)
    end
end

function StateMachine:cancelTransition(event)
    if self.currentTransitioningEvent == event then
        self.asyncState = NONE
        self.currentTransitioningEvent = nil
    end
end

StateMachine.NONE = NONE
StateMachine.ASYNC = ASYNC

return StateMachine