local CommandHelper = {}

function CommandHelper.define_name(command_class, name)
    command_class.name = name
    function command_class:get_name()
        return command_class.name
    end
end

return CommandHelper

