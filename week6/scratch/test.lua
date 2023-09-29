lpeg = require "lpeg"
pt = require "pt"
P,S,R,C,Ct,V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.V


block_comment = P("#{")*((1-P("}#"))^0)*P("}#")

input = io.read("a")
print(#input)
print(block_comment:match(input))


