local M = {}
pt=require"pt"
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

local Compiler = { funcs = {}, vars = {}, nvars = 0 }

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

function Compiler:codeCall(ast) 
    local func = self.funcs[ast.fname]
    if not func then
        error("Undefined function" .. ast.fname)
    end
    self:addCode("call")
    self:addCode(func.code)
end
    
function Compiler:codeExpr(ast) 
    if ast.tag == "number" then
        self:addCode("push")
        self:addCode(ast.value)
    elseif ast.tag == "variable" then
        self:addCode("load")
        local var = self:declareVar(ast.value)
        if not var then error("Undeclared variable "..ast.value) end
        self:addCode(var)
    elseif ast.tag == "call" then
        self:codeCall(ast)
    elseif ast.tag == "indexed" then
        self:codeExpr(ast.name)
        self:codeExpr(ast.index)
        self:addCode("getarray")
    elseif ast.tag == "new" then
        self:codeExpr(ast.size)
        self:addCode("newarray") 
        -- multi-dimensional new loop
        if ast.eltype ~= nil then
            -- loop counter used to fill new array
            self:codeExpr(ast.size)
            self:addCode("jmpzp")
            self:addCode(0)
            local l1 = self:getCurrentLocation()
            -- steal from FORTH -- duplicate destination array
            -- and next index in that array at which to store 
            self:addCode("2dup")
            -- create the next level of table which
            -- will be used to set all the elements
            -- of the newly created array above
            self:codeExpr(ast.eltype)
            self:addCode("setarray")
            self:addCode("dec")
            self:addCode("jmp")
            self:addCode(l1-self:getCurrentLocation()-3)
            self:fixupJmp(l1)
            -- cleanup loop counter and array value
            self:addCode("pop")
        end
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

function Compiler:codeAssign(ast)
    local lhs = ast.lhs
    if lhs.tag == "variable" then
        self:codeExpr(ast.value)
        self:addCode("store")
        self:addCode(self:declareVar(lhs.value))
    elseif lhs.tag == "indexed" then
        self:codeExpr(lhs.name)
        self:codeExpr(lhs.index)
        self:codeExpr(ast.value)
        self:addCode("setarray")
    end
end

function Compiler:codeBlock(ast)
    if ast.body then
        self:codeStat(ast.body)
    end
end

function Compiler:codeStat(ast) 
    if ast.tag == "assignment" then
        self:codeAssign(ast)
    elseif ast.tag == "block" then
        self:codeBlock(ast)
    elseif ast.tag == "statements" then
        self:codeStat(ast.s1)
        self:codeStat(ast.s2)
    elseif ast.tag == "out" then
        self:codeExpr(ast.value)
        self:addCode("out")
    elseif ast.tag == "ret" then
        self:codeExpr(ast.value)
        self:addCode("ret")
    elseif ast.tag == "call" then
        self:codeCall(ast)
        self:addCode("pop")
        self:addCode(1)
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

function Compiler:codeFunc(ast)
    -- check to see if the function has already been defined
    -- could probably be more careful here...forward declared functions
    -- exist in our table self.funcs but the code table is empty and waiting
    -- to be filled
        
    -- this way, other functions that referred to it will automatically 
    -- get the proper definition via the table reference
    local code = self.funcs[ast.name] and self.funcs[ast.name].code or {}
    self.funcs[ast.name] = { code = code }
    self.code = code
    
    -- a nil body means a forward declaration to be filled in later
    if ast.body then
        self:codeStat(ast.body)
        Compiler:addCode("push")
        Compiler:addCode(0)
        Compiler:addCode("ret")
    end
end

function M.compile(ast)
    for i=1,#ast do
        Compiler:codeFunc(ast[i])
    end
    local main = Compiler.funcs["main"]
    if not main then
        error("Missing 'main' function")
    end
    return main.code
end

return M
