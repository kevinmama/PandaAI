local ApiNew = require 'klib/container/api_new'
local ApiLoad = require 'klib/container/api_load'
local ApiInfo = require 'klib/container/api_info'

local Container = {}

Container.define_class = ApiNew.define_class
Container.singleton = ApiNew.singleton
Container.get = ApiNew.get

Container.load = ApiLoad.load
Container.persist = ApiLoad.persist

Container.get_id = ApiInfo.get_id
Container.get_class = ApiInfo.get_class

return Container

