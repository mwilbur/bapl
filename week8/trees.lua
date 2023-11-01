local pt=require"pt"
package.path = package.path .. ";./busted/?.lua"
busted = require"busted"

local function flatten(ts)
  if ts[1].leaf then
    return ts
  end
  local t = ts[1]
  for i=2,#ts do
    for _,v in ipairs(ts[i]) do
      t[#t+1]=v
    end
  end
  return t
end

local function treesAtLevel(ts,n,curr)
  curr = curr or 1
  if n == curr then
    return ts.trees 
  else 
    local x = {}
    for _, t in ipairs(ts.trees) do
      x[#x+1] = treesAtLevel(t,n,curr+1)
    end
    return flatten(x)
  end
end

local function makeLeaves(vs)
  local t = {}
  for _,v in ipairs(vs) do
    t[#t+1]={leaf=true, value=v}
  end
  return { leaf = false, trees = t }
end

local function depth(t) 
  if t.leaf then
    return 0
  else 
    local d = depth(t.trees[1])
    for i=2,#t.trees do
      assert(depth(t.trees[i])==d)
    end
    return d+1
  end
end

local function eq(t1,t2) 
  if type(t1) == "table" and type(t2) == "table" then
    if #t1 == #t2 then
      local e = true
      for i=1,#t1 do
        e = e and eq(t1[i],t2[i])
      end
      return e
    else 
      return false
    end
  else
    return t1 == t2
  end
end

--print(pt.pt(eq({1,{7,2},2,{4}},{1,{7,2},2,{4}})))


local function dims(ts) 
    if ts.leaf then
      return {}
    else
      local ds = {#ts.trees}
      local d = dims(ts.trees[1])
      for i=2,#ts.trees do
        local dd = dims(ts.trees[i])
        assert(eq(d,dd),"Inconsistent dimensions")
      end
      for _,v in ipairs(d) do
        ds[#ds+1] = v
      end
      return ds
    end
    
end





--print(pt.pt(depth(makeLeaves{1,2,3,4})))

local t1 = { leaf=false, trees={ makeLeaves{2,3,4}, makeLeaves{3,4,5} } }
local t2 = { leaf=false, trees={ makeLeaves{5,6,7}, makeLeaves{7,8,9} } }
local t3 = { leaf=false, trees={t1, t2} }
print(pt.pt(dims(t3)))
--local tt = treesAtLevel(t3,3)
--print(#tt)
--print(pt.pt(treesAtLevel(t3,1)))
--print(pt.pt(treesAtLevel(t3,2)))



--local function makeTree(
  

--print(pt.pt(flatten{1,2,3}))
--print(pt.pt(flatten{{1,2}}))
--print(pt.pt(flatten{{1,2},{3,4}}))
--print(pt.pt(flatten(flatten{{{1,2}},{{3,4}}})))

