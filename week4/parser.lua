local M = {}

local lpeg = require "lpeg"
local pt = require "pt"
local P,S,R,C,Ct,V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.V

function I(msg)
    return P(function (_,p) io.write(msg,"\n") return true end)
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
    print(pt.pt(lst))
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

local sourceInfo = {
    lineCount = 0,
    charactersPerLine = {},
    characterCount = 0,
    fullLineCharacterCount = 0,
}

function updateLineInfo(src,p) 
    sourceInfo.lineCount = sourceInfo.lineCount + 1 
    lastCount = sourceInfo.charactersPerLine[sourceInfo.lineCount-1] or 0
    newCount = p - lastCount - 1
    sourceInfo.charactersPerLine[sourceInfo.lineCount] = newCount
    sourceInfo.fullLineCharacterCount = sourceInfo.fullLineCharacterCount + newCount
end

function updateCharInfo(p)
    sourceInfo.characterCount = math.max(sourceInfo.characterCount,p)
end


function getTextMatchedSoFar(src)
    return string.sub(src,1,sourceInfo.characterCount-1)
end

function getTextAfterError(src)
    s = string.sub(src,sourceInfo.characterCount,-1)
    e = string.find(s,"\n")
    return string.sub(s,1,e-1)
end

function getErrorLineNumber()
    return sourceInfo.lineCount + 1
end

function getErrorLine(src)
    s = string.sub(src,sourceInfo.fullLineCharacterCount+1,-1)
    e = string.find(s,"\n")
    return string.sub(s,1,e-1)
end

local updateLineCount = P(function(src,p) updateLineInfo(src,p) return true end)
local updateCharacterCount = P(function(_,p) updateCharInfo(p) return true end)


local block_comment = V"block_comment"
local spaces = V"spaces"


local function reservedWords() 
    local reservedWords = {"return","if","for","while"}
    local excluded = P(false)
    for i=1,#reservedWords do
        excluded = excluded + reservedWords[i]
    end
    return excluded
end


local alpha = R("az","AZ")
local alphanum = alpha + R"09"
local identifier = C(P"_"^0*alpha*(alphanum+"'")^0 - reservedWords())*spaces
local comment = "#"*(P(1)-"\n")^0

local base10_integer    = P"-"^-1*R"09"^1 / tonumber * spaces
local base16_integer    = "0" * S"xX" * R("09","af","AF")^1 / function(x) return tonumber(x,16) end * spaces
local base10_float      = (R"09"^1*"."*R"09"^0 + "."*R"09"^1) / tonumber * spaces
local numeral           = (base10_float + base16_integer + base10_integer) / numberAst
local variable          = identifier / variableAst 
local out               = P"@" * spaces 

local factor        = V"factor"
local term          = V"term"
local power         = V"power"
local expr          = V"expr"
local sums          = V"sums"
local statement     = V"statement"
local statements    = V"statements"
local block         = V"block"
local test          = V"test"

local function T(t)
    return P(t)*spaces
end

local function Rw(t) 
    return P(t)*-alphanum*spaces
end

local opAD  = C(S"+-" ) *spaces
local opML  = C(S"*/%") *spaces
local opCM  = C(T("<=") + T("<") + T(">=") + T(">") + T("==") + T("!="))


local function collectAndApply(p,f) return Ct(p) / f end

local grammar = P{ "prog",
    spaces          = (((S(" \t") + S("\n")*updateLineCount) + block_comment + comment)^0*updateCharacterCount),

    block_comment   = P("#{")*((block_comment + (1-P("}#")))^0)*P("}#"),

    factor          = collectAndApply( 
                        numeral + 
                            T("-")*numeral + 
                            T("-")^-1*(T("(")*expr*T(")")) + 
                            T("-")^-1*variable,
                        unaryAst),

    term            = collectAndApply( 
                        factor*(opML*factor)^0,
                        binaryAst),

    power           = collectAndApply( 
                        term*(C(T("^"))*term)^-1,
                        binaryAst),

    sums            = collectAndApply( 
                        power*(opAD*power)^0,                   
                        binaryAst),

    expr            = collectAndApply( 
                        sums*(opCM*sums)^-1,                     
                        binaryAst),

    block           = T("{")*statements*T(";")^-1*T("}") + T("{")*T("}"),

    statement       = block + 
                      collectAndApply(
                          identifier*T("=")*expr, 
                          assignmentAst) +
                      collectAndApply(
                          Rw("return")*expr,
                          returnAst) +
                      collectAndApply(
                          out*expr,
                          outAst),

    statements      = collectAndApply(
                        statement*(T(";")*statements^-1)^-1,
                        statementsAst),

    prog            =   spaces*statements*-1
}

function M.parse(input)
    res = grammar:match(input)
    if not res then 
        print("Syntax error detected at '|' mark:")
        print("---")
        io.write(getTextMatchedSoFar(input))
        io.write("|")
        io.write(getTextAfterError(input))
        io.write("\n")
        print("---")
        print("Number of characters before error: "..tostring(sourceInfo.characterCount-1))
        print("Error line number: "..tostring(getErrorLineNumber()))
        print("Error line: "..getErrorLine(input))
        os.exit(1)
    end
    return res
end

return M
