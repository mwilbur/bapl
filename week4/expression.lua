local M = {}

local lpeg = require "lpeg"
local pt = require "pt"
local P,S,R,C,Ct,V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.V

function M.I(msg)
    return P(function (_,p) print(msg.." "..tostring(p)) return true end)
end

local function numberAst(num)
    return {tag = "number", value = num}
end

local function unaryAst(pair) 
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
-- i = 4                        /---------------------------------\
-- tree = { tag = "binop", e1 = { tag = "biCop", e1 = n1, e2 = n2 }, e2 = n3 } = tree4
-- tree4 = { tag = "binop", e1 = tree2, e2 = n3 }

local function binaryAst(lst)
    local tree = lst[1]
    for i=2,#lst,2 do
        tree = { tag = "binary", e1 = tree, op = lst[i], e2 = lst[i+1] }
    end
    return tree
end

local function variableAst(var) 
    return {tag = "variable", value = var}
end

local function assignmentAst(assignment)
    return {tag = "assignment", name = assignment[1], value = assignment[2]}
end

local function statementsAst(statements)
    if statements[1]== nil and statements[2]==nil then
        return {}
    elseif statements[2]==nil then
        return statements[1]
    else
        return {tag = "statements", s1 = statements[1], s2 = statements[2]}
    end
end

local function returnAst(retExpr) 
    return {tag = "ret", value=retExpr[1]}
end

local function outAst(outExpr) 
    return {tag = "out", value=outExpr[1]}
end

local function decodeVar(state, id)
    return state.vars[id]
end

local function declareVar(state,id)
    local num = decodeVar(state,id)
    if not num then
        num = state.nvars + 1
        state.nvars = num
        state.vars[id] = num
    end
    return num
end

local sourceInfo = {
    data = {
        lineCount = 0,
        charactersPerLine = {},
        characterCount = 0,
        fullLineCharacterCount = 0,
    }
}

function sourceInfo:updateLineInfo(src,p) 
    self.data.lineCount = self.data.lineCount + 1 
    lastCount = self.data.charactersPerLine[self.data.lineCount-1] or 0
    newCount = p - lastCount - 1
    self.data.charactersPerLine[self.data.lineCount] = newCount
    self.data.fullLineCharacterCount = self.data.fullLineCharacterCount + lastCount
end

function sourceInfo:updateCharInfo(p)
    self.data.characterCount = math.max(self.data.characterCount,p)
end

function sourceInfo:lastLineSpan()
    return self.data.fullLineCharacterCount+1, self.data.characterCount-1
end
--[[
function sourceInfo:getErrorLocation()
    sourceInfo.lineCount, 
    sourceInfo.charactersPerLine[sourceInfo.lineCount]))
--]]
local updateLineCount = P(function(src,p) sourceInfo:updateLineInfo(src,p) return true end)
local updateCharacterCount = P(function(_,p) sourceInfo:updateCharInfo(p) return true end)

local ss = ((S(" \t") + S("\n")*updateLineCount)^0*updateCharacterCount)

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

local alpha = R("az","AZ")
local alphanum = alpha + R"09"
local identifier = C(P"_"^0*alpha*(alphanum+"'")^0)*ss

local base10_integer    = P"-"^-1*R"09"^1 / tonumber * ss
local base16_integer    = "0" * S"xX" * R("09","af","AF")^1 / function(x) return tonumber(x,16) end * ss
local base10_float      = (R"09"^1*"."*R"09"^0 + "."*R"09"^1) / tonumber * ss
local numeral           = (base10_float + base16_integer + base10_integer) / numberAst
local variable          = identifier / variableAst 
local ret               = P"return" * ss
local out               = P"@" * ss 
local OP = "(" * ss
local CP = ")" * ss
local OB = "{" * ss
local CB = "}" * ss
local SC = P(";") * ss
local assign = "=" * ss

local factor        = V"factor"
local term          = V"term"
local power         = V"power"
local expr          = V"expr"
local sums          = V"sums"
local statement     = V"statement"
local statements    = V"statements"
local block         = V"block"
local test          = V"test"

local function collectAndApply(p,f) return Ct(p) / f end

local grammar = P{ "statements",
    factor      = collectAndApply( 
                    numeral + opUM*numeral + opUM^-1*(OP*expr*CP) + opUM^-1*variable,
                    unaryAst),
    term        = collectAndApply( 
                    factor*(opML*factor)^0,
                    binaryAst),
    power       = collectAndApply( 
                    term*(opEX*term)^-1,
                    binaryAst),
    sums        = collectAndApply( 
                    power*(opAD*power)^0,                   
                    binaryAst),
    expr        = collectAndApply( 
                    sums*(opCM*sums)^-1,                     
                    binaryAst),
    block       = OB*statements*SC^-1*CB + OB*CB,
    statement   = block + 
                  collectAndApply(
                      identifier*assign*expr, 
                      assignmentAst) +
                  collectAndApply(
                      ret*expr,
                      returnAst) +
                  collectAndApply(
                      out*expr,
                      outAst),
    statements  = collectAndApply(
                    statement*(SC*statements^-1)^-1,
                    statementsAst),
}

grammar = ss*grammar*-1


function M.parse(input)
    res = grammar:match(input)
    if not res then 
        --[[
        io.stderr:write(string.format("Error on line %d, character %d\n", 
                        sourceInfo.lineCount, 
                        sourceInfo.charactersPerLine[sourceInfo.lineCount]))
        --]]
        print(sourceInfo.data.characterCount-1)
        lines = 1
        s=string.sub(input,1,sourceInfo.data.characterCount-1)
        print("---")
        print(s)
        print("---")
        for _ in string.gmatch(s,"\n") do
            lines = lines+1
        end
        print(lines)
        print(pt.pt(sourceInfo.data))
        --print(string.sub(input,sourceInfo:lastLineSpan()))
        os.exit(1)
    end
    return res
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
    elseif ast.tag == "variable" then
        addCode(state, "load")
        local var = decodeVar(state,ast.value)
        if not var then error("Undeclared variable "..ast.value) end
        addCode(state, var)
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

local function codeStat(state, ast) 
    if ast.tag == "assignment" then
        codeExpr(state, ast.value)
        addCode(state, "store")
        addCode(state, declareVar(state,ast.name))
    elseif ast.tag == "statements" then
        codeStat(state, ast.s1)
        codeStat(state, ast.s2)
    elseif ast.tag == "out" then
        codeExpr(state, ast.value)
        addCode(state, "out")
    elseif ast.tag == "ret" then
        codeExpr(state, ast.value)
        addCode(state, "ret")
    end
end

function M.compile(ast)
    local state = { code = {}, vars = {}, nvars = 0 }
    codeStat(state, ast)
    addCode(state, "push")
    addCode(state, 0)
    addCode(state, "ret")
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

function M.run(code,store,io,stack,tracefunc) 
    local tracefunc = tracefunc or function(...) end 
    local pc = 1
    local top = 0
    tracefunc(pc,top,code,stack,store)
    while true do
        if code[pc] == "ret" then
            break
        elseif code[pc] == "out" then
            io.out(stack[top])
            top = top - 1
            stack[top+1] = nil
        elseif code[pc]=="push" then
            pc = pc + 1
            top = top + 1
            stack[top] = code[pc]
        elseif code[pc]=="load" then
            pc = pc + 1
            top = top + 1
            local id = code[pc]
            stack[top] = store[id]
        elseif code[pc]=="store" then
            pc = pc + 1
            local id = code[pc]
            store[id] = stack[top]
            top = top - 1
            stack[top+1] = nil
        elseif code[pc]=="neg" then
            stack[top] = -1*stack[top]
        else 
            f = machine_ops[code[pc]] or error("unkown op")
            result = f(stack[top-1],stack[top])
            top = top - 1
            stack[top] = result
            stack[top+1] = nil
        end
        pc = pc + 1
        tracefunc(pc,top,code,stack,store)
    end
end

return M
