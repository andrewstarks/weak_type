--[[
	mediacircus.type.lua
--]]

local 	_type, setmetatable, getmetatable, select, ipairs, pairs,  tostring, error, assert, print, unpack, fmt = 
		type, setmetatable, getmetatable, select, ipairs, pairs, tostring, error, assert, print, table.unpack, string.format

-- print(("%s %s %s"):match("%%"))

local have_debug, debug = pcall(require, 'debug')

_ENV = {}

local function get_ud_name(ud)
	if not have_debug then return "userdata" end

	local ud_mt = getmetatable(ud)
	local registry = debug.getregistry()
	for i, v in pairs(registry) do
		if v == ud_mt then
			return i
		end
	end
end
local type = setmetatable({}, {
	__call = function(t, ...)
		if  select("#", ...) == 1 then

			return _type(...)
		else
			return t.check(...)
		end

	end
})

local function normalize_to_type(...)

	if select("#", ...) ~= 0 then
		return type((...), "type") and (...) or type.get((...)), normalize_to_type(select(2,...))
	else
		return nil
	end

end

type.types = setmetatable({}, {
	__mode = "v", 
	__type={types = 1, "types", table = true}}
)

local  type_mt = {
	__type = {type = 1, "type", table = true},
	__call = function(self, o)
		return type.cast(o, self)
	end,
	__tostring = function(self)
		return self[1]
	end,
	__eq = function(a,b)
		return type.eq(a,b)
	end,
	__lt = function(a, b)

		return type.le(a,b)
	end,
	__le = function(a, b)
		return  type.le(a,b)
	end
}

local types = type.types
function type.new(t)

	if _type(t) == "string" then
		t = {t}
	elseif _type(t) ~= "table" then
		error("Expected string or table of type names.") 
	end


	local new_type = {}

	for i,v in ipairs(t) do
		new_type[i] = v
		new_type[v] = i
	--	print("making",new_type[v],new_type[i])
	end


	--make a table entry, but don't index it.
	--that way #length points to how many types
	--are assigned to it, but not the obvious ones.
	--also, tables that are passed in can be done this way too.
	if t.table or t.table == nil and not t.userdata then -- default path
		new_type.table, new_type.userdata = true, false
	elseif t.userdata and not t.table then --userdata is true
		new_type.table, new_type.userdata = false, true
	elseif t.table and t.userdata then--
		error("A type can't be a table and a userdata value.")
	else --the specified it. probably t.table is false and so is userdata (native type.)
		new_type.table, new_type.userdata =  t.table, t.userdata
	end

	types[new_type[1]] = new_type

	return setmetatable(new_type, type_mt)

end
function type.get(o)
	local obj_type = _type(o)
	if obj_type == "table" then
		local o_mt =   getmetatable(o)
		return o_mt and o_mt.__type or types["table"]

	elseif have_debug and obj_type == "userdata" then
		local ud_name =  get_ud_name(o)
		if types[ud_name] then
			if not types[ud_name].userdata then
				error(fmt("Name clash! Previous type with the name '%s' was defined in userspace (not a metatable).", 
					ud_name),
				2)
			end 

			return types[ud_name]
		elseif ud_name then
			return type.new({ud_name, userdata = true, table = false})
		else
			return types.userdata --couldn't find it.
		end

	else
		return types[_type(o)] or error(fmt("Undefined type: %s",_type(o)), 2)
	end
end
function type.find(type_name)
	return types[type_name]
end

function type.check(...)

	local arg_len = select("#", ...) 

	if arg_len == 0 then
		return types.undefined[1], types.undefined[2]
	elseif arg_len == 1 then 
		return type.tostring((...))
	end

	local o_type = type.get((...))

	-- o is at one, so skip that. make i 2
	for i = 2, arg_len do
		local cur_search = (select(i , ...))
		if o_type[cur_search] then
				return o_type[1],  cur_search
		end
	end
	
	--didn't find it.
	return false

end



function type.tostring(o)
	return tostring(type.get(o))

end
function type.cast (o, new_type)

	if _type(o) ~= "table" then
		error("Expected a table as first argument to  type.cast. Received %s", _type(o) )
	end

	local o_mt = getmetatable(o) or {}

	--if a string is passed in, and that string is  an index of types,
	--then they want to cast an existing type.
	if _type(t) == "string" and types[new_type] then
		o_mt.__type =  types[new_type]

	--Maybe they're removing the type?
	elseif new_type == nil then
		o_mt.__type = nil
	--Are the placing an existing type?
	elseif type.check(new_type, "type") then
		o_mt.__type = new_type
	--Is it a new type?
	else
		o_mt.__type = type.new(new_type)
	end

	return setmetatable(o,  o_mt)
	
end


--this isn't right. if all of the types in a
--are found in b, then it should be true
--so type.le(a,b) and type.le(b, a)?
function type.eq(a, b)

	a, b = normalize_to_type(a, b)


	return  type.le(a,b) and type.le(b, a)

end
function type.lt(a,b)

	return type.le(a,b) and not type.le(b, a)
end

-- Does not return true for equality. Only less than.
local function assert_type(o)
	if not type(o, "type") then
		error(fmt("Error: expected 'type' and received %s", type.tostring(o)),2)
	else
		return o
	end

end
function type.le(a, b)

	a,b = normalize_to_type(a,b)

	

	if a[1] == "table" or a[1] == "userdata" then
		return b[a[1]] and true or false
	--two complex types.
	else
		for i, v in ipairs(a) do
			if not b[v] then
	
				return false
			end
		end
		return true
	end
end

type.native = {
	type.new({"userdata", table = false, userdata = true}),
	type.new({"table", userdata = false}),
	type.new({"string", table = false}),
	type.new({"number", table = false}),

	type.new({"boolean", table = false}),
	type.new({"function", table = false}),
	type.new({"thread", table = false}),
	type.new({"nil", table = false}),
	type.new({"undefined", "nil", table = false})
}

return type