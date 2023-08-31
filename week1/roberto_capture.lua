local lpeg = require "lpeg"
function add(as)
	local sum = 0
	for _,a in ipairs(as) do
		sum = sum + a
	end
	return sum
end

local space = lpeg.S(" \n\t")^0
local numeral = lpeg.R("09")^1 / tonumber * space
local op = lpeg.P("+") * space
local sum = space * lpeg.Ct(numeral * (op * numeral)^0) * -1


print(sum:match("12 + 20 + 3"))
