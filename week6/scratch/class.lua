local lpeg = require"lpeg"

lpeg.locale(lpeg)


local keywords = {"if", "elseif", "else", "end"}

local alnum = lpeg.alnum^1

local keyword = lpeg.P(false)

for _, kw in ipairs(keywords) do

  keyword = keyword + kw

end

keyword = keyword * -(lpeg.P";" + alnum)


-- make these assertions to pass

assert(lpeg.match(keyword, "else") == 5)

assert(lpeg.match(keyword, "elseif") == 7)

assert(lpeg.match(keyword, "else1") == nil)

assert(lpeg.match(keyword, "else;") == nil)