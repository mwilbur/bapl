local lpeg = require "lpeg"
local pt = require "pt"


-- take a list {n1, "+", n2, "+", n3, ...} to a tree
-- { ... { op = "+", e1 = { op = "+", e1 = n1, e2 = n2 } e2 = n3 } ... }

-- Initialize:
--
-- tree = n1
-- i = 2
-- tree = { tag = "binop", e1 = n1, e2 = n2 } = tree2
--        `---------------------------------'
--                       |
--                       +----------------------+
--                                              | 
--                                              v 
-- i = 4                        /---------------------------------\
-- tree = { tag = "binop", e1 = { tag = "binop", e1 = n1, e2 = n2 }, e2 = n3 } = tree4
-- tree4 = { tag = "binop", e1 = tree2, e2 = n3 }

local function foldBin (lst)
	local tree = lst[1]
	for i=2,#lst,2 do
		tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i+1] }
	end
	return tree
end

local function node(num)
	return {tag = "number", value = num}
end

local function unary(pair) 
	if #pair == 1 then
		return pair[1]
	else
		return {tag = "unary", op = pair[1], value = pair[2] }
	end
end

local function folded(p,f) 
	return lpeg.Ct(p) / f
end

local spaces = lpeg.S(" \r\n")^0
local base10_numeral = lpeg.R("09")^1 / tonumber * spaces
local base16_numeral = "0" * lpeg.S("xX") * (lpeg.R("09","af","AF")^1 / function(x) return tonumber(x,16) end) * spaces
local numeral = (base16_numeral + base10_numeral)/node
local opE = lpeg.C(lpeg.S("^")) * spaces 
local opA = lpeg.C(lpeg.S("+-")) * spaces
local opM = lpeg.C(lpeg.S("*/%")) * spaces
local opLTE = lpeg.C(lpeg.P("<=")) * spaces
local opLT = lpeg.C(lpeg.P("<")) * spaces
local opGTE = lpeg.C(lpeg.P(">=")) * spaces
local opGT = lpeg.C(lpeg.P(">")) * spaces
local opEQ = lpeg.C(lpeg.P("==")) * spaces
local opNE = lpeg.C(lpeg.P("!=")) * spaces
local opC = opLTE + opGTE + opLT + opLTE + opEQ + opNE
local OP = "(" * spaces
local CP = ")" * spaces
local minus = lpeg.C(lpeg.P("-"))


local factor = lpeg.V"factor"
local term = lpeg.V"term"
local power = lpeg.V"power"
local expr = lpeg.V"expr"
local compare = lpeg.V"compare"

local grammar = lpeg.P{ "compare",
	term = folded(factor * ( opM * factor)^0,foldBin),
	factor = folded((minus^-1)*numeral + (minus^-1)*(OP * compare * CP), unary),
	power = folded(term * (opE * term)^-1,foldBin),
	expr = folded(power * ( opA * power)^0,foldBin),
	compare = folded(expr * (opC * expr)^-1,foldBin)
} * -1

local function parse(input)
	return grammar:match(input)
end

local function addCode(state, opcode)
	local code = state.code
	code[#code+1] = opcode
end

local binops = {
	["+"] = "add", 
	["-"] = "sub", 
	["*"] = "mul", 
	["/"] = "div",
	["^"] = "exp",
	["%"] = "rem",
	["<"] = "lt",
	["<="] = "le",
	[">"] = "gt",
	[">="] = "ge",
	["=="] = "eq",
	["!="] = "ne",
}

local unaryops = {
	["-"] = "neg", 
}

local function codeExpr(state, ast) 
	if ast.tag == "number" then
		addCode(state, "push")
		addCode(state, ast.value)
	elseif ast.tag == "unary" then
		codeExpr(state, ast.value)
		addCode(state, unaryops[ast.op])
	elseif ast.tag == "binop" then
		codeExpr(state, ast.e1)
		codeExpr(state, ast.e2)
		addCode(state, binops[ast.op])
	else 
		print(pt.pt(ast))
		print(pt.pt(state))
		error("Unknown tag")
	end
end

local function compile(ast)
	local state = { code = {} }
	codeExpr(state, ast)
	return state.code
end

local machine_ops = {
	add = function (x,y) return x+y end,
	sub = function (x,y) return x-y end,
	mul = function (x,y) return x*y end,
	div = function (x,y) return x/y end,
	exp = function (x,y) return x^y end,
	rem = function (x,y) return x%y end,
	lt = function (x,y) if x<y then return 1 else return 0 end end,
	lte = function (x,y) if x<=y then return 1 else return 0 end end,
	gt = function (x,y) if x>y then return 1 else return 0 end end,
	gte = function (x,y) if x>=y then return 1 else return 0 end end,
	eq = function (x,y) if x==y then return 1 else return 0 end end,
	ne = function (x,y) if x~=y then return 1 else return 0 end end,
}

local function run(code, stack) 
	local pc = 1
	local top = 0
	while pc <= #code do
		if code[pc]=="push" then
			top = top + 1
			pc = pc + 1
			stack[top] = code[pc]
		elseif code[pc]=="neg" then
			stack[top] = -1*stack[top]
		else 
			f = machine_ops[code[pc]] or error("unkown op")
			result = f(stack[top-1],stack[top])
			top = top - 1
			stack[top] = result
		end
		pc = pc + 1
	end
end
local input = io.read("*a")
local ast = parse(input)
print(pt.pt(ast))
local code = compile(ast)
print(pt.pt(code))
stack = {}
run(code, stack)
print(pt.pt(stack[1]))
