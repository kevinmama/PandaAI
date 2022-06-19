local ApiNew = require 'klib/container/api_new'
local ApiInit = require 'klib/container/api_init'
local ApiInfo = require 'klib/container/api_info'
local next_id = require 'klib/container/id_generator'

local Container = {}
Container.class = ApiNew.class
Container.singleton = ApiNew.singleton
Container.class_builder = ApiNew.class_builder
Container.get = ApiNew.get

Container.init = ApiInit.init
Container.load = ApiInit.load

Container.get_object_id = ApiInfo.get_object_id
Container.get_class = ApiInfo.get_class
Container.get_base_class = ApiInfo.get_base_class
Container.is_class = ApiInfo.is_class
Container.is_object = ApiInfo.is_object
Container.for_each_object = ApiInfo.for_each_object
Container.find_object = ApiInfo.find_object
Container.filter_objects = ApiInfo.filter_objects
Container.equals = ApiInfo.equals
Container.is_valid = ApiInfo.is_valid

Container.next_id = next_id

ApiInit.init_container(Container)

return Container

