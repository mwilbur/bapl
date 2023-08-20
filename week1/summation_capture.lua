lpeg = require "lpeg"

space = lpeg.S(" \n\t")^1

-- a numeral is an optional '-' followed by 1 or more digits
numeral = lpeg.P("-")^-1 * lpeg.R("09")^1

numeral_surrounded_with_spaces = 
	lpeg.P(" ")^0 * lpeg.C(numeral) * lpeg.P(" ")^0

p1 = numeral_surrounded_with_spaces * 
	(lpeg.Cp() * lpeg.P("+") * numeral_surrounded_with_spaces)^0 * -1

