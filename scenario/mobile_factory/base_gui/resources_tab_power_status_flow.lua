local KC = require 'klib/container/container'
local gui = require 'flib/gui'
local String = require 'klib/utils/string'
local GE = require 'klib/fgui/gui_element'
local BaseComponent = require 'klib/fgui/base_component'
local ColorList = require 'stdlib/utils/defines/color_list'
local Config = require 'scenario/mobile_factory/config'

local column_style_mods = { width = 100}
local short_column_style_mods = { width = 50}

local PowerStatusFlow = KC.class(Config.PACKAGE_BASE_GUI_PREFIX .. 'PowerStatusFlow', BaseComponent, function(self, parent)
    BaseComponent(self)
    self.parent = parent
end)

PowerStatusFlow:delegate_method("parent", {
    "get_selected_base",
    "get_selected_base_id"
})

function PowerStatusFlow:build(player, parent)
    self.refs[player.index] = gui.build(parent, {
        GE.hr(),
        GE.flow(false, nil, {
            GE.h1({"mobile_factory_base_gui.power_label"}, column_style_mods),
            GE.flow(false, {style_mods = {width = 300}}, {
                GE.progressbar("electric_satisfaction_progressbar", {bar_width = 20}, {"energy_progressbar"}),
                GE.label("", "electric_usage_label", {minimal_width=50, maximal_width=100}, {ref = {"energy_amount_label"}}),
            }),
            GE.h2({"mobile_factory_base_gui.resource_table_request_header"}),
            GE.editable_label(self, {
                caption = 0,
                tooltip = {"mobile_factory_base_gui.click_to_edit_tooltip"},
                style_mods = short_column_style_mods,
                textfield_style_mods = short_column_style_mods,
                ref = {"request_label"},
                textfield_ref = { "request_textfield" },
                on_edit = "edit_power_request",
                on_submit = "submit_power_request",
            }),
            GE.h2({"mobile_factory_base_gui.resource_table_reserve_header"}),
            GE.editable_label(self, {
                caption = 0,
                tooltip = {"mobile_factory_base_gui.click_to_edit_tooltip"},
                style_mods = short_column_style_mods,
                textfield_style_mods = short_column_style_mods,
                ref = { "reserve_label" },
                textfield_ref = { "reserve_textfield" },
                on_edit = "edit_power_reserve",
                on_submit = "submit_power_reserve",
            }),
            GE.fill_horizontally(),
            GE.sprite_button(self, "entity/substation", "tool_button",
                    { "mobile_factory_base_gui.create_deploy_substation_tooltip" },
                    "create_deploy_substation")
        })
    })
end

function PowerStatusFlow:update(player)
    local base = self:get_selected_base(player.index)
    if base and base:is_active() then
        local refs = self.refs[player.index]
        local info = base:get_power_information()
        refs.energy_progressbar.value = info.energy / info.buffer
        refs.energy_amount_label.caption = String.exponent_string(info.energy, 2) .. '/' .. String.exponent_string(info.buffer, 2)
        refs.request_label.caption = String.exponent_string(info.request, 2)
        refs.reserve_label.caption = String.exponent_string(info.reserve, 2)
    end
end

local function edit(type, refs)
    refs[type .. "_label"].visible = false
    refs[type .. "_textfield"].visible = true
    refs[type .. "_textfield"].text = refs[type .. "_label"].caption
end

function PowerStatusFlow:edit_power_request(e, refs)
    edit("request", refs)
end

function PowerStatusFlow:edit_power_reserve(e, refs)
    edit("reserve", refs)
end

local function submit(type, refs)
    refs[type .. "_label"].visible = true
    refs[type .. "_textfield"].visible = false
    refs[type .. "_label"].caption = refs[type .. '_textfield'].text
end

function PowerStatusFlow:submit_power_request(e, refs)
    submit("request", refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        base:set_power_exchange(String.exponent_number(refs.request_textfield.text))
    end
end

function PowerStatusFlow:submit_power_reserve(e, refs)
    submit("reserve", refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        base:set_power_exchange(nil, String.exponent_number(refs.reserve_textfield.text))
    end
end

function PowerStatusFlow:create_deploy_substation(e, refs)
    local base = self:get_selected_base(e.player_index)
    if base then
        if not base:create_deploy_substation() then
            GE.get_player(e).print({"mobile_factory_base_gui.create_deploy_substation_failed"})
        end
    end
end

return PowerStatusFlow