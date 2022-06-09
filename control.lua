if script.active_mods["gvv"] then require("__gvv__.gvv")() end

require 'config'

--require 'klib/container/container'
require 'klib/klib'

-- widges
--require 'widget/debug_panel'
--require 'widget/player_info'

-- addons
--require 'addon/player_modifier_in_pollution'
--require 'addon/autofill'

--require "utils.utils"
--require "utils.corpse_util"
--require "bot"
--require "chatbot"
--require "session_tracker"
--require "addons/comfy_factorio/antigrief"
--require "addons/comfy_factorio/antigrief_admin_panel"
--require "addons/comfy_factorio/group"
--require "addons/comfy_factorio/player_list"
--require "addons/comfy_factorio/poll"
--require "addons/comfy_factorio/score"
--
--

--------------------------------------------------------------------------------
--- ### Spec ###
--------------------------------------------------------------------------------
--require 'klib/spec/spiral_index_spec'
--require 'klib/spec/linked_list_spec'
--require 'klib/spec/table_size_spec'
--require 'klib/spec/entity_die_desync'

--------------------------------------------------------------------------------
--- ### Scenario ###
--------------------------------------------------------------------------------
--require 'scenario/quickstart/main'
--require 'scenario/tow/solder_spawner_manager'
require 'scenario/mobile_factory/main'
--require 'scenario/nauvis_war/main'

--------------------------------------------------------------------------------
--- ### For Debug Checking, Should Not Change Global in control stage ###
--------------------------------------------------------------------------------

if next(global) then
    log("!!! detected changing global in control stage !!!")
    log(serpent.line(global))
end
