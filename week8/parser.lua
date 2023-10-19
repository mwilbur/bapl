local M = {}

local lpeg = require "lpeg"
local pt = require "pt"
local P,S,R,C,Ct,V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.V

function I(msg)
    return P(function (_,p) io.write(msg,"\n") return true end)
end

local function simpleNode(tag, ...)
    local nodeParams = table.pack(...)
    return function(nodeValues)
        ast = {tag=tag}
        for i,k in ipairs(nodeParams) do
            ast[k] = nodeValues[i]
        end
        return ast
    end
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

local function indexedAst(lst)
    local tree = lst[1]
    for i=2,#lst do
        tree = { tag = "indexed", name = tree, index = lst[i] }
    end
    return tree
end

local function multidimNewAst(lst)
    local tree = { tag = "new", size = lst[#lst] }
    for i = #lst-1,1,-1 do
        tree = { tag = "new", size = lst[i], eltype = tree }
    end 
    return tree
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

local function conditionalAst(params)
    if #params == 0 then
        return
    elseif #params == 1 then
        return params[1]
    else
        -- if the number of parameters is even, there is no "else" clause
        -- if the number of parameters is odd, there is an else clause 
        local top= #params%2 == 0 and #params or #params-1
        local t = { tag="if", cond=params[top-1], th=params[top], el = params[top+1] }
        for n=top-2,1,-2 do
            t = {tag = "if", cond = params[n-1], th = params[n], el = t }
        end
        return t
    end
    
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
    local s = string.sub(src,sourceInfo.characterCount,-1)
    local e = string.find(s,"\n") or #s
    return string.sub(s,1,e-1)
end

function getErrorLineNumber()
    return sourceInfo.lineCount + 1
end

function getErrorLine(src)
    local s = string.sub(src,sourceInfo.fullLineCharacterCount+1,-1)
    local e = string.find(s,"\n") or #s
    return string.sub(s,1,e-1)
end

local updateLineCount = P(function(src,p) updateLineInfo(src,p) return true end)
local updateCharacterCount = P(function(_,p) updateCharInfo(p) return true end)


local block_comment = V"block_comment"
local spaces = V"spaces"


local function reservedWords() 
    local reservedWords = {"return","if","else","for","while","new","function","var"}
    local excluded = P(false)
    for i=1,#reservedWords do
        excluded = excluded + reservedWords[i]
    end
    return excluded
end


local excluded = reservedWords()

local alpha = R("az","AZ")
local alphanum = alpha + R"09"

local comment = "#"*(P(1)-"\n")^0

local base10_integer    = P"-"^-1*R"09"^1 / tonumber * spaces
local base16_integer    = "0" * S"xX" * R("09","af","AF")^1 / function(x) return tonumber(x,16) end * spaces
local base10_float      = (R"09"^1*"."*R"09"^0 + "."*R"09"^1) / tonumber * spaces
local numeral           = Ct(base10_float + base16_integer + base10_integer) / simpleNode("number","value")

local out               = P"@" * spaces 

local factor        = V"factor"
local term          = V"term"
local power         = V"power"
local expr          = V"expr"
local sums          = V"sums"
local statement     = V"statement"
local statements    = V"statements"
local block         = V"block"
local condition     = V"condition"
local conditional   = V"conditional"
local elif          = V"elif"
local lhs           = V"lhs"
local identifier    = V"identifier"
local funcDesc      = V"funcDesc"
local call          = V"call"
local var           = V"var"
local params        = V"params"
local args          = V"args"

local function T(t)
    return P(t)*spaces
end

local function Rw(t) 
    if not excluded:match(t) then error("missing reserved word") end
    return P(t)*-alphanum*spaces
end

local opAD  = (C(S"+-" )+C("and")+C("or"))*spaces
local opML  = C(S"*/%") *spaces
local opCM  = C(T("<=") + T("<") + T(">=") + T(">") + T("==") + T("!="))
local variable          = Ct(identifier) / simpleNode("variable","value") 

local function collectAndApply(p,f) return Ct(p) / f end

local grammar = P{ "prog",
    spaces          = (((S(" \t") + S("\n")*updateLineCount) + block_comment + comment)^0*updateCharacterCount),
    
    identifier = C(P"_"^0*alpha*(alphanum+"'")^0 - excluded)*spaces,

    block_comment   = P("#{")*((block_comment + (1-P("}#")))^0)*P("}#"),

    factor          = collectAndApply( 
        numeral + 
        T("-")*numeral + 
        T("-")^-1*(T("(")*expr*T(")")) +
        T("-")^-1*call +
        T("-")^-1*lhs +
        collectAndApply(Rw("new")*(T("[")*expr*T("]"))^1, multidimNewAst),
        unaryAst),

    term = collectAndApply( 
        factor*(opML*factor)^0,
        binaryAst),

    power = collectAndApply( 
        term*(C(T("^"))*term)^-1,
        binaryAst),

    sums = collectAndApply( 
        power*(opAD*power)^0,                   
        binaryAst),

    lhs  = collectAndApply(variable*(T("[")*expr*T("]"))^0,indexedAst),
    
    call = collectAndApply(identifier*T"("*args*T")",simpleNode("call","fname","args")),
    
    args = Ct((expr * (T"," * expr)^0)^-1),

    expr = collectAndApply( 
        sums*(opCM*sums)^-1,                     
        binaryAst),

    condition = collectAndApply(
        T("!")^-1*expr,
        unaryAst),

    block = collectAndApply( T("{")*statements*T(";")^-1*T("}") + T("{")*T("}"), simpleNode("block","body")),
    
    conditional =  collectAndApply(
                    Rw("if")*condition*block*elif,
                    simpleNode("if","cond","th","el")),
    
    elif  =       collectAndApply(
                    (Rw("elseif")*condition*block)^0 * (Rw("else")*block)^-1, 
                    conditionalAst),
    
    statement = collectAndApply(Rw"var"*identifier*T"="*expr, simpleNode("local","name","init"))+ 
                conditional +
                collectAndApply(Rw("while")*expr*block, simpleNode("while1","cond","block")) +
                block +
                call +
                collectAndApply(
                    lhs*T("=")*expr, 
                    simpleNode("assignment","lhs","value")) +
                collectAndApply(
                    Rw("return")*expr,
                    simpleNode("ret","value")) +
                collectAndApply(
                    out*expr,
                    outAst),

    statements = collectAndApply(
        statement*(T(";")*statements^-1)^-1,
        statementsAst),

    funcDesc = collectAndApply(Rw("function") * identifier * T"(" * params * T")" * (T";" + block), simpleNode("func","name","params","body")),
    
    params = Ct((identifier * (T"," * identifier)^0)^-1),

    prog = spaces*Ct(funcDesc^1)*-1
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
