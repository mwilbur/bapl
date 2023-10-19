local lpeg = require"lpeg"

local function I(msg)
  return lpeg.P( function (_,p) print(msg,p) return true end ) 
end

local q = lpeg.P('"')
local e = lpeg.P("\\") * (1 + q)
local p = q*lpeg.C((e+(1-q))^0) * q 

assert([[a\"b]] == p:match([["a\"b"]]))
assert([[a\\]] == p:match([["a\\"]]))
assert([[xyz\\]] == p:match([["xyz\\"]]))


