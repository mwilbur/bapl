pt = require "../pt"
params = {{ e1 = { tag = "number", value = 5}, e2 = {tag = "number", value=3}, op="<", tag="binary" },
          { name = "a", tag = "assignment", value = {tag = "number", value = 9}},
          { e1 = { tag = "number", value = 1}, e2 = {tag = "number", value=1}, op=">", tag="binary" },
          { name = "a", tag = "assignment", value = {tag = "number", value=13}},"FFFFFF"}
        
--print(pt.pt({tag = "if", cond = params[1], th = params[2], el = { tag = "if", cond = params[3], th = params[4]} }))

top= #params%2 == 0 and #params or #params-1
t = { tag="if", cond=params[top-1], th=params[top], el = params[top+1] }
for n=top-2,1,-2 do
  t = {tag = "if", cond = params[n-1], th = params[n], el = t }
end

print(pt.pt(t))
print(top)
function x(p1,p2) 
end

for i=1,#params,2 do
  
end