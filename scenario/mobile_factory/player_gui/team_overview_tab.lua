local KC = require 'klib/container/container'
local GE = require 'klib/fgui/gui_element'
local Table = require 'klib/utils/table'
local TabAndContent = require 'klib/fgui/tab_and_content'
local gui = require 'flib/gui'

local Config = require 'scenario/mobile_factory/config'
local Team = require 'scenario/mobile_factory/player/team'
local Player = require 'scenario/mobile_factory/player/player'

local TeamOverviewTab = KC.class(Config.PACKAGE_PLAYER_GUI_PREFIX .. 'TeamOverviewTab', TabAndContent, function(self, tabbed_pane)
    TabAndContent(self, tabbed_pane)
    self.caption = {"mobile_factory_team_gui.team_overview_tab"}
end)

function TeamOverviewTab:build_content(player, parent)
    local structure = {
        GE.table(self, "table", 4, {"overview_table"}, nil, {
            GE.h2({ "mobile_factory_team_gui.team_overview_tab_name" }, {width = 100}),
            GE.h2({ "mobile_factory_team_gui.team_overview_tab_player" }, {horizontally_stretchable = true}),
            GE.h2({"mobile_factory_team_gui.team_overview_tab_rockets"}, {width = 100}),
            GE.h2({ "mobile_factory_team_gui.team_overview_tab_spectate" }, {width = 100})
        })
    }
    local refs = gui.build(parent, structure)
    self.refs[player.index] = refs
    GE.column_alignments(refs.overview_table, "center")
end

local function get_team_overview_data()
    local overview_data = {}
    KC.for_each_object(Team, function(team)
        local rc = {}
        rc.team_id = team:get_id()
        rc.name = team:get_name()
        rc.player_name_list = Table.reduce(team:get_members(), function(name_list, player)
            return name_list .. ' ' .. player.name
        end, '')
        --rc.kills = 0 -- FIXME
        rc.rockets_launched = team.force.rockets_launched or 0
        if team:is_main_team() then
            Table.insert(overview_data, 1, rc)
        else
            Table.insert(overview_data, rc)
        end
    end)
    return overview_data
end

function TeamOverviewTab:update_overview_tab(event, refs)
    GE.update_table(refs.overview_table, {
        skip_row = 1,
        records = get_team_overview_data(),
        create_row = function(t, row, key, rc)
            gui.build(t, {
                GE.label(rc.name, "label", {width = 100}),
                GE.label(rc.player_name_list, "label", {horizontally_stretchable = true}),
                GE.label(rc.rockets_launched, "label", {width = 100}),
                GE.sprite_button(self, "item/raw-fish", "slot_button", nil, "on_spectate_team", {
                    tags = {team_id = rc.team_id}
                })
            })
        end,
        update_row = function(elems, row, key, rc)
            elems[1].caption = rc.name
            elems[2].caption = rc.player_name_list
            elems[3].caption = rc.rockets_launched
            gui.update_tags(elems[4], {team_id = rc.team_id})
            gui.set_action(elems[4], "on_click", "on_spectate_team")
        end
    })
end

function TeamOverviewTab:on_selected(event, refs)
    self:update_overview_tab(event, refs)
end

function TeamOverviewTab:on_spectate_team(event)
    local mf_player = Player.get(event.player_index)
    local team_id = gui.get_tags(event.element).team_id
    mf_player:spectate_team(team_id and KC.get(team_id))
end

TeamOverviewTab:on({
    Config.ON_TEAM_CREATED, Config.ON_TEAM_DESTROYED,
    Config.ON_PLAYER_JOINED_TEAM, Config.ON_PLAYER_LEFT_TEAM
}, function(self, event)
    Table.each(self.refs, function(refs, player_index)
        self:update_overview_tab({
            player_index = player_index
        }, refs)
    end)
end)

return TeamOverviewTab
