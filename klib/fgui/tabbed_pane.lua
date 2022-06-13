local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local LazyTable = require 'klib/utils/lazy_table'
local GE = require 'klib/fgui/gui_element'
local BaseComponent = require 'klib/fgui/base_component'
local gui = require 'flib/gui'

local TabbedPane = KC.class('klib.fgui.TabbedPane', BaseComponent, function(self)
    BaseComponent(self)
    self.caption = {"missing_text"}
    self.style = "frame_tabbed_pane"
    self.tabs = {}
end)

TabbedPane.REF_TABBED_PANE = "tabbed_pane"
TabbedPane.REF_TABS = "tabs"
TabbedPane.REF_CONTENTS = "contents"

function TabbedPane:add_tab(tab)
    Table.insert(self.tabs, tab)
end

function TabbedPane:build(player, parent)
    local structure = self:create_structure()
    for i, tab in pairs(self.tabs) do
        tab.tab_index = i
        local tab_structure = tab:create_structure(player)
        LazyTable.set_if_absent(tab_structure.tab, "ref", { TabbedPane.REF_TABS, i})
        LazyTable.set_if_absent(tab_structure.content, "ref", { TabbedPane.REF_CONTENTS, i})
        Table.insert(structure.tabs, tab_structure)
    end

    local refs = gui.build(parent, {structure})
    self.refs[player.index] = refs

    for i, tab in pairs(self.tabs) do
        local content_frame = refs[TabbedPane.REF_CONTENTS][i]
        tab:build_content(player, content_frame, {
            tabbed_pane = refs[TabbedPane.REF_TABBED_PANE],
            tab = refs[TabbedPane.REF_TABS[i]],
            content = content_frame
        })
    end

    refs.tabbed_pane.selected_tab_index = 1
    return refs
end

function TabbedPane:create_structure()
    return GE.tabbed_pane(self, self.style, {TabbedPane.REF_TABBED_PANE}, "on_selected_tab_changed")
end

function TabbedPane:on_selected_tab_changed(event, refs)
    local index = refs[TabbedPane.REF_TABBED_PANE].selected_tab_index
    local tab = self.tabs[index]
    if tab.on_selected then
        tab:on_selected(event, tab.refs[event.player_index])
    end
end

function TabbedPane:get_selected_tab(player_index)
    return self.tabs[self.refs[player_index][TabbedPane.REF_TABBED_PANE].selected_tab_index]
end

return TabbedPane