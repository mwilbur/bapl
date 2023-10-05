pt = require"pt"
local t = { i={1} }
t.j = t.i
print(pt.pt(t.i))
print(pt.pt(t.j))
