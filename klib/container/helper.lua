local Helper = {}

function Helper.trigger(object, func)
    if object[func] then
        object[func](object)
    end
end

return Helper
