--type_test.lua

-- for i, v in pairs(types) do print(i,v) end
--testing
---[[
local 	_type,  pairs, print, tostring, error, assert,        format,       concat,       unpack, getmetatable = 
		type,   pairs, print, tostring, error, assert, string.format, table.concat, table.unpack, getmetatable

local type = require'mediacircus.type'




local pf = function(...) print(format(...))  end
local assert_false = function(test, ...)
	if not test then
		return test, ...
	else
		error(...)
	end
end
local function table_report (r, e)
	local ret_table = {}
	for i = 1, #r >= #e and #r or #e do
		ret_table[#ret_table + 1] = format("%d: expected, received:\t%s,\t%s\n", i, tostring(e[i]), tostring(r[i]))
	end
	return concat(ret_table)
end

local function tables_equal (r, e)
	if #r ~= #e then
		return  false
	else
		for i, v in pairs(e) do
			if _type(v) == "table" then
				if _type(r[i]) ~= "table" then 
					return false
				elseif not  tables_equal(r[i], v) then
					return false
				end
			elseif r[i] ~= v then
				return false
			end
		end
		return true
		
	end
end

local function assert_equal (result, expected, ...)


	if mult_val and (_type(result) ~= "table" or _type(expected) ~= "table") then 
		error("Multiple values for assert_equal must be wrapped in a table.")
	end
	local pass, mult_values_string = true, nil

	if _type(expected) ~= _type(result) then
		pass = false
	elseif _type(expected) == "table" then
		
		pass = tables_equal(result, expected)
		if not pass then
			mult_values_string = table_report(result, expected)
		end
	elseif result ~= expected then
		pass = false
	end

	if not pass then	
		if select("#", ...) > 0 then
			error(...)
		elseif mult_values_string then

			error(format("Multiple Value assert_equal failed:\n%s\n---------\n", mult_values_string), 2)

		else
			error(format("assert_equal failed: Expected %s (%s), received %s (%s).", tostring(expected), _type(expected), tostring(result), _type(result) ), 2)

		end
	elseif  _type(expected) == "table" then 

		return concat(result, ", ")
	else
		return result
	end
end


---[[
-- DOCUMENTATION and testing.
pf([=[
Consider our friendly type function:
	type("Hello, World?"): %s
]=],  
	assert_equal(type("Hello, World?"),"string")
)



--> string

pf([=[
We normally check for type equality with this:
	type('hello') == 'string' (%s)
]=],  
	assert(type('hello') == 'string'))
--> string
pf([=[
What if we could also do this:
	type('hello', 'string') (%s)
]=],  
	assert_equal({type('hello', 'string')}, {'string', 'string'}) )
--> string
local my_object_type_t = type.new{"My_Object_Type", "string"}
local my_object = my_object_type_t({})

pf([=[
Not a big deal, but this could lead to some nice tricks: 
	local My_Object_Type_t = type.new{"My_Object_Type", "string"}
	local my_object = type.cast({}, My_Object_Type_t)
or...
	local My_Object_Type_t = type.new{"My_Object_Type", "string"}
	--some code
	---later in your object constructor...
	local my_object = {}
	My_Object_Type_t(my_object)

or...
	local my_object = type.cast({}, {"My_Object_Type", "string"})


	type(my_object, 'string') (%s)
]=], 
	 assert_equal({type(my_object, 'string')}, {"My_Object_Type", "string"}))
-->My_Object_Type, string
print([=[
In the last example, 'My_Object_Type' is the type of the object,
so it is returned first. 'string' was the match, so it is second.

'type' called with multiple arguments redirects to 'type.check'. It receives an object
to check as the first argument, followed by possible matches, which may be either strings 
or 'type' objects. It returns the type object first and the match second.

Note: I think of secondary 'types' more as 'supported interfaces'. They are the quacks in 
duck typing.

So we see that objects can have multiple entries.

Next, we will make some objects:
	--test objects
	local foo_t = type.new{"foo", "test"}
	local test_t = type.new{"test", "foo", "bar"}

	local obj = foo_t({})
	local obj1 =  test_t({})

]=])

	--test objects
	local foo_t = type.new{"foo", "test"}
	local test_t = type.new{"test", "foo", "bar"}

	local obj = foo_t({})
	local obj1 =  test_t({})




pf([=[
Comparison works on types. We can see if all of the interfaces are
'in' another type, if they have all the same type interfaces and the 
opposites of all of that. Order does not matter in comparison.

In the next example, you will notice that we use 'type.get'. Since we 
are keeping compatibility the Lua 'type' function, we need to "get" 
the actual type object, not just its string name.

I may change this later...

Anyway...

Containment:
	type.lt(obj, obj1): 				%s (obj is a subset of obj1)
	type.lt(obj1, obj): 				%s
	type.get(obj)	<=	type.get(obj1):	%s
	type.get(obj)	>=	type.get(obj1):	%s 
	type.get(obj1)	<=	type.get(obj):	%s 
	type.get(obj1)	>=	type.get(obj):	%s 
	type.get(obj)	==	type.get(obj1):	%s
	type.get(obj)	<	type.get(obj1):	%s
	type.get(obj)	>	type.get(obj1):	%s
	type.get(obj1)	<	type.get(obj):	%s
	type.get(obj1)	>	type.get(obj):	%s
]=],
	assert(			type.lt(obj, obj1)),
	assert_false(	type.lt(obj1, obj)),
	assert(			type.get(obj)	<=	type.get(obj1)),
	assert_false(	type.get(obj)	>=	type.get(obj1)),
	assert_false(	type.get(obj1)	<=	type.get(obj)), 
	assert(			type.get(obj1)	>=	type.get(obj)),
	assert_false(	type.get(obj)	==	type.get(obj1)),
	assert(			type.get(obj)	<	type.get(obj1)),
	assert_false(	type.get(obj)	>	type.get(obj1)),
	assert_false(	type.get(obj1)	<	type.get(obj)),
	assert(			type.get(obj1)	>	type.get(obj))
)

local fraction_t = type.new{"fraction", "number", "int"}
local number_t = type.new{"number", "fraction", "int"}

pf([=[
Equality of two tables seems a bit worthless, except that order is
not considered... 

Imagine a possible case where it is not. Consider:

	local fraction_t = type.new{"fraction", "number", "int"}
	local number_t = type.new{"number", "fraction", "int"}

Where a 'fraction' object is a table with a numerator and a denominator and 
all of its arithmatic and equality operators are defined. It supports the 
'number' and 'int' interface and the 'number' type supports fractions and ints. 

There is nothing stopping someone from using this in terms of sub-types, 
but that makes no sense to me. :)

What happens if we try equality?
Containment with another couple of objects:
	type.eq(number_t, fraction_t): 	%s
	number_t == fraction_t:			%s
	type.lt(number_t, fraction_t):	%s
	type.eq(3, fraction_t):			%s

WARNING!! this last test is tricky. We use the fact that weak_type will promote
an object (3) to a type, if it is not a type object. DO NOT think that it will turn...

	"nil"

...into the nil type object. You will get string type object, instead!

]=], 
	assert(			type.eq(number_t, fraction_t)), 
	assert(					number_t == fraction_t),
	assert_false(	type.lt(number_t, fraction_t)),
	assert(	type.eq(3, fraction_t))
)
--> true, false
local pop_t = type.new{"pop", "bang", "dazzle"}
pf([=[
Even unrelated things work as they should! (I really do not know why, actually.)
	local pop_t = type.new{"pop", "bang", "dazzle"}

	type.lt(pop_t, test_t):	%s
	type.lt(test_t, pop_t):	%s
	test_t	<=	pop_t:		%s
	test_t	>=	pop_t:		%s
	pop_t	<=	test_t:		%s 
	pop_t	>=	test_t:		%s 
	test_t  ==	pop_t:		%s
	test_t	<	pop_t:		%s
	test_t  >	pop_t:		%s
	pop_t	<	test_t:		%s
	pop_t	>	test_t:		%s
]=],
	assert_false(	type.lt(pop_t, test_t)),
	assert_false(	type.lt(test_t, pop_t)),
	assert_false(	test_t	<=	pop_t),
	assert_false(	test_t	>=	pop_t),
	assert_false(	test_t	<=	pop_t), 
	assert_false(	test_t	>=	pop_t),
	assert_false(	test_t	==	pop_t),
	assert_false(	test_t	<	pop_t),
	assert_false(	test_t	>	pop_t),
	assert_false(	test_t	<	pop_t),
	assert_false(	test_t	>	pop_t)
)
pf([==[
If you have the debug library loaded, you may also be able to get type names
for user data types:

	type(io.stdin): %s
	type(io.stdin, "userdata"): %s
]==],
	assert_equal(type(io.stdin), "userdata"),
	assert_equal({type(io.stdin, "userdata")}, {"FILE*", "userdata"})
)

pf([=[
You may also pre-cast a type to a user data, making sure to set `userdata = true`:

	 local int64_t = type.new{"int64", "number", userdata = true, table = false}

In this example, we have let Lua know that our type can stand in for a number. With the 
int64 library written by Luiz Henrique de Figueiredo, you can now use these types more 
naturally, (at least within your own library funcitons. The lua libraries are not cool
with your userdata when they want to see a number. I monkey patch all of my stuff.)

]=]
)

local int64_t = type.new{"int64", "number", userdata = true, table = false}

local have_int64, int64 = pcall(require, 'lint64')
--ours is called lint64.
if not have_int64 then
	have_int64, int64 = pcall(require, 'int64')
end


if have_int64 then
local int3 = int64.new(3)

pf([=[
You have int64, so allow me to demonstration:

	local int64 = pcall(require, 'int64')
	local int3 = int64.new(3)

	type(int3):					%s
	type(int3, "number"):		%s
	type.lt(3, int3):			%s

...Wait.. why?

Because we redefined the `number` type to include fractions. If we put it back
to the default:

	local number_t = type.new{"number", table = false}

then...

]=],
	assert_equal(			type(int3), "userdata"),
	assert_equal(			{type(int3, "number")}, {"int64", "number"}),
	assert_false(			type.lt(3, int3))

)

local number_t = type.new{"number", table = false}
pf([=[
	type.lt(3, int3):					%s
	type.lt(int3, 3):					%s
	type.lt(type.find"userdata", int3):	%s
]=],
	assert(					type.lt(3, int3)),
	assert_false(			type.lt(int3, 3)),
	assert(					type.lt(type.find"userdata", int3))
)

end

local obj4 = {}
int64_t(obj4)

pf([=[
Use lt to see if an object can 'behave' like something, even with native types.
	
	local obj4 = {}
	int64_t(obj4)
	
	type.get(3) <= type.get(obj4):	%s
	type.get(3) >= type.get(obj4):	%s
	type.lt(3, obj4):				%s
	type.lt(obj4, 3):				%s
	type(obj4, "number"): 			%s

]=],

	assert(			type.get(3) <= type.get(obj4)),
	assert_false(	type.get(3) >= type.get(obj4)),
	assert(			type.lt(3, obj4)),
	assert_false(	type.lt(obj4, 3)),
	assert_equal(	{type(obj4, "number")}, {"int64", "number"})
)


pf([=[
Again, all of this works (mostly) like normal, too:
	type("Hello, word!"): %s
	type(2): %s 
	type(nil): %s
]=],
	assert_equal(	type("Hello, word!"), "string"),
	assert_equal(	type(2)				, "number"),
	assert_equal(	type(nil)			, "nil"   )
)

local f = function()
	return
end

pf([=[
The 'mostly' is that regular type will error on a call like this:

	type()

or this...

	local f = function()
		return
	end

	type(f())

It might not seem completely obvious why this ever comes up, 
but there are times when does, especially when walking through
an argument list with `select`.

So, instead, this is how it works:

	type(f()): 									%s
	type(f(), "nil"):							%s
	type(f(), "undefined"):						%s					
	type.eq(f(), type.find"nil"): 				%s
	type.lt(f(), type.find"nil"):				%s
	type.lt(f(), type.find"undefined"):			%s

The reason for the above behavior is discovered in the way that Lua adds
the "nil" to argument positions, if there are that follow.
Therefore, you can only get the 'undefined' type by calling 'type()' 
without other arguments. If you do not every care if it is 'undefined' or
just plain 'nil', like you have for your whole Lua life, you can safely
ignore this.

Also, note that no matter what you do (even to __index), a table will
always return 'nil', even for undefined indexes. :(

]=],
	assert_equal(		{type(f())}, {"undefined", "nil"}),
	assert_equal(		{type(f(), "nil")}, {"nil", "nil"}),
	assert_equal(		type(f(), "undefined"), false),
	assert(				type.eq(f(), type.find"nil") ),
	assert_false(		type.lt(f(), type.find"nil")),
	assert(				type.lt(f(), type.find"undefined"))
)





print([=[
To sumarize:

`type.cast` puts a new type into a table. type.new returns a new type. A type will cast
an object (table) by calling it like `typ_name_t(my_object)`.

Types are saved in a type.types table. They cache values (especially usefull for userdate)
and make equality simpler. I have emerging evil plans for more on this, as well. Bwahahaha.

type.get returns a type object. 'type.tostring' returns the string 
representation of the type, which is often not the Lua type. Use type(o) to return's o's 
native type (table or userdata).
]=])

pf([=[
Note that type(obj, 'table') returns a truthy value (the type object), as well ('%s' in 
this case), if there is a match. Otherwise, you get 'false'. 

]=],
	assert_equal({type(obj, 'table')}, {"foo", "table"}) )

print([=[
If it isn't abundantly clear, this is a first.5 whack at something useful.
Hopefully it's not too un-Lua-like. I tried to stick to real-world problems 
that I've actually run into. So far, it's worked really well for me.
]=])

--]]