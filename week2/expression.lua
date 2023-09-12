local M = {}

local lpeg = require "lpeg"
local pt = require "pt"
local P,S,R,C,Ct,V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.V

local function number(num)
    return {tag = "number", value = num}
end

local function unary(pair) 
    if #pair == 1 then
        return pair[1]
    else
        return {tag = "unary", op = pair[1], value = pair[2] }
    end
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
-- i = 4                         _________________________________
-- i = 4                        /                                 \
-- tree = { tag = "binop", e1 = { tag = "binop", e1 = n1, e2 = n2 }, e2 = n3 } = tree4
-- tree4 = { tag = "binop", e1 = tree2, e2 = n3 }

local function binary (lst)
    local tree = lst[1]
    for i=2,#lst,2 do
        tree = { tag = "binary", e1 = tree, op = lst[i], e2 = lst[i+1] }
    end
    return tree
end


local ss = S(" \r\n")^0

local opEX  = C(S"^"  ) *ss
local opAD  = C(S"+-" ) *ss
local opML  = C(S"*/%") *ss
local opLE  = C(P"<=" ) *ss
local opLT  = C(P"<"  ) *ss
local opGE  = C(P">=" ) *ss
local opGT  = C(P">"  ) *ss
local opEQ  = C(P"==" ) *ss
local opNE  = C(P"!=" ) *ss
local opUM  = C(P"-"  )
local opCM  = opLE + opLT + opGE + opGT + opEQ + opNE

local base10_integer = R"09"^1 / tonumber * ss
local base16_integer = "0" * S"xX" * R("09","af","AF")^1 / function(x) return tonumber(x,16) end * ss
local base10_float   = (R"09"^1*"."*R"09"^0 + "."*R"09"^1) / tonumber * ss
local numeral = (base10_float + base16_integer + base10_integer) / number
local OP = "(" * ss
local CP = ")" * ss

local factor    = V"factor"
local term      = V"term"
local power     = V"power"
local expr      = V"expr"
local compare   = V"compare"

local function collectAndApply(p,f) return Ct(p) / f end

local grammar = P{ "compare",
    term    = collectAndApply( 
                    factor*(opML*factor)^0,
                    binary),
    factor  = collectAndApply( 
                    opUM^-1*numeral + opUM^-1*(OP*compare*CP),   
                    unary),
    power   = collectAndApply( 
                    term*(opEX*term)^-1,
                    binary),
    expr    = collectAndApply( 
                    power*(opAD*power)^0,                   
                    binary),
    compare = collectAndApply( 
                    expr*(opCM*expr)^-1,                     
                    binary)
}*-1

function M.parse(input)
    return grammar:match(input)
end

local function addCode(state, opcode)
    local code = state.code
    code[#code+1] = opcode
end

local binops = {
    ["+"]  = "add", 
    ["-"]  = "sub", 
    ["*"]  = "mul", 
    ["/"]  = "div",
    ["^"]  = "exp",
    ["%"]  = "rem",
    ["<"]  = "lt",
    ["<="] = "le",
    [">"]  = "gt",
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
    elseif ast.tag == "binary" then
        codeExpr(state, ast.e1)
        codeExpr(state, ast.e2)
        addCode(state, binops[ast.op])
    else 
        print(pt.pt(ast))
        print(pt.pt(state))
        error("Unknown tag")
    end
end

function M.compile(ast)
    print("--------------------")
    print(pt.pt(ast))
    local state = { code = {} }
    codeExpr(state, ast)
    return state.code
end

local function compare(expr)
    if expr then
        return 1
    else 
        return 0
    end
end

local machine_ops = {
    add = function (x,y) return x+y end,
    sub = function (x,y) return x-y end,
    mul = function (x,y) return x*y end,
    div = function (x,y) return x/y end,
    exp = function (x,y) return x^y end,
    rem = function (x,y) return x%y end,
    lt  = function (x,y) return compare(x<y)  end,
    lte = function (x,y) return compare(x<=y) end,
    gt  = function (x,y) return compare(x>y)  end,
    gte = function (x,y) return compare(x>=y) end,
    eq  = function (x,y) return compare(x==y) end,
    ne  = function (x,y) return compare(x~=y) end
}

function M.run(code, stack) 
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

return M
