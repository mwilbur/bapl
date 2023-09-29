lpeg = require"lpeg"

function literal(l)
  return lpeg.P(function(src,p)
      if string.sub(src,p,#l+p) == l then
        return p+#l
      else 
        return false 
      end
    end)
end


reserved = lpeg.P(function(src,p) 
    local reserved_words = { "return", "if", "then" }
    for _,w in ipairs(reserved_words) do
      if string.match(src,w,p-#w) then 
        return true
      else
        return false
      end
    end
  end
) 


alpha = lpeg.R("az","AZ")+lpeg.P("_")
number = lpeg.R("09")
alphanumeric = alpha + number
identifier = alpha * alphanumeric^0 * -reserved

assert(identifier:match("return1"))
assert(not identifier:match("return"))

