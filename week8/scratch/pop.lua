pt=require"../pt"
vm = require "../vm"

s = vm.Stack:new()
s:push(1,3,4)
print(pt.pt(s))
print(s:peek(1,1))
print(s:get(3))
s:set(1,19)
print(pt.pt(s))

