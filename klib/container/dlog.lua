local DebugLog = require('klib/utils/dlog')
local dlog = DebugLog.new()
--debug.Level = Debug.Level
dlog.level = DebugLog.Level.DEBUG
dlog.threshold = DebugLog.Level.DEBUG
return dlog
