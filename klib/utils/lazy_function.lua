local LazyFunction = {}

function LazyFunction.call(object, method, ...)
    if object and object[method] then
        return object[method](object, ...)
    else
        return nil
    end
end

function LazyFunction.delegate_instance_method(class, field_name, method_name, alias_name)
    if nil == alias_name then
        alias_name = method_name
    end
    class[alias_name] = function(self, ...)
        local field = self['get_' .. field_name](self)
        return field[method_name](field, ...)
    end
end

function LazyFunction.delegate_instance_methods(class, field_name, methods)
    for _, method_name in ipairs(methods) do
        class[method_name] = function(self, ...)
            local field = self['get_' .. field_name](self)
            return field[method_name](field, ...)
        end
    end
end

return LazyFunction
