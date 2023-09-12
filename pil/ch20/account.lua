Account = {balance=0}

function Account:new(o) 
    o = o or {}
    self.__index = self
    setmetatable(o,self)
    return o
end

function Account:deposit(v)
    self.balance = self.balance + v
end

function Account:withdrawl(v)
    if v > self.balance then error"insufficient funds" end
    self.balance = self.balance - v
end

SpecialAccount = Account:new()

s = SpecialAccount:new{limit = 1000.00}

-- SpecialAccount:new{limit} ->
-- SpecialAccount.new(self, {limit})
--  SpecialAccount no method new
--      SpecialAccount has metatable Account with __index = Account
--      so new resolves to Account:new
--

s:deposit(100)

-- s has n
