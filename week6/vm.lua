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

function M.run(code,store,io,stack,tracefunc) 
    local tracefunc = tracefunc or function(...) end 
    local pc = 1
    local top = 0
    tracefunc(pc,top,code,stack,store)
    while true do
        op = code[pc]
        if op == "ret" then
            break
        elseif code[pc] == "out" then
            io.out(stack[top])
            top = top - 1
            stack[top+1] = nil
        elseif op=="push" then
            pc = pc + 1
            top = top + 1
            stack[top] = code[pc]
        elseif op=="pop" then
            stack[top] = nil
            top = top - 1
        elseif op=="load" then
            pc = pc + 1
            top = top + 1
            local id = code[pc]
            stack[top] = store[id]
        elseif op=="store" then
            pc = pc + 1
            local id = code[pc]
            store[id] = stack[top]
            top = top - 1
            stack[top+1] = nil
        elseif op=="neg" then
            stack[top] = -1*stack[top]
        elseif op=="jmp" then
            pc=pc+1
            pc= pc + code[pc]
        elseif op=="jmpz" or op=="jmpzp" or op=="jmpnzp" then
            pc=pc+1
            local tos = stack[top]
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
              top = top - 1
            end
            
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
