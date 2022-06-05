log(table_size({"aa", "bb"}))
log(table_size({a=1,b=2}))
log(table_size({5,3,a=1,b=2}))

local a = {}
table.insert(a, 4, 4)
log(serpent.line(a))
table.insert(a, 3, 3)
log(serpent.line(a))
table.insert(a, 2, 2)
log(serpent.line(a))
table.insert(a, 1, 1)
log(serpent.line(a))
