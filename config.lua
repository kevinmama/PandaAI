__DEBUG__ = true
--_DISPLAY_STEER__ = true

if __DEBUG__ then
    dpl = function(...)
        game.print(serpent.line(...))
    end
    dpb = function(...)
        game.print(serpent.block(...))
    end
end