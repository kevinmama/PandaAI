local mod_gui = require '__core__/lualib/mod-gui'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'
local Tasks = require 'klib/task/tasks'

local ModGuiButton = require 'klib/fgui/mod_gui_button'

--- 顶部按钮基类，一般用其子类单例
local ModGuiFrameButton = KC.class("klib.fgui.ModGuiFrame", ModGuiButton, function(self)
    ModGuiButton(self)
    self.mod_gui_frame_caption = {"missing_text"}
    self.mod_gui_frame_minimal_width = 800
    self.close_on_open_other_frame = true
    self.auto_update = false
end)

ModGuiFrameButton.MOD_GUI_FRAME = "mod_gui_frame"
ModGuiFrameButton.MOD_GUI_FRAME_CLOSE_BUTTON = "mod_gui_frame_close_button"
ModGuiFrameButton.AUTO_UPDATE_INTERVAL = 60

ModGuiFrameButton.SEPARATE_LINE_STYLE_MODS = {
    top_margin = 4,
    bottom_margin = 4
}

function ModGuiFrameButton:build(player)
    ModGuiButton.build(self, player)
    local refs = self.refs[player.index]
    Table.merge(refs, self:build_mod_gui_frame(player))
    local buildReturn = self:build_frame_content(refs[ModGuiFrameButton.MOD_GUI_FRAME], player)
    if buildReturn then
        if Type.is_table(buildReturn) then
            Table.merge(refs, buildReturn)
        else
            Table.insert(refs, buildReturn)
        end
    end
    self:post_build(refs, player)
end

function ModGuiFrameButton:build_mod_gui_frame(player)
    return gui.build(mod_gui.get_frame_flow(player), {
        {
            type = "frame",
            direction = "vertical",
            ref = { ModGuiFrameButton.MOD_GUI_FRAME},
            style = mod_gui.frame_style,
            style_mods = { minimal_width = self.mod_gui_frame_minimal_width },
            visible = false,
            { type = "flow", children = {
                {type = "label", style = "frame_title", caption = self.mod_gui_frame_caption, ignored_by_interaction = true},
                {type = "empty-widget", style = "draggable_space", style_mods = {horizontally_stretchable = true}, ignored_by_interaction = true},
                {
                    type = "sprite-button",
                    style = "frame_action_button",
                    ref = { ModGuiFrameButton.MOD_GUI_FRAME_CLOSE_BUTTON},
                    sprite = "utility/close_white",
                    hovered_sprite = "utility/close_black",
                    clicked_sprite = "utility/close_black",
                    mouse_button_filter = {"left"},
                    actions = {
                        on_click = "close_mod_gui_frame"
                    }
                }
            }}
        }
    })
end

function ModGuiFrameButton:build_frame_content(parent, player)
    local structure = self:create_frame_structure(player)
    return gui.build(parent, {structure})
end

function ModGuiFrameButton:create_frame_structure(player)
end

function ModGuiFrameButton:post_build(refs, player)
end

local AutoUpdateTask = Tasks.register_scheduled_task(
        "klib.fgui.ModGuiFrame$AutoUpdateTask",
        function(self)
            local owner = self.owner
            if self.player.connected and owner.refs[self.player.index][ModGuiFrameButton.MOD_GUI_FRAME].visible then
                if owner.on_auto_update then
                    owner:on_auto_update(self.player)
                end
            else
                owner.auto_update_tasks[self.player.index] = nil
                self:destroy()
            end
        end)

function ModGuiFrameButton:set_auto_update(enable, interval)
    self.auto_update = enable
    self.auto_update_interval = interval or ModGuiFrameButton.AUTO_UPDATE_INTERVAL
    if not self.auto_update_tasks then
        self.auto_update_tasks = {}
    end
end


function ModGuiFrameButton:on_click(event, refs)
    local visible = refs[ModGuiFrameButton.MOD_GUI_FRAME].visible
    if visible then
        self:close_mod_gui_frame(event, refs)
    else
        self:open_mod_gui_frame(event, refs)
    end
end

local function create_update_task_if_not(self, player)
    if self.auto_update_tasks then
        local task = self.auto_update_tasks[player.index]
        if not task or task.destroyed then
            task = AutoUpdateTask:new_local(self.auto_update_interval, self.auto_update_interval)
            task.player = player
            task.owner = self
            self.auto_update_tasks[player.index] = task
        end
    end
end

function ModGuiFrameButton:open_mod_gui_frame(event, refs)
    refs[ModGuiFrameButton.MOD_GUI_FRAME].visible = true
    local player = game.get_player(event.player_index)
    player.opened = refs[ModGuiFrameButton.MOD_GUI_FRAME]
    KC.for_each_object(ModGuiFrameButton, function(other)
        if other ~= self and other.close_on_open_other_frame then
            other:close_mod_gui_frame({
                player_index = event.player_index
            }, other.refs[event.player_index])
        end
    end)
    create_update_task_if_not(self, player)
    if self.on_open_frame then
        self:on_open_frame(event, refs)
    end
end

function ModGuiFrameButton:is_close_mod_gui_frame(event, refs)
    return event.element == refs[ModGuiFrameButton.MOD_GUI_FRAME_CLOSE_BUTTON]
end

function ModGuiFrameButton:close_mod_gui_frame(event, refs)
    local player = game.get_player(event.player_index)
    refs[ModGuiFrameButton.MOD_GUI_FRAME].visible = false
    if player.opened then
        player.opened = nil
    end
    if self.on_close_frame then
        self:on_close_frame(event, refs)
    end
end

return ModGuiFrameButton
