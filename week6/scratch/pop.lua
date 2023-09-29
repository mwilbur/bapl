pt=require"../pt"

Stack = {}
function Stack:new() 
  local t= { top = 0, data = {} }
  self.__index = self
  setmetatable(t, self)
  return t
end 

function Stack:push(...)
  local vals = table.pack(...)
  for i = 1,#vals do
      self.top=self.top+1
      self.data[self.top]=vals[i]
  end
end

function Stack:pop(n)
  local t = {}
  for i = 1,n do
    t[#t+1]=self.data[self.top]
    self.data[self.top]=nil
    self.top=self.top-1
  end
  return table.unpack(t)
end

s = Stack:new()

s:push(9,10,11)
a,b = s:pop(2)

print(a,b,pt.pt(s))
