local Helper = {}

function Helper.define_name(behavior, name)
    behavior.name = name
    function behavior:get_name()
        return behavior.name
    end
end

return Helper
