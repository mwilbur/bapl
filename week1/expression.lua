local lpeg = require "lpeg"
local pt = require "pt"
function fold(as)
	local acc = as[1]
	for i = 2,#as,2 do
	    if as[i] == "+" then
		acc = acc + as[i+1]
	    elseif as[i] == "-" then 
		acc = acc - as[i+1]
	    elseif as[i] == "*" then 
		acc = acc * as[i+1]
	    elseif as[i] == "/" then 
		acc = acc / as[i+1]
	    elseif as[i] == "^" then 
		acc = acc ^ as[i+1]
	    else
		error("Uknown operator")
	    end
	end
	return acc
end

local space = lpeg.S(" \n\t")^0
local numeral = (lpeg.P("-")^-1 * lpeg.R("09")^1) / tonumber * space
local lparen = "(" * space
local rparen = ")" * space
local opA = lpeg.C(lpeg.S("+-")) * space
local opM = lpeg.C(lpeg.S("*/%")) * space
local opE = lpeg.C("^") * space

local primary = lpeg.V"primary"
local power = lpeg.V"power"
local term = lpeg.V"term"
local expr = lpeg.V"expr"

local g = lpeg.P{"expr",
    primary = numeral + lparen * expr * rparen,
    power = lpeg.Ct(primary * (opE * primary)^0) / fold,
    term = lpeg.Ct(power * (opM * power)^0) / fold,
    expr = space * lpeg.Ct(term * (opA * term)^0) / fold
} * -1

print(pt.pt(g:match("12 + 20 - 3 * -75 / 3")))
print(pt.pt(g:match("2^4*3")))
print(pt.pt(g:match("(1+3)*4")))

