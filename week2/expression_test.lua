local expr = require "expression"
local pt = require "pt"

local parse,compile,run = expr.parse, expr.compile, expr.run

local input = io.read("*a")
local ast = parse(input)
print(pt.pt(ast))
local code = compile(ast)
print(pt.pt(code))
stack = {}
run(code, stack)
print(pt.pt(stack[1]))
