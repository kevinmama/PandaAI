local Vargs = require 'klib/utils/vargs'
local TypeUtils = require 'klib/utils/type_utils'

local Level = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4
}

local default_level = Level.INFO
local default_threshold
if DEBUG then
    default_threshold = Level.DEBUG
else
    default_threshold = Level.ERROR
end

local DebugLog = {
    Level = Level,
    enable = true,
    threshold = default_threshold,
    level = default_level
}

function DebugLog.new()
    local debug = setmetatable({}, {__index = DebugLog })
    local meta = getmetatable(debug)
    meta.__call = debug.log
    return debug
end

local function get_level(self, vargs)
    local level
    if 1 == vargs:length() then
        level = self.level
    else
        level = vargs:next_if(TypeUtils.is_int) or self.level
    end
    return level
end

local function get_message(vargs)
    local m = ""
    vargs:next_if(TypeUtils.is_string, function(message)
        m = m .. message
    end)
    vargs:next(function(object)
        m = m .. serpent.block(object)
    end)
    return m
end

--- log(level, message, object)
--- log(message, object)
--- log(object)
--- log(level, object)
--- log(level, message)
function DebugLog:log(...)
    if self.enable then
        local vargs = Vargs(...)
        local level = get_level(self, vargs)
        if level <= self.threshold then
            log(get_message(vargs))
        end
    end
end

setmetatable(DebugLog, { __call = DebugLog.log })

return DebugLog
