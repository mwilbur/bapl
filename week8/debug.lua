local lpeg = require "lpeg"
local pt = require "pt"
local P,S,R,C,Ct,V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.V

local spaces = S(" \t\n")^0
local function T(t)
    return P(t)*spaces
end
local number = R("09")

local p = V"p"

local function f(t) 
  return {t}
end


local grammar = P{
  p,
  p = (T"{"*C(p)*T"}" + C(number)) / f
}

print(pt.pt(grammar:match("{{1}}")))

