-- Exercise 4.1
xml_fragment1 = [=[
<![CDATA[
  Hello world
]]>
]=]

xml_fragment2 = "<![CDATA[\
  Hello world\
]]>\
"

function insert(s, i, t) 
		sbegin = string.sub(s,1,i)
		send = string.sub(s,i+1,-1)
			
		-- allocate the resultant string
		return sbegin .. t .. send
end
