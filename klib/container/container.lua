local EventBinder = require 'klib/container/event_binder'
local ApiNew = require 'klib/container/api_new'
local ApiLoad = require 'klib/container/api_load'
local ApiInfo = require 'klib/container/api_info'

local Container = {}
Container.class = ApiNew.class
Container.singleton = ApiNew.singleton
Container.class_builder = ApiNew.class_builder
Container.get = ApiNew.get

Container.init = ApiLoad.init
Container.load = ApiLoad.load

Container.get_id = ApiInfo.get_id
Container.get_class = ApiInfo.get_class
Container.get_base_class = ApiInfo.get_base_class
Container.is_class = ApiInfo.is_class
Container.is_object = ApiInfo.is_object

EventBinder.init_container(Container)

return Container

