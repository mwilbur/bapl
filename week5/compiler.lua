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
    ["!"] = "not"
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

function Compiler:getCurrentLocation()
    return #self.code
end

function Compiler:fixupJmp(jmpAddr)
    self.code[jmpAddr] = self:getCurrentLocation()-jmpAddr
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
        if ast.op == "and" or ast.op == "or" then
          -- for short circuit evaluation we want the arguments pushed
          -- on the stack in reverse order
          self:codeExpr(ast.e2)
          self:codeExpr(ast.e1)
          if ast.op == "and" then
            self:addCode("jmpzp") 
          elseif ast.op == "or" then
            self:addCode("jmpnzp")
          end
            self:addCode(0)
            l1=self:getCurrentLocation()
            self:addCode("pop")
            self:fixupJmp(l1)
        else
          self:codeExpr(ast.e1)
          self:codeExpr(ast.e2)
          self:addCode(binops[ast.op])
        end
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
    elseif ast.tag == "while1" then
        local l1 = self:getCurrentLocation()
        self:codeExpr(ast.cond)
        self:addCode("jmpz")
        self:addCode(0)
        local l2 = self:getCurrentLocation()
        self:codeStat(ast.block)
        self:addCode("jmp")
        self:addCode(l1-self:getCurrentLocation()-1)
        self:fixupJmp(l2)
    elseif ast.tag == "if" then
        self:codeExpr(ast.cond)
        self:addCode("jmpz")
        self:addCode(0)
        local jmpz = self:getCurrentLocation()
        self:codeStat(ast.th)
        if ast.el then
            self:addCode("jmp")
            self:addCode(0)
            local jmp = self:getCurrentLocation()
            self:fixupJmp(jmpz)        
            self:codeStat(ast.el)
            self:fixupJmp(jmp)
        else
            self:fixupJmp(jmpz)
        end
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
