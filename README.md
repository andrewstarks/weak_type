weak_type
=========

A Lua type library for the weak.


Consider our friendly type function:
```lua
type("Hello, World?"): string
```

We normally check for type equality with this:
```lua
type('hello') == 'string' (true)
```

What if we could also do this:
```lua
type('hello', 'string') (string, string)
```
Not a big deal, but this could lead to some nice tricks: 
```lua
local My_Object_Type_t = type.new{"My_Object_Type", "string"}
local my_object = type.cast({}, My_Object_Type_t)
```
or...
```lua
local My_Object_Type_t = type.new{"My_Object_Type", "string"}

--some code
---later in your object constructor...

local my_object = {}
My_Object_Type_t(my_object)
```
or...
```lua
local my_object = type.cast({}, {"My_Object_Type", "string"})
type(my_object, 'string') (My_Object_Type, string)
```

In the last example, `My_Object_Type` is the type of the object,
so it is returned first. 'string' was the match, so it is second.

`type` called with multiple arguments redirects to `type.check`. It receives an object
to check as the first argument, followed by possible matches, which may be either strings 
or `type` objects. It returns the type object first and the match second.

Note: I think of secondary 'types' more as 'supported interfaces'. They are the quacks in 
duck typing.

So we see that objects can have multiple entries.

Next, we will make some objects:
```lua
	--test objects
local foo_t = type.new{"foo", "test"}
local test_t = type.new{"test", "foo", "bar"}

local obj = foo_t({})
local obj1 =  test_t({})
```

Comparison works on types. We can see if all of the interfaces are
'in' another type, if they have all the same type interfaces and the 
opposites of all of that. Order does not matter in comparison.

In the next example, you will notice that we use 'type.get'. Since we 
are keeping compatibility the Lua 'type' function, we need to "get" 
the actual type object, not just its string name.

I may change this later...

Anyway...

Containment:
```lua
type.lt(obj, obj1): 				true (obj is a subset of obj1)
type.lt(obj1, obj): 				false
type.get(obj)	<=	type.get(obj1):	true
type.get(obj)	>=	type.get(obj1):	false 
type.get(obj1)	<=	type.get(obj):	false 
type.get(obj1)	>=	type.get(obj):	true 
type.get(obj)	==	type.get(obj1):	false
type.get(obj)	<	type.get(obj1):	true
type.get(obj)	>	type.get(obj1):	false
type.get(obj1)	<	type.get(obj):	false
type.get(obj1)	>	type.get(obj):	true
```

Equality of two tables seems a bit worthless, except that order is
not considered... 

Imagine a possible case where it is not. Consider:
```lua
local fraction_t = type.new{"fraction", "number", "int"}
local number_t = type.new{"number", "fraction", "int"}
```
Where a 'fraction' object is a table with a numerator and a denominator and 
all of its arithmatic and equality operators are defined. It supports the 
'number' and 'int' interface and the 'number' type supports fractions and ints. 

There is nothing stopping someone from using this in terms of sub-types, 
but that makes no sense to me. :)

What happens if we try equality?
Containment with another couple of objects:
```lua
type.eq(number_t, fraction_t): 	true
number_t == fraction_t:			true
type.lt(number_t, fraction_t):	false
type.eq(3, fraction_t):			true
```
**WARNING!!** this last test is tricky. We use the fact that weak_type will promote
an object (3) to a type, if it is not a type object. DO NOT think that it will turn...

	`"nil"`

...into the `nil` type object. You will get string type object, instead!


Even unrelated things work as they should!
```lua
	local pop_t = type.new{"pop", "bang", "dazzle"}

	type.lt(pop_t, test_t):	false
	type.lt(test_t, pop_t):	false
	test_t	<=	pop_t:		false
	test_t	>=	pop_t:		false
	pop_t	<=	test_t:		false 
	pop_t	>=	test_t:		false 
	test_t  ==	pop_t:		false
	test_t	<	pop_t:		false
	test_t  >	pop_t:		false
	pop_t	<	test_t:		false
	pop_t	>	test_t:		false
```

If you have the debug library loaded, you may also be able to get type names
for user data types:
```lua
type(io.stdin): userdata
type(io.stdin, "userdata"): FILE*, userdata
```
You may also pre-cast a type to a user data, making sure to set `userdata = true`:
```lua
local int64_t = type.new{"int64", "number", userdata = true, table = false}
```

In this example, we have let Lua know that our type can stand in for a number. With the 
int64 library written by Luiz Henrique de Figueiredo, you can now use these types more 
naturally, (at least within your own library funcitons. The lua libraries are not cool
with your userdata when they want to see a number. I monkey patch all of my stuff.)


You have int64, so allow me to demonstration:
```lua
local int64 = pcall(require, 'int64')
local int3 = int64.new(3)

type(int3):					userdata
type(int3, "number"):		int64, number
type.lt(3, int3):			false
```

*...Wait.. why?*

Because we redefined the `number` type to include fractions. If we put it back
to the default:

```lua
local number_t = type.new{"number", table = false}
```

then...

```lua
	type.lt(3, int3):					true
	type.lt(int3, 3):					false
	type.lt(type.find"userdata", int3):	true
```

Use lt to see if an object can 'behave' like something, even with native types.

```lua	
	local obj4 = {}
	int64_t(obj4)
	
	type.get(3) <= type.get(obj4):	true
	type.get(3) >= type.get(obj4):	false
	type.lt(3, obj4):				true
	type.lt(obj4, 3):				false
	type(obj4, "number"): 			int64, number
```

Again, all of this works (mostly) like normal, too:

```lua
	type("Hello, word!"): string
	type(2): number 
	type(nil): nil
```
The 'mostly' is that regular type will error on a call like this:
```lua
	type()
```
or this...

```lua
	local f = function()
		return
	end

	type(f())
```

It might not seem completely obvious why this ever comes up, 
but there are times when does, especially when walking through
an argument list with `select`.

So, instead, this is how it works:

```lua
	type(f()): 									undefined, nil
	type(f(), "nil"):							nil, nil
	type(f(), "undefined"):						false					
	type.eq(f(), type.find"nil"): 				true
	type.lt(f(), type.find"nil"):				false
	type.lt(f(), type.find"undefined"):			true
```

The reason for the above behavior is discovered in the way that Lua adds
the "nil" to argument positions, if there are that follow.
Therefore, you can only get the 'undefined' type by calling 'type()' 
without other arguments. If you do not every care if it is 'undefined' or
just plain 'nil', like you have for your whole Lua life, you can safely
ignore this.

Also, note that no matter what you do (even to `__index`), a table will
always return `nil`, even for undefined indexes. :(


To sumarize:

`type.cast` puts a new type into a table. `type.new` returns a new type. A type will cast
an object (`table`) by calling it like `typ_name_t(my_object)`.

Types are saved in a `type.types` table. They cache values (especially usefull for userdata)
and make equality simpler. I have emerging evil plans for more on this, as well. Bwahahaha.

`type.get` returns a `type` object. `type.tostring` returns the string 
representation of the type, which is often not the Lua type. Use `type(o)` to return's o's 
native type (`table` or `userdata`).

Note that `type(obj, 'table')` returns a truthy value (the `type` object), as well (`foo, table` in 
this case), if there is a match. Otherwise, you get `false`. 

If it isn't abundantly clear, this is a first.5 whack at something useful.
Hopefully it's not too un-Lua-like. I tried to stick to real-world problems 
that I've actually run into. So far, it's worked really well for me.

Your comments would be most appreciated!

-- Andrew Starks
