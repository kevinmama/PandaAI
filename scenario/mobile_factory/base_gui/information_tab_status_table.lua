local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local String = require 'klib/utils/string'
local GE = require 'klib/fgui/gui_element'
local BaseComponent = require 'klib/fgui/base_component'
local ColorList = require 'stdlib/utils/defines/color_list'
local Config = require 'scenario/mobile_factory/config'

local first_column_style_mods = {width = 100}

local StatusTable = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'StatusTable', BaseComponent, function(self, parent)
    BaseComponent(self)
    self.parent = parent
end)

StatusTable:delegate_method("parent", {
    "get_selected_base",
    "get_selected_base_id"
})

function StatusTable:build(player, parent)
    self.refs[player.index] = gui.build(parent, {
        GE.hr(),
        GE.h1({"mobile_factory_base_gui.information_tab_status_caption"}),
        GE.hr(),
        GE.flow(false, nil, {
            GE.h2({"mobile_factory_base_gui.information_tab_working_state_label"}, first_column_style_mods),
            GE.h3("", {font_color = ColorList.green}, {ref = {"working_state_label"}}),
            GE.h3({"mobile_factory.state_text_heavy_damaged"}, {font_color = ColorList.red, left_margin=10}, {ref = {"heavy_damage_label"}}),
            GE.fill_horizontally(),
            GE.sprite_button(self, "entity/substation", "tool_button",
                    {"mobile_factory_base_gui.information_tab_toggle_working_state_tooltip"},
                    "toggle_working_state"),
            GE.sprite_button(self, "utility/side_menu_blueprint_library_hover_icon", "tool_button_blue",
                    {"mobile_factory_base_gui.information_tab_show_deploy_area"},
                    "show_deploy_area"),
            GE.sprite_button(self, "utility/side_menu_blueprint_library_hover_icon", "tool_button_red",
                    {"mobile_factory_base_gui.information_tab_clear_deploy_area"},
                    "clear_deploy_area")
        }),
        GE.flow(false, nil, {
            GE.h2({"mobile_factory_base_gui.information_tab_power_label"}, first_column_style_mods),
            GE.progressbar("electric_satisfaction_progressbar", {bar_width = 20}, {"energy_progressbar"}),
            GE.label("", "electric_usage_label", {minimal_width=50, maximal_width=100}, {ref = {"energy_amount_label"}}),
        })
    })
end

function StatusTable:update(player)
    local base = self:get_selected_base(player.index)
    if base and base.generated and not base.destroyed then
        local refs = self.refs[player.index]
        refs.working_state_label.caption = base:get_working_state_label()
        refs.heavy_damage_label.visible = base:is_heavy_damaged()
        refs.energy_progressbar.value = base.hyper_accumulator.energy / base.hyper_accumulator.electric_buffer_size
        refs.energy_amount_label.caption = String.exponent_string(base.hyper_accumulator.energy) .. '/' .. String.exponent_string(base.hyper_accumulator.electric_buffer_size)
    end
end

function StatusTable:show_deploy_area(e, refs)
    self:get_selected_base(e.player_index):toggle_display_deploy_area()
end

function StatusTable:clear_deploy_area(e, refs)
    self:get_selected_base(e.player_index):clear_deploy_area()
end

function StatusTable:toggle_working_state(e, refs)
    self:get_selected_base(e.player_index):toggle_working_state()
end

return StatusTable