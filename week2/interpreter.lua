local lpeg = require "lpeg"
local pt = require "pt"

local function node(num)
	return {tag = "number", value = num}
end

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

local function foldBin(lst)
	local tree = lst[1]
	for i=2,#lst,2 do
		tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i+1] }
	end
	return tree
end

local spaces = lpeg.S(" \r\n")^0
local base10_numeral = lpeg.R("09")^1 / tonumber * spaces
local base16_numeral = "0" * lpeg.S("xX") * (lpeg.R("09","af","AF")^1 / function(x) return tonumber(x,16) end) * spaces
local numeral = (base16_numeral + base10_numeral)/node
local opA = lpeg.C(lpeg.S("+-")) * spaces
local expr = lpeg.Ct(numeral * ( opA * numeral)^0)  / foldBin

local function parse(input)
	return expr:match(input)
end

local function addCode(state, opcode)
	local code = state.code
	code[#code+1] = opcode
end

local ops = {["+"] = "add", ["-"] = "sub"}

local function codeExpr(state, ast) 
	if ast.tag == "number" then
		addCode(state, "push")
		addCode(state, ast.value)
	elseif ast.tag == "binop" then
		codeExpr(state, ast.e1)
		codeExpr(state, ast.e2)
		addCode(state, ops[ast.op])
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

local function run(code, stack) 
	local pc = 1
	local top = 0
	while pc <= #code do
		if code[pc]=="push" then
			top = top + 1
			pc = pc + 1
			stack[top] = code[pc]
		elseif code[pc]=="add" then
			result = stack[top-1] + stack[top]
			top = top - 1
			stack[top] = result
		elseif code[pc]=='sub' then
			result = stack[top-1] - stack[top]
			top = top - 1
			stack[top] = result
		else 
			error("unknown instruction")
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

