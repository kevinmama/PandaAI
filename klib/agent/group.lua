local KAgent = require('klib/agent/agent')

function KAgent:join_group(group)
    self.groups[group[KContainer.OBJECT_ID]] = group
end

function KAgent:leave_group(group)
    self.groups[group[KContainer.OBJECT_ID]] = nil
end