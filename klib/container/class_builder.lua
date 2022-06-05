local dlog = require('klib/container/dlog')
local Type = require('klib/utils/type')
local ClassRegistry = require('klib/container/class_registry')
local ClassDefiner = require('klib/container/class_definer')

local assert_is_string, assert_is_table, assert_is_function = Type.assert_is_string, Type.assert_is_table, Type.assert_is_function

local ClassBuilder = {}

function ClassBuilder.new(class_name)
    dlog(dlog.Level.DEBUG, 'ClassBuilder.new(class_name): ', class_name)
    assert_is_string(class_name, 'class_name')
    local o = {
        class_name = class_name
    }
    return setmetatable(o, {__index = ClassBuilder})
end

function ClassBuilder:extend(base_class_name)
    local base_class = ClassRegistry.get_class(base_class_name)
    if base_class == nil then
        error('You must define base class first. You may require the defining script at the beginning.')
    end
    self.base_class = base_class
    return self
end

function ClassBuilder:variables(class_variables)
    assert_is_table(class_variables, 'class_variables')
    self.class_variables = class_variables
    return self
end

function ClassBuilder:constructor(constructor_function)
    assert_is_function(constructor_function, 'constructor')
    self.constructor_function = constructor_function
    return self
end

function ClassBuilder:singleton()
    self._singleton = true
end

function ClassBuilder:build()
    local class = ClassRegistry.new_class(self.class_name)
    ClassDefiner.define_singleton(class, self._singleton or false)
    if nil ~= self.class_variables then
        ClassDefiner.define_class_variables(class, self.class_variables)
    end
    if nil ~= self.base_class then
        ClassDefiner.define_base_class(class, self.base_class)
    end
    ClassDefiner.define_class_functions(class)
    ClassDefiner.define_constructor(class, self.constructor_function)
    ClassDefiner.define_destroyer(class)
    ClassDefiner.define_object_references_definer(class)
    ClassDefiner.define_delegate_binder(class)
    ClassDefiner.define_event_binder(class)
    return class
end

return ClassBuilder
