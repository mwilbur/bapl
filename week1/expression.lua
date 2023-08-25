local lpeg = require "lpeg"
local pt = require "pt"

function fact(n) 
	function factorial1(n, acc)
		if n <= 1 then
			return acc 
		else
			return factorial1(n-1,n*acc)
		end
	end
	return factorial1(n,1)
end


function fold(as)
	acc = as[1]
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
	    elseif as[i] == "!" then
		acc = fact(acc)
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
local opFact = lpeg.C("!") * space
local primary = lpeg.V"primary"
local factorial = lpeg.V"factorial"
local power = lpeg.V"power"
local term = lpeg.V"term"
local expr = lpeg.V"expr"

local g = lpeg.P{"expr",
    primary = numeral + lparen * expr * rparen,
    factorial = lpeg.Ct(primary * opFact^-1) / fold,
    power = lpeg.Ct(factorial * (opE * factorial)^0) / fold,
    term = lpeg.Ct(power * (opM * power)^0) / fold,
    expr = space * lpeg.Ct(term * (opA * term)^0) / fold
} * -1
print(pt.pt(g:match("-2!")))
print(pt.pt(g:match("5!")))
print(pt.pt(g:match("12 + 20 - 3 * -75 / 3")))
print(pt.pt(g:match("3^4*3")))
print(pt.pt(g:match("(1+3)*4")))

