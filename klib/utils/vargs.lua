local TypeUtils = require('klib/utils/type')
local assert_is_function = TypeUtils.assert_is_function

local Parser = {}

function Parser:new (...)
    return setmetatable({
        args = {...},
        index = 1
    }, { __index = Parser })
end

function Parser:length()
    return #self.args
end

function Parser:has_next()
    return self.index <= #self.args
end

function Parser:next(handler)
    if self:has_next() then
        local value = self.args[self.index]
        self.index = self.index + 1
        if nil ~= handler then
            assert_is_function(handler)
            handler(value)
        end
        return value
    else
        return nil
    end
end

function Parser:next_if(condition, handler)
    assert_is_function(condition)
    if self:has_next() then
        local value = self.args[self.index]
        if condition(value) then
            self.index = self.index + 1
            if nil ~= handler then
                assert_is_function(handler)
                handler(value)
            end
            return value
        end
    end
    return nil
end

function Parser:next_if_string(handler)
    return self:next_if(TypeUtils.is_string, handler)
end

function Parser:next_if_table(handler)
    return self:next_if(TypeUtils.is_table, handler)
end


setmetatable(Parser, {__call = Parser.new})
return Parser
