do
    local parser = require "parser"
    local compiler = require "compiler"
    local vm = require "vm"
    local pt = require "pt"

    local parse,compile,run = parser.parse, compiler.compile, vm.run

    local input = io.open("test_files/test12.txt"):read("a")
    --local input = "a =  1 "
    local ast = parse(input)
    print(pt.pt(ast))
    ---[[
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
    local stack = vm.Stack:new()
    run(code, store, stack, vmio, mytrace)
    --]]
end
