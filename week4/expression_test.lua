do
    local expr = require "expression"
    local pt = require "pt"

    local parse,compile,run = expr.parse, expr.compile, expr.run

    local input = io.read("a")
    --local input = "a =  1 "
    local ast = expr.parse(input)
    print(pt.pt(ast))
    --[[
    local code = compile(ast)
    print(pt.pt(code))
    --store = {k1 = 1, k2 = 2, k10 = 10, __q=15, ["k'"]=32}
    store = {}
    stack = {}
    vmio = {
        out = function(v) io.write(">>>>>>",v,"\n") end
    }
    local function mytrace(pc,tos,code,stack,store) 
        print(string.format("====[pc=%d]==[tos=%d]====",pc,tos))
        print("code: ")
        print(pt.pt(code))
        print("stack: ")
        print(pt.pt(stack))
        print("store: ")
        print(pt.pt(store))
    end
    --mytrace = function(...) t={...} print(pt.pt(t[#t-1])) end
    mytrace = function(...) end 
    run(code, store, vmio, stack, mytrace)
    --run(code, store, stack)
    print(pt.pt(stack))
    print(pt.pt(store))
    --]]
end
--[[
--]]
