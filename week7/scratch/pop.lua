pt=require"../pt"
vm = require "../vm"

s = vm.Stack:new()
s:push(nil)
s:pop()
print(pt.pt(s))
