local KC = require 'klib/container/container'
local Agent = require('klib/agent/base')

function Agent:join_group(group)
    self.groups[KC.get_id(group)] = group
end

function Agent:leave_group(group)
    self.groups[KC.get_id(group)] = nil
end
