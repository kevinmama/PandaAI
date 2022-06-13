local mod_gui = require '__core__/lualib/mod-gui'
local gui = require 'flib/gui'
local KC = require 'klib/container/container'
local Table = require 'klib/utils/table'
local Type = require 'klib/utils/type'
local Tasks = require 'klib/task/tasks'

local GE = require 'klib/fgui/gui_element'
local ModGuiButton = require 'klib/fgui/mod_gui_button'

--- 顶部按钮基类，一般用其子类单例
local ModGuiFrameButton = KC.class("klib.fgui.ModGuiFrame", ModGuiButton, function(self)
    ModGuiButton(self)
    self.mod_gui_frame_caption = {"missing_text"}
    self.mod_gui_frame_minimal_width = 800
    self.close_others_on_open = true
    self.ignore_close_others_on_open = false
    self.auto_update = false
end)

ModGuiFrameButton.MOD_GUI_FRAME = "mod_gui_frame"
ModGuiFrameButton.MOD_GUI_FRAME_CONTENT = "mod_gui_frame_content"
ModGuiFrameButton.AUTO_UPDATE_INTERVAL = 60

function ModGuiFrameButton:build(player)
    ModGuiButton.build(self, player)
    local refs = self.refs[player.index]
    Table.merge(refs, self:build_mod_gui_frame(player))
    local buildReturn = self:build_frame_content(player, refs[ModGuiFrameButton.MOD_GUI_FRAME])
    if buildReturn then
        if Type.is_table(buildReturn) then
            Table.merge(refs, buildReturn)
        else
            refs[ModGuiFrameButton.MOD_GUI_FRAME_CONTENT] = refs[ModGuiFrameButton.MOD_GUI_FRAME_CONTENT] or buildReturn
        end
    end
    self:post_build(player, refs)
end

function ModGuiFrameButton:build_mod_gui_frame(player)
    return gui.build(mod_gui.get_frame_flow(player), {
        GE.frame(true, mod_gui.frame, {ModGuiFrameButton.MOD_GUI_FRAME}, {
            style_mods = { minimal_width = self.mod_gui_frame_minimal_width },
            elem_mods = {visible = false},
        }, {
            GE.flow(false, nil, {
                GE.label(self.mod_gui_frame_caption, "frame_title", nil, {ignored_by_interaction = true}),
                GE.fill_horizontally(),
                GE.sprite_button(self, "utility/close_white", "frame_action_button",
                        nil, "close_mod_gui_frame", {
                    hovered_sprite = "utility/close_black",
                    clicked_sprite = "utility/close_black",
                })
            })
        })
    })
end

function ModGuiFrameButton:build_frame_content(player, parent)
    local structure = self:create_frame_content_structure(player)
    self:set_component_tag(structure)
    return gui.build(parent, {structure})
end

function ModGuiFrameButton:create_frame_content_structure(player)
end

function ModGuiFrameButton:post_build(player, refs)
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
    if self.close_others_on_open then
        KC.for_each_object(ModGuiFrameButton, function(other)
            if other:get_id() ~= self:get_id() and not other.ignore_close_others_on_open then
                local other_refs = other.refs[event.player_index]
                -- 初始化过程中，其它组件还没初始化完成，故不调用
                if other_refs then
                    other:close_mod_gui_frame({ player_index = event.player_index }, other_refs)
                end
            end
        end)
    end
    create_update_task_if_not(self, player)
    if self.on_open_frame then
        self:on_open_frame(event, refs)
    end
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
