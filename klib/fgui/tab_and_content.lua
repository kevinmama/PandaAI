local KC = require 'klib/container/container'
local GE = require 'klib/fgui/gui_element'
local BaseComponent = require 'klib/fgui/base_component'
local gui = require 'flib/gui'

local TabAndContent = KC.class('klib.fgui.TabAndContent', BaseComponent, function(self, tabbed_pane)
    BaseComponent(self)
    self.tabbed_pane = tabbed_pane
    self.caption = {"missing_text"}
end)

TabAndContent.TAB = "tab"
TabAndContent.CONTENT = "content"
TabAndContent.TABBED_PANE = "tabbed_pane"

function TabAndContent:create_structure(player)
    return {
        tab = { type = "tab", caption = self.caption , style="frame_tab", style_mods = {font = "heading-2"}},
        content = { type = "flow", direction = 'vertical' }
    }
end

function TabAndContent:build_content(player, parent, tab_refs)
    local structure = self:create_content_structure(player)
    self:set_component_tag(structure)
    return gui.build(parent, {structure})
end

function TabAndContent:create_content_structure(player)
end

function TabAndContent:on_selected(event, refs)
end

return TabAndContent