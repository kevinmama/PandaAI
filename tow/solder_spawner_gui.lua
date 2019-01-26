require 'klib/klib'

local SolderSpawnerGUI = KContainer.define_class('SolderSpawnerGUI', {
    spawn_solder_btn_name = 'spawn_solder_btn',
    command_menu_name = 'command_menu'
}, function(self, spawner)
    game.print('init spawner ui for player: ' .. spawner.player.name)
    self.spawner = spawner
    self.player = spawner.player
    self:create()
end)

--------------------------------------------------------------------------------
--- spawn btn
--------------------------------------------------------------------------------

local SpawnBtnCreator = {}
function SpawnBtnCreator.create(self)
    self.spawn_btn = self.player.gui.top.add({
        type = "button",
        name = self.spawn_solder_btn_name,
        caption = 'S'
    })
end

function SpawnBtnCreator.register(self)
    KGui.on_click(self.spawn_btn, function()
        self.spawner:spawn_around_player()
    end)
end

--------------------------------------------------------------------------------
--- command dropdown
--------------------------------------------------------------------------------

local CommandMenu = {}
function CommandMenu.create(self)
    self.command_menu = self.player.gui.top.add({
        type = 'button',
        name = self.command_menu_name,
        caption = 'C'
    })
end

function CommandMenu.register(self)
    KGui.on_click(self.command_menu, function(event)
        if self.cmd ~= 'standby' then
            self.cmd = 'standby'
            self.spawner:command(KCommand.Standby)
        else
            self.cmd = 'follow'
            self.spawner:command(KCommand.Follow, self.player)
        end
    end)
end

function SolderSpawnerGUI:create()
    SpawnBtnCreator.create(self)
    CommandMenu.create(self)
end

function SolderSpawnerGUI:on_ready()
    SpawnBtnCreator.register(self)
    CommandMenu.register(self)
end

return SolderSpawnerGUI
