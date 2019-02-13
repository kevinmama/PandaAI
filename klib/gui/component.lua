local UiEvent = require 'klib/gui/event'
local Event = require 'klib/kevent'

local KEY_GLOBAL_REGISTRY = "klib.gui.component.REG"
local KEY_ELEMENT = "element"
local KEY_TOGGLE_COMPONENT = "toggle_component"

local REG = {}
local NEXT_ID = 1
local function next_id()
    local id = NEXT_ID
    NEXT_ID = NEXT_ID + 1
    return id
end

local Component = {
    top = 'top',
    left = 'left',
    center = 'center'
}

function Component:new(name)
    local component = {
        id = next_id(),
        name = name
    }
    setmetatable(component, { __index = self })
    return component
end

local function parse_custom_options(options, defaults)
    local opts
    if type(options) == 'string' then
        opts = { name = options }
    else
        opts = {}
        for k, v in pairs(options) do
            opts[k] = v
        end
    end
    for k, v in pairs(defaults) do
        if nil == opts[k] then
            opts[k] = v
        end
    end
    if nil == opts.constructor then
        opts.constructor = function(self, parent, opts)
            return parent.add(opts)
        end
    end
    return opts
end

-- for button, flow, etc... to custom itself
function Component:_custom(defaults)
    self.create = function(self, options)
        local opts = parse_custom_options(options, defaults)
        local component = self:new(opts.name)
        local constructor = opts.constructor
        opts.constructor = nil
        component:_prebuild(constructor, opts)
        return component
    end
end

function Component:_prebuild(constructor, options)
    self._build = function(self, player_index, parent)
        local element = constructor(self, parent, options)
        self:set_element(player_index, element)
        if self._init then
            self:_init(element)
        end
        return element
    end
    return self
end

function Component:_attach(component, player_index)
    local player = game.players[player_index]
    local parent
    if component == Component.top then
        parent = player.gui.top
    elseif component == Component.left then
        parent = player.gui.left
    elseif component == Component.center then
        parent = player.gui.center
    else
        parent = component:get_element(player_index)
    end
    self:_build(player_index, parent)
    return self
end

function Component:attach(component, player_index)
    if type(component) == 'string' and player_index == nil then
        Event.register(defines.events.on_player_created, function(event)
            self:_attach(component, event.player_index)
        end)
    else
        self:_attach(component, player_index)
    end
    return self
end

function Component:destroy(player_index)
    self:get_element(player_index).destroy()
    table.remove(REG[player_index], self.id)
end

function Component:set_data(player_index, key, value)
    if REG[player_index] == nil then
        REG[player_index] = {}
    end
    local player_registry = REG[player_index]
    if player_registry[self.id] == nil then
        player_registry[self.id] = {}
    end
    local element_registry = player_registry[self.id]
    element_registry[key] = value
end

function Component:remove_data(player_index, key)
    local player_registry = REG[player_index]
    if nil ~= player_registry then
        local element_registry = player_registry[self.id]
        if nil ~= element_registry then
            element_registry[key] = nil
        end
    end
end

function Component:get_data(player_index, key)
    local player_registry = REG[player_index]
    if player_registry ~= nil then
        local element_registry = player_registry[self.id]
        if element_registry ~= nil then
            return element_registry[key]
        end
    end
    return nil
end

function Component:get_element(player_index)
    return self:get_data(player_index, KEY_ELEMENT)
end

function Component:set_element(player_index, element)
    self:set_data(player_index, KEY_ELEMENT, element)
end

function Component:on_click(handler)
    UiEvent.on_click(self.name, handler)
    return self
end

function Component:on_toggle(handler)
    UiEvent.on_click(self.name, function(event)
        local toggle_component = self:get_data(event.player_index, KEY_TOGGLE_COMPONENT)
        if toggle_component == nil then
            toggle_component = handler(event)
            self:set_data(event.player_index, KEY_TOGGLE_COMPONENT, toggle_component)
        else
            toggle_component:destroy(event.player_index)
            self:remove_data(event.player_index, KEY_TOGGLE_COMPONENT)
        end
    end)
    return self
end

return Component
