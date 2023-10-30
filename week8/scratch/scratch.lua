local pt = require"pt"

local t = { 
    tag = "init",
    exprs = { 
        { tag = "init",
          exprs = {{ tag = "number", value = 4 }} 
        },
        { tag = "init",
          exprs = {{ tag = "number", value = 3 }} 
        }
    }
}

print(pt.pt(t))