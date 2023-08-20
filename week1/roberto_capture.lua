local lpeg = require "lpeg"

function add(a,b)
	return a+b
end

local space = lpeg.S(" \n\t")^0
local numeral = (lpeg.P("-")^-1 * lpeg.R("09")^1) / tonumber * space
local op = lpeg.P("+") * space
local sum = (numeral * op * numeral) / add

print(sum:match("12 + 20"))
print(sum:match("12 + -20"))
