lpeg = require "lpeg"

-- a numeral is an optional '-' followed by 1 or more digits
numeral = lpeg.P("-")^-1 * lpeg.R("09")^1

numeral_surrounded_with_spaces = 
	lpeg.P(" ")^0 * numeral * lpeg.P(" ")^0

p = numeral_surrounded_with_spaces * 
	(lpeg.P("+") * numeral_surrounded_with_spaces)^0 * -1

function assert_matches_all(p,expr)
	assert(p:match(expr)==#expr+1)
end

function assert_matches(p,expr)
	assert(p:match(expr))
end

function assert_no_match(p,expr)
	assert(not p:match(expr) or p:match(expr) <= #expr)
end

tests = {
	function (p)
		assert_matches_all(p,"1")
	end,

	function (p)
		assert_matches_all(p,"1+2")
	end,

	function (p)
		assert_no_match(p,"1+")
	end,

	function (p)
		assert_no_match(p,"+1")
	end,

	function (p)
		assert_no_match(p,"+1+")
	end,

	function (p)
		assert_matches_all(p," 1")
	end,

	function (p)
		assert_matches_all(p,"1 ")
	end,

	function (p)
		assert_matches_all(p," 1 ")
	end,

	function (p)
		assert_no_match(p," 1 +")
	end,

	function (p)
		assert_matches_all(p," 1+ 3 + 4+  5")
	end,

	function (p)
		assert_matches_all(p," 21+ 3 + 44+  3535")
	end,

	function (p)
		assert_matches_all(p," -21+ 3 + 44+  -3535")
	end,

	function (p)
		assert_matches_all(p,"-1")
	end,

	function (p)
		assert_matches_all(p," -1")
	end,

	function (p)
		assert_matches_all(p,"-1 ")
	end,

	function (p)
		assert_no_match(p,"-1 +")
	end,

	function (p)
		assert_no_match(p,"+ -1 +")
	end,

	function (p)
		assert_no_match(p,"+ -1 ")
	end,

	function (p)
		assert_no_match(p,"- 1")
	end,

	function (p)
		assert(not p:match("1 + 3 + -1 df"))
	end,
}

for _,test in ipairs(tests) do
	test(p1)
end

