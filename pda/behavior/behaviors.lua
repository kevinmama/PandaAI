local PACKAGE = 'pda/behavior/'

local Behaviors = {}

Behaviors.Follow = require(PACKAGE .. 'follow')
Behaviors.Alert = require(PACKAGE .. 'alert')
Behaviors.Separation = require(PACKAGE .. 'separation')
Behaviors.PathFollowing = require(PACKAGE .. 'path_following')

return Behaviors
