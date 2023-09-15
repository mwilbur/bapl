local M = {}

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

local Compiler = { code = {}, vars = {}, nvars = 0 }

function Compiler:addCode(opcode)
    local code = self.code
    code[#code+1] = opcode
end

function Compiler:decodeVar(id)
    return self.vars[id]
end

function Compiler:declareVar(id)
    local num = self:decodeVar(id)
    if not num then
        num = self.nvars + 1
        self.nvars = num
        self.vars[id] = num
    end
    return num
end

function Compiler:codeExpr(ast) 
    if ast.tag == "number" then
        self:addCode("push")
        self:addCode(ast.value)
    elseif ast.tag == "variable" then
        self:addCode("load")
        local var = self:decodeVar(ast.value)
        if not var then error("Undeclared variable "..ast.value) end
        self:addCode(var)
    elseif ast.tag == "unary" then
        self:codeExpr(ast.value)
        self:addCode(unaryops[ast.op])
    elseif ast.tag == "binary" then
        self:codeExpr(ast.e1)
        self:codeExpr(ast.e2)
        self:addCode(binops[ast.op])
    else 
        print(pt.pt(ast))
        print(pt.pt(state))
        error("Unknown tag")
    end
end

function Compiler:codeStat(ast) 
    if ast.tag == "assignment" then
        self:codeExpr(ast.value)
        self:addCode("store")
        self:addCode(self:declareVar(ast.name))
    elseif ast.tag == "statements" then
        self:codeStat(ast.s1)
        self:codeStat(ast.s2)
    elseif ast.tag == "out" then
        self:codeExpr(ast.value)
        self:addCode("out")
    elseif ast.tag == "ret" then
        self:codeExpr(ast.value)
        self:addCode("ret")
    end
end

function M.compile(ast)
    Compiler:codeStat(ast)
    Compiler:addCode("push")
    Compiler:addCode(0)
    Compiler:addCode("ret")
    return Compiler.code
end

return M
