lpeg = require "lpeg"

ss = lpeg.S(" \t\n")^0

v=lpeg.R("az")^1*ss
a=lpeg.P("=")*ss
n=lpeg.R("09")*ss
sc=lpeg.P(";")*ss
p=v*a*n*sc*v*a*n
print(p:match(io.read("a")))


