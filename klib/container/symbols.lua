local Symbols = {}

Symbols.GLOBAL_REGISTRY = "kcontainer"
Symbols.CLASS_REGISTRY = "classes"
Symbols.OBJECT_REGISTRY = "objects"

Symbols.CLASS_NAME = "_class_"
Symbols.OBJECT_ID = "_id_"
Symbols.BASE_CLASS_NAME = "_base_class_"
Symbols.SINGLETON = "_singleton_"
Symbols.LAZY_INIT = "_lazy_init_" -- 延迟初始化，用于带参数的单例
Symbols.RAW = "_raw_" -- 加载器不再展开表，寻找 K 结构，客户代码要自己处理表

Symbols.GET_CLASS_NAME = "get_class_name"
Symbols.GET_BASE_CLASS_NAME = "get_base_class_name"

Symbols.GET_OBJECT_ID = "get_object_id"
Symbols.GET_OBJECT_ID_SHORT = "get_id"
Symbols.GET_CLASS = "get_class"
Symbols.SUPER = "super"

Symbols.NEW = "new"
Symbols.CONSTRUCTOR = "_constructor_"
Symbols.DESTROY = "destroy"
Symbols.REFERENCE_OBJECTS = "reference_objects"

Symbols.ON_LOAD = "on_load"
Symbols.ON_READY = "on_ready"
Symbols.ON_DESTROY = "on_destroy"

Symbols.BIND_EVENT = "on"
Symbols.BIND_NTH_TICK = "on_nth_tick"

return Symbols
