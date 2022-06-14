local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local BaseComponent = require 'klib/fgui/base_component'
local GE = require 'klib/fgui/gui_element'

local EditableLabel = KC.class("klib.fgui.EditableLabel", BaseComponent, function(self, options)
    BaseComponent(self)
    self.caption = options.caption
    self.style = options.style
    self.style_mods = options.style_mods
    self.tooltip = options.tooltip
    self.textfield_style = options.textfield_style or "titlebar_search_textfield"
end)

function EditableLabel:build(player, parent)
    local structure = GE.flow(false, nil, {
        GE.label(self.caption, self.style, self.style_mods, {
            ref = {"label"},
            tooltip = self.tooltip,
            actions = {
                on_click = "edit"
            },
            tags = {
                component_id = self:get_id()
            }
        }),
        GE.textfield(self, "titlebar_search_textfield", {"textfield"}, "submit", {
            elem_mods = {visible = false}
        }),
    })
    self.refs[player.index] = gui.build(parent, structure)
end

function EditableLabel:edit(event, refs)
    refs.label.visible = false
    refs.textfield.visible = true
    refs.textfield.text = refs.label.caption
end

function EditableLabel:submit(event, refs)
    refs.label.visible = false
    refs.textfield.visible = true
    refs.label.caption = refs.textfield.text
end

return EditableLabel