local M = {}

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
    le  = function (x,y) return compare(x<=y) end,
    gt  = function (x,y) return compare(x>y)  end,
    ge  = function (x,y) return compare(x>=y) end,
    eq  = function (x,y) return compare(x==y) end,
    ne  = function (x,y) return compare(x~=y) end
}


local Stack = {}
M.Stack = Stack
function Stack:new() 
    local t= { top = 0, data = {} }
    self.__index = self
    setmetatable(t, self)
    return t
end 

function Stack:push(...)
    local vals = table.pack(...)
    for i = 1,vals.n do
        self.top=self.top+1
        self.data[self.top]=vals[i]
    end
end

function Stack:pop(n)
    n = n or 1
    local t = {}
    for i = n,1,-1 do
        t[i]=self.data[self.top]
        self.data[self.top]=nil
        self.top=self.top-1
    end
    return table.unpack(t)
end

function Stack:peek(n,loc)
    n = n or 1
    loc = loc or 0
    local _t = {}
    for i = 1,n do
        _t[n-(i-1)] = self.data[self.top-(i-1)]
    end
    return table.unpack(_t)
end

function M.run(code,store,stack,io,tracefunc) 
    tracefunc = tracefunc or function(...) end 
    local pc = 1
    while true do
        tracefunc(pc,stack.top,code,stack.data,store)
        op = code[pc]
        if op == "ret" then
            break
        elseif op == "call" then
            pc = pc + 1
            local code = code[pc]
            M.run(code,store,stack,io,tracefunc)
        elseif code[pc] == "out" then
            io.out(stack:pop())
        elseif op=="push" then
            pc = pc + 1
            stack:push(code[pc])
        elseif op=="pop" then
            pc=pc+1
            stack:pop(code[pc])
        elseif op=="dup" then
            stack:push(stack:peek())      
        elseif op=="2dup" then
            stack:push(stack:peek(2))  
        elseif op=="swp" then
            local a,b= stack:pop(2)
            stack:push(b,a)
        elseif op=="dec" then
            stack:push(stack:pop()-1)
        elseif op=="load" then
            pc = pc + 1
            local id = code[pc]
            stack:push(store[id])
        elseif op=="store" then
            pc = pc + 1
            local id = code[pc]
            store[id] = stack:pop()
        elseif op=="newarray" then
            size = stack:pop()
            stack:push({ size = size })
        elseif op=="setarray" then
            local tbl, index, value = stack:pop(3)
            assert(index <= tbl.size, "array index out of bounds!") 
            tbl[index] = value
        elseif op=="getarray" then
            local tbl, index = stack:pop(2)
            assert(index <= tbl.size, "array index out of bounds!") 
            stack:push(tbl[index])
        elseif op=="neg" then
            -- bit inefficient, could optimize this case?
            local v = stack:pop()
            stack:push(-1*v)
        elseif op=="jmp" then
            pc=pc+1
            pc= pc + code[pc]
        elseif op=="jmpz" or op=="jmpzp" or op=="jmpnzp" then
            pc=pc+1
            local tos = stack:peek()
            if op=="jmpnzp" then
                if tos~=0 then
                    pc=pc + code[pc]
                end
            else
                if tos==0 then
                    pc=pc + code[pc]
                end
            end
            if op=="jmpz" then
                stack:pop()
            end
        else 
            f = machine_ops[code[pc]] or error("unkown op")
            a,b=stack:pop(2)
            stack:push(f(a,b))
        end
        pc = pc + 1
        tracefunc(pc,stack.top,code,stack.data,store)
    end
end

return M
