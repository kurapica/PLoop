# Prototype Lua Object-Oriented Program System

中文版请点击[README-zh.md](https://github.com/kurapica/PLoop/blob/master/README-zh.md)

**PLoop** is a C# like style object-oriented program system for lua. It support Lua 5.1 and above versions, also include the luajit. It's also designed to be used on multi-os thread platforms.

It provide the usage of enum, struct, interface and class. Also provide common useful features like thread, collection, serialization , data entity framework, web framework and etc.

You can also find useful features for enterprise development like code organization, type validation and etc.

**You can find more details in the [Docs](https://github.com/kurapica/PLoop/tree/master/Docs)**


## Table of Contents

* [Install](#install)
* [Using the collection](#using-the-collection)
* [Attribute and Thread Pool](#attribute-and-thread-pool)
* [Spell Error Checks And More](#spell-error-checks-and-more)
	* [Read un-existed global variables](#read-un-existed-global-variables)
	* [Write to illegal global variables](#write-to-illegal-global-variables)
	* [Access un-existed object fields](#access-un-existed-object-fields)
* [Type Validation](#type-validation)
* [enum](#enum)
* [struct](#struct)
	* [Custom](#custom)
	* [Member](#member)
	* [Array](#array)
	* [Dictionary](#dictionary)
* [Class](#class)
* [Interface](#interface)
* [Serialization](#serialization)
	* [JSON Format](#json-format)
* [Data Entity](#data-entity)
* [Web FrameWork](#web-framework)


## Install

After install the **Lua**, download the **PLoop** and save it to **LUA_PATH**, or you can use

```lua
package.path = package.path .. ";PATH TO PLOOP PARENT FOLDER/?/init.lua;PATH TO PLOOP PARENT FOLDER/?.lua"

require "PLoop"
```

to load the **PLoop**. If you need to load files by yourself, you could check the **PLoop/init.lua** for more details.


## Using the collection

The collection classes will provide useful stream works like

```lua
require "PLoop"

-- Generate a list from 1 to 10, choose all even numbers, square them and join them by ","
-- The result is  "4,16,36,64,100"
print( PLoop.System.Collections.List(10):Range(2, -1, 2):Map("x=>x^2"):Join(",") )


-- Get all the keys from the _G whose value is a table, sort them and join them by ","
-- The result is "_G,arg,coroutine,debug,io,math,os,package,string,table"
print( PLoop.System.Collections.XDictionary(_G):Filter("k,v=>type(v)=='table'").Keys:ToList():Sort():Join(",") )
```


## Attribute and Thread Pool

We have see how to use classes in the previous example, for the second example, I'll show special usage of the **PLoop**:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Iterator__()
	function iter(i, j)
		for k = i, j do
			coroutine.yield(k)
		end
	end

	-- print 1-10 for each line
	for i in iter(1, 10) do
		print(i)
	end
end)
```

The **PLoop** can used to call a function with `_ENV` as its first arguments, this is used to make sure the code in the function will be processed in a special environment provided by the **PLoop**, in here, you can use **List** instead the **PLoop.System.Collections.List**. The best part is you can use the attribute for functions.

Unlike the `_G`, the **PLoop** environments are very sensitive about new variables, when the *iter* is defiend, the system will check if there is any attributes should be applied on the function, here we have the `__Iterator__()`.

The `__Iterator__` is an attribute class defined in **System.Threading**, when we use it to create an object, the object is registered to the system, and waiting for the next attribute target(like function, class and etc) that should be defined. The attributes are used to modify or attach data to the attribute targets.

The `__Iterator__` is used to wrap the target function, so it'll be used as an iterator that runs in a corotuine, and we can use *coroutine.yield* to return values:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- Calculate the Fibonacci sequence
	__Iterator__()
	function Fibonacci(maxn)
		local n0, n1 = 1, 1

		coroutine.yield(0, n0)
		coroutine.yield(1, n1)

		local n = 2

		while n <= maxn  do
			n0, n1 = n1, n0 + n1
			coroutine.yield(n, n1)
			n = n + 1
		end
	end

	-- 1, 1, 2, 3, 5, 8
	for i, v in Fibonacci(5) do print(v) end

	-- you also can pass the argument later
	-- the iterator will combine all arguments
	-- 1, 1, 2, 3, 5, 8
	for i, v in Fibonacci(), 5 do print(v) end
end)
```

The collection object method also using the coroutines, so it don't need to generate any cache or anonymous function to do the jobs, since those coroutines are recycled automatically, there is no cost compares to other solutions.


## Spell Error Checks And More

There are a lots of troubles in the Lua debugging, if the lua error can be triggered, it's still easy to fix it, but for codes like `if a == ture then`, *ture* is a non-existent variable, Lua treate it as nil so the checking will still working, but the result can't be right.

We'll see how to solve it in the **PLoop**.


### Read un-existed global variables

Before rquire the **PLoop**, we can create a **PLOOP_PLATFORM_SETTINGS** table to toggle the **PLoop**'s system settings:

```lua
PLOOP_PLATFORM_SETTINGS = { ENV_ALLOW_GLOBAL_VAR_BE_NIL = false }

require "PLoop"

PLoop(function(_ENV)
	local a = ture  -- Error: The global variable "ture" can't be nil.

	if a then
		print("ok")
	end
end)
```

Turn off the **ENV_ALLOW_GLOBAL_VAR_BE_NIL** will apply a strict mode for all **PLoop** private environment, so no nil variables can be accessed, so you can locate those errors.

### Write to illegal global variables

If we missing the `local`, we may create unwanted global variables. But the system can't diff the wanted and unwanted global variable, we can add filter in the platform settings to do the job, so we can remove the filter when we don't need it:

```lua
PLOOP_PLATFORM_SETTINGS = {
	GLOBAL_VARIABLE_FILTER = function(key, value)
		-- Don't allow the lowercase key with non-function value
		if type(key) == "string" and key:match("^%l") and type(value) ~= "function" then
			return true
		end
	end,
}

require "PLoop"

PLoop(function(_ENV)
	Test = 1

	class "A" (function(_ENV)
		function Test(self)
			ch = 2 -- error: There is an illegal assignment for "ch"
		end
	end)

	A():Test()
end)
```

If the filter return true, the assignment will trigger an error, so the code'll be stopped, if we only need a warning, we can add a setting like:

```lua
PLOOP_PLATFORM_SETTINGS = {
	GLOBAL_VARIABLE_FILTER = function(key, value)
		-- Don't allow the lowercase key with non-function value
		if type(key) == "string" and key:match("^%l") and type(value) ~= "function" then
			return true
		end
	end,
	GLOBAL_VARIABLE_FILTER_USE_WARN = true,
}

require "PLoop"

PLoop(function(_ENV)
	Test = 1

	class "A" (function(_ENV)
		function Test(self)
			ch = 2 -- [PLoop: Warn]There is an illegal assignment for "ch"@path_to_file\file.lua:18
		end
	end)

	A():Test()
end)
```

You also can use the filter as a record, with another setting, the call line'll be passed in as the 3rd argument:

```lua
PLOOP_PLATFORM_SETTINGS = {
	GLOBAL_VARIABLE_FILTER = function(key, value, path)
		print("Assign '" .. key .. "'" .. path )
	end,
	GLOBAL_VARIABLE_FILTER_GET_CALLLINE = true,
}

require "PLoop"

PLoop(function(_ENV)
	Test = 1  -- Assign 'Test'@path_to_file\file.lua:11

	class "A" (function(_ENV)
		function Test(self)
			ch = 2 -- Assign 'ch'@path_to_file\file.lua:15
		end
	end)

	A():Test()
end)
```

To use the get call line, the `debug.getinfo` must exist.

### Access un-existed object fields

We also can block the accessing of un-existed object fields:

```lua
PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST = true, OBJECT_NO_NIL_ACCESS = true }

require "PLoop"

PLoop(function(_ENV)
	-- Define a class with Name and Age property
	class "Person" (function(_ENV)
		property "Name" { type = String }
		property "Age"  { type = Number }
	end)

	o = Person()

	o.Name = "King" -- Ok

	o.name = "Ann"  -- Error: The object can't accept field that named "name"

	print(o.name)   -- Error: The object don't have any field that named "name"
end)
```

This three settings will help authors to avoid many spell errors during the development. You shouldn't use those settings when you release the project since the access speeding should be slightly increased.


## Type Validation

**PLoop** make the Lua as a strong type language, there are many type validation features to stop the errors spread to far so too hard to be tracked.

The function validation is always a complex part, we need to do many checks before the function's main logic for the arguments so we can tell the caller where and what is failed. And when the project is released, those check should be removed since we already test them.

Within the **PLoop**, it'll be a small problem:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String, Number }
	function SetInfo(name, age)
	end

	-- Error: Usage: SetInfo(System.String, System.Number) - the 2nd argument must be number, got boolean
	SetInfo("Ann", true)
end)
```

The `__Arguments__` is an attribute class defined in the **System**, it associated the argument name, type, default value and etc to the argument, also wrap those functions with the argument validation.

The **String** and **Number** are struct types used to validate values, we'll see them at the introduction of struct.

If we need to release the project, there is also no need to remove those `__Arguments__`, you can change the platform setting( not all type validation would be removed, but just leave them to the system):

```lua
PLOOP_PLATFORM_SETTINGS = { TYPE_VALIDATION_DISABLED = true }

require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String, Number }
	function SetInfo(name, age)
	end

	-- No error now
	SetInfo("Ann", true)
end)
```

To achieve a whole type validation system, we need more types to describe the datas. In **PLoop**, there are four types: enum, struct, interface and class.


## enum

the enumeration is a data type consisting of a set of named values called elements, The enumerator names are usually identifiers that behave as constants.

To define an enum within the **PLoop**, the syntax is

```lua
enum "name" { -- key-value pairs }
```

In the table, for each key-value pair, if the key is string, the key would be used as the element's name and the value is the element's value. If the key is a number and the value is string, the value would be used as both the element's name and value, othwise the key-value pair will be ignored.

Use `enumeration[elementname]` to fetch the enum element's value, also can use `enumeration(value)` to fetch the element name from value.

Also can use the element name directly where the enum is defined or imported.

Here is an example :

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "TestNS"

	enum "Direction" { North = 1, East = 2, South = 3, West = 4 }

	print(Direction.South) -- 3
	print(Direction.NoDir) -- nil
	print(Direction(3))    -- South

	print(East)            -- 2
end)

PLoop(function(_ENV)
	import "TestNS.Direction"

	print(South)           -- 3
end)
```

Since the element value is indexed, we also can define it like

```lua
require "PLoop"

PLoop(function(_ENV)
	__AutoIndex__{ North = 1, South = 5 }
	enum "Direction" {
		"North",
		"East",
		"South",
		"West",
	}

	print(East) -- 2
	print(West) -- 6
end)
```

The `__AutoIndex__` attribute will give each element an auto-increase index based on the config tables.

Another special enum is the flags enumeration type, the element value should be 2^n(0 is also allowed), so the element value can be used together :

```lua
require "PLoop"

PLoop(function(_ENV)
	__Flags__()
	enum "Days" {
		"SUNDAY",
		"MONDAY",
		"TUESDAY",
		"WEDNESDAY",
		"THURSDAY",
		"FRIDAY",
		"SATURDAY",
	}

	v = SUNDAY + MONDAY + FRIDAY

	-- SUNDAY  1
	-- MONDAY  2
	-- FRIDAY  32
	for name, val in Days(v) do
		print(name, val)
	end

	print(Enum.ValidateFlags(MONDAY, v)) -- true
	print(Enum.ValidateFlags(SATURDAY, v)) -- false
end)
```


## struct

The structures are types for basic and complex organized datas and also the data contracts for value validation. There are three struct types:

### Custom

The basic data types like number, string and more advanced types like nature number. Take the *Number* as an example:

```lua
require "PLoop" (function(_ENV)
	v = Number(true)  -- Error : the value must be number, got boolean
end)
```

There system have provide many fundamental custom struct types like :

Custom Type                   |Description
:-----------------------------|:-----------------------------
**System.Any**                |represents any value
**System.Boolean**            |represents boolean value
**System.String**             |represents string value
**System.Number**             |represents number value
**System.Function**           |represents function value
**System.Table**              |represents table value
**System.Userdata**           |represents userdata value
**System.Thread**             |represents thread value
**System.AnyBool**            |represents anybool value
**System.NEString**           |represents nestring value
**System.RawTable**           |represents rawtable value
**System.Integer**            |represents integer value
**System.NaturalNumber**      |represents natural number value
**System.NegativeInteger**    |represents negative interger value
**System.NamespaceType**      |represents namespace type
**System.EnumType**           |represents enum type
**System.StructType**         |represents struct type
**System.InterfaceType**      |represents interface type
**System.ClassType**          |represents class type
**System.AnyType**            |represents any validation type
**System.Lambda**             |represents lambda value
**System.Callable**           |represents callable value, like function, callable objecct, lambda
**System.Guid**               |represents Guid value


### Member

The member structure represent tables with fixed fields of certain types. Like

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	loc = Location{ x = "x" }    -- Error: Usage: Location(x, y) - x must be number
	loc = Location(100, 20)
	print(loc.x, loc.y)          -- 100  20
end)
```

So the **Location** struct has two members : *x*, *y* all are numbers, we can use it to validate the tables with the special structure.

it also can be used as value constructor(and only the member struct can be used as constructor), the argument order is the same order as the declaration of it members.


### Array

The array structure represent tables that contains a list of same type items. Here is an example to declare an array:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	struct "Locations" { Location }

	v = Locations{ {x = true} } -- Usage: Locations(...) - the [1].x must be number
end)
```

So the **Locations** should contains several **Location** values.

The enum and struct are all data types, normally used for type validation. The interface and class types is the core system of the **PLoop**.

### Dictionary

The dictionary structure represent tables that contains a specific type keys and specific type value pairs.

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "NameAge" { [String] = Number }

	v = NameAge{ ann = 2, ben = 3 }
end)
```


## Class

The classes are types that abstracted from a group of similar objects. The objects generated by the classes are tables with fixed meta-tables.

A class can be defined within several parts: constructor, meta-method, object method, property and event:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Imaginary" (function(_ENV)
		-- event
		event "OnRealChanged"
		event "OnImgChanged"

		-- property
		property "Real"      { type = Number, default = 0 }
		property "Imaginary" { type = Number, default = 0 }

		-- method
		function AddReal(self, rel)
			self.Real = self.Real + rel
			OnRealChanged(self)
		end

		function AddImg(self, img)
			self.Imaginary = self.Imaginary + img
			OnImgChanged(self)
		end

		-- constructor
		function Imaginary(self, real, img)
			self.Real = real
			self.Imaginary = img
		end

		-- meta-method
		function __add(self, another)
			return Imaginary(self.Real + another.Real, self.Imaginary + another.Imaginary)
		end

		function __tostring(self)
			return ("%d + %di"):format(self.Real, self.Imaginary)
		end
	end)

	a = Imaginary(1, 2)

	a.OnRealChanged = a.OnRealChanged + function(self)
		print("New real is " .. self.Real)
	end

	-- New real is 4
	a:AddReal(3)

	-- 7 + -2i
	print(a + Imaginary(3, -4))
end)
```


## Interface

The interfaces are abstract types of functionality, it also provided the multi-inheritance mechanism to the class. It works like the class, just can't be used to create objects.

A class can only have one super class, but can extend no limit interfaces.

You could find the details in [006.class.md](https://github.com/kurapica/PLoop/blob/master/Docs/006.class.md)


## Serialization

With the **System.Serialization**, we can serialize objects to data of target format, or deserialize the data to objects.

### JSON Format

Here is a full example to use the Serialization:

```lua
require "PLoop" (function(_ENV)
	import "System.Serialization"

	json = [==[
	{
		"debug": "on\toff",
		"nums" : [1,7,89,4,5,6,9,3,2,1,1,9,3,0,11]
	}]==]

	-- deserialize json data to lua table
	data = Serialization.Deserialize(JsonFormatProvider(), json)

	-- Serialize lua table to string with indent
	-- {
	-- 		debug = "on	off",
	-- 		nums = {
	-- 			[1] = 1,
	-- 			[2] = 7,
	-- 			[3] = 89,
	-- 			[4] = 4,
	-- 			[5] = 5,
	-- 			[6] = 6,
	-- 			[7] = 9,
	-- 			[8] = 3,
	-- 			[9] = 2,
	-- 			[10] = 1,
	-- 			[11] = 1,
	-- 			[12] = 9,
	-- 			[13] = 3,
	-- 			[14] = 0,
	-- 			[15] = 11
	-- 		}
	-- }
	print(Serialization.Serialize(StringFormatProvider{Indent = true}, data))
end)
```

The example is using **System.Serialization** deserialize a json string to lua data by using **System.Serialization.JsonFormatProvider**, then use **System.Serialization.StringFormatProvider** to serialize the data to a string.

You can find more in [009.serialization.md](https://github.com/kurapica/PLoop/blob/master/Docs/009.serialization.md)

To simply use the **JsonFormatProvider**, you can use `Toolset.json(data[, type])` to serialize the data or object into json,
or use `Toolset.parsejson(json[, type])` to deserialize the json to the data or object.

For the **StringFormatProvider**, also we can use `Toolset.tostring(data[, type[, pretty]])` to serialize the data or object into
string, or use `Toolset.parsestring(str[, type])` deserialize the string to the data or object.


## Data Entity

With the **Systm.Data** lib, we can define data entity classes that represents a data base

```lua

require "PLoop"
require "PLoop.System.Data"

PLoop(function(_ENV)
	import "System.Data"

	__DataContext__()  -- Represents the data base
	class "TestDBContext" (function(_ENV)
		-- Init the connection when a context object is created
		function __ctor(self)
			self.Connection = MySQLConnection { }
		end

		-- Represents the data table
		__DataTable__{
			name         = "department",
			indexes      = {
				{ fields = { "id" },   primary = true },
			}
		}
		class "Department" (function(_ENV)
			-- Represents the data field
			__DataField__{ autoincr = true }
			property "id"           { type = NaturalNumber }

			__DataField__{ notnull = true, unique = true }
			property "name"         { type = String }
		end)
	end)

	-- Operations for CRUD
	with( TestDBContext() )(function(ctx)
		-- Query the data table department with id, take the first result
		local dept = ctx.Departments:Query{ id = 1 }:First()

		if not dept then
			-- create it if not existed
			with( ctx.Transaction )(function(trans)
				dept =  ctx.Departments:Add{
					name = "temp",
				}

				-- save all changes to the data base
				ctx:SaveChanges()
			end)
		end
	end)
end)
```

So we can only use the Lua codes to avoid sql operations. You can find the details in [019.data.md](https://github.com/kurapica/PLoop/blob/master/Docs/019.data.md)


## Web FrameWork

The **System.Web** provide the abstract layer for web development, you can find the implementation for [Openresty](https://github.com/openresty/lua-nginx-module/) at [NgxLua](https://github.com/kurapica/NgxLua/), there is an example project at [PLoop.Browser](https://github.com/kurapica/PLoop.Browser) which can be used to browser the types of the **PLoop**.

With the web framework we can create any web service with a simple format

```lua
require "PLoop.System.Web"

-- Create a web application
Application "TestWebApp" (function(_ENV)
	__Route__("/jsonhandler", HttpMethod.GET) -- bind the route
	__Json__()  -- the return value will be converted to JSON format as response
	function JsonHandler(context)
		return {
			Data = {
				{ Name = "Ann", Age =  12},
				{ Name = "King", Age =  32},
				{ Name = "July", Age =  22},
				{ Name = "Sam", Age =  30},
			}
		}
	end
end)
```

The web framework also provide a powerful template system and MVC framework, you can find the details in [020.web.md](https://github.com/kurapica/PLoop/blob/master/Docs/020.web.md)



## Contancts

QQ Group: 107045813
https://discord.gg/6hD4sdUtgp
