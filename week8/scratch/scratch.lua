t = {tag="if"}
pt=require"pt"
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

s = simpleNode("if","condition","then")

print(pt.pt(s{1,{}}))
