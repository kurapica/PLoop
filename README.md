# Prototype Lua Object-Oriented Program System

中文版请点击[README-zh.md](https://github.com/kurapica/PLoop/blob/master/README-zh.md)

**PLoop** is a C# like style object-oriented program system for lua. It support Lua 5.1 and above versions, also include the luajit. It's also designed to be used on multi-os thread platforms like the **OpenResty**.

It also provide common useful classes like thread pool, collection, serialization and etc.

You also can find useful features for large enterprise development like code organization, type validation and etc.


## Install

After install the **Lua**, download the **PLoop** and save it to **LUA_PATH**, or you can use

```lua
package.path = package.path .. ";PATH TO PLOOP PARENT FOLDER/?/init.lua;PATH TO PLOOP PARENT FOLDER/?.lua"

require "PLoop"
```

to load the **PLoop**. If you need to load files by yourself, you could check the **PLoop/init.lua** for more details.


## Start with the Collections

Before the introduction of the OOP part, I'll show some scenarios of the usages of **PLoop**, let's start with the collections.

In Lua, we use the table in two ways to store datas:

* array table, we only care the values with orders
* has table, we care about the key and value

In the **PLoop**, we have the **System.Collections.List** represents the array table and the **System.Collections.Dictionary** represents the hash table.

### The creation of List

There are several ways to create a **List** object:

Constructor                      |Result
:--------------------------------|:--------------------------------
List(table)                      |Convert the input table as a list object, no new table would be generated
List(listobject)                 |Copy all elements form the other list object(may be other list type's object)
List(iterator, object, index)    |Use it like List(ipairs{1, 2, 3})，use the result of the iterator as list elements
List(count, func)                |Repeat func(i) for _count_ times, use those result as list elements
List(count, init)                |Create a list with _count_ elements, all values are the init
List(...)                        |Use the arguments as the list elements, it's the same like List{...}

Let's have an examples:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- List(table)
	o = {1, 2, 3}
	print(o == List(o))  -- true

	-- List(count)
	v = List(10)         -- {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	-- List(count, func)
	v = List(10, function(i) return math.random(100) end) -- {46, 41, 85, 80, 62, 37, 29, 91, 62, 37}

	-- List(...)
	v = List(1, 5, 4)    -- {1, 5, 4}
end)

print(v) -- nil
print(List) -- nil

import "System.Collections"

print(List) -- System.Collections.List
```

This is our first **PLoop** example. **PLoop** has a lot of different design from the usual Lua development.

First of all, we use `PLoop(function(_ENV) end)` to encapsulate and call the processing code. This is designed to solve several problems of Lua development(you can skip the following discussion about the environment if you can't understand, you can continue the reading without problem):

* Lua's each file can be considered as a function to be executed, and each Lua function has an environment associated with it. The environment is Lua's ordinary table. The global variables accessed by the function are the fields in the environment. By default, the environment is `_G`.

	In collaborative development, global variables accessed by all files are stored in `_G`. This can easily cause conflicts. In order to avoid the double-name conflicts, we must keep using local variables, it's not good for free coding and will create too many closures.

* As shown in the **System.Collections.List**, to avoid the using of the same name type, we normally use a **namespace** system to manage various types. In order to use the **List** in `_G`, as we can see in the last few lines of the above example, we need to use `import "System.Collections"`, then wen can use **List** in the `_G`.

	If we have an ui library that provides type **System.Form.List**, this is an ui class. If it is also imported into `_G`, then the two types will cause errors due to duplicate names.

The main problem is that the default environment of all processing codes is the `_G`. If we can keep each codes processed in its own private environment, we can completely avoid the problem of duplicate names, and we also don't need to strictly use local to declare function or share Datas.

In the previous example, the function that encapsulates the code is passed as argument to **PLoop**, it will be bound to a private and special **PLoop** environment and then be executed. Because the Lua's environmental control has significant changes from version 5.1 to version 5.2. **PLoop** used this calling style for compatibility, you will see other similar codes, such as defining a class like `class "A" (function(_ENV) end)`.(If you don't understand the `_ENV`, you should check the Lua 5.2 updates)

We'll learn more benefites of this calling style in the other examples, and for the previous example:

* The global variable declared belongs to this private environment. In the `_G`, the variable v cannot be accessed.

* Free to use the public libraries or variables such as math.random stored in `_G`, there is no performance issues since the private environment will auto-cache those variables when it is accessed.

* You can directly access the **List** class, **PLoop** has public namespaces, the public namespaces can be accessed by all **PLoop** environments without **import**, the default public namespaces are **System**, **System.Collections** and **System.Threading**, we'll learn more about the them at later.

	The public namespaces accessing priority is lower than the imported namespaces, so if you use the `import "System.Form"`, then the **List** is pointed to the **System.Form.List**.

* We can use the keyword **import** to import namespaces to the private environments or the `_G`, then we can use the types stored in those namespaces. The difference is importing to the `_G` is a *saving all to `_G`* action, and the private environment will only records the namespaces it imported, only access the types in them when needed(also will be auto cached).

Back to the creation of the **List** objects, the **List** type can be used as an object generator, it'll create the list objects based on the input arguments.

Those List objects are normal Lua tables with meta-table settings, we still can use **ipairs** to traverse it or use `obj[1]` to accessed its elements. We also can enjoy the powerful methods provided by the **List** classes.


### The method of the List

The **List** class has provide basic method for list operations:

Method                                   |Description
:----------------------------------------|:--------------------------------
Clear(self)                              |Clear the list
Contains(self, item)                     |Whether the item existed in the list
GetIterator(self)                        |Return an interator for traverse
IndexOf(self, item)                      |Get the index of an item if it existed in the list
Insert(self[, index], item)              |Insert an item in the list
Remove(self, item)                       |Remove an item from the list
RemoveByIndex(self[, index])             |Remove and item by index or from the tail if index not existed

```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	print(obj:Remove()) -- 10
end)
```

### The traverse of the List

The **List** and **Dictionary** all extended the **System.Collections.Iterable** interface, the interface require the collections classes must have a **GetIterator** object method, used to traverse the object like :

```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	for _, v in obj:GetIterator() do print(v) end
end)
```

For the **List** class, since it represents the array table, the **GetIterator** method just is the **ipairs**, it's not a powerful method, we'll see some special examples:

```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	-- print each elements
	obj:Each(print)

	-- print all even numbers
	obj:Filter(function(x) return x%2 == 0 end):Each(print)

	-- print the final three numbers
	obj:Range(-3, -1):Each(print)

	-- print all odd numbers
	obj:Range(1, -1, 2):Each(print)

	-- print 2^n of those numbers
	obj:Map(function(x) return 2^x end):Each(print)

	-- print the sum of the numbers
	print(obj:Reduce(function(x,y) return x+y end))
end)
```

There are two types of those method: the **queue** method like the **Range**, **Filter** and **Map**, the **final** method like **Each**, **Reduce** and others.

The queue method is used to queue operations with options, and when the final method is called, the queue operations'll be converted to a whole iterator so the final method can traverse the result to do the jobs. Those queue operations'll be saved to a stream worker object, so if we disassemble the above operation will be like:

```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	-- obj:Range(1, -1, 2)::Map(function(x) return 2^x end):Each(print)
	-- get a stream worker for next operations
	local worker = obj:Range(1, -1, 2)

	-- the same worker
	worker = worker:Map(function(x) return 2^x end)

	-- the final method
	for _, v in worker:GetIterator() do
		print(v)
	end
end)

```

* since the stream workers are inner objects that don't need be controlled by the users, the system can recycle them and re-use them for the next stream operations. So there is no need to care about the inner operations.

* unlike other list operations libs, there is no cache or anonymous method created during those operations, so you can do it thousands times without the GC working. We'll see more details in the **Thread** part.

Here is a full method list of the queue method:

Method                                   |Description
:----------------------------------------|:--------------------------------
Filter(self, func)                       |pass the list elements into the function, if the return value is non-false, the element would be used for next operations
Filter(self, name, value)                |If the `element[name] == value`, the element would be used for next operations
Map(self, func)                          |pass the list elements into the function and use the return value as new elements for next operations
Map(self, name)                          |use the `element[name]` as the new elements for next operations
Range(self[, start[, stop[, step]]])     |Only the elements in the range and fit to the step will be used for next operations, the *start*'s default value is 1, the *stop* is -1 and the *step* is 1

Here is a full list of the final method:

Method                                   |Description
:----------------------------------------|:--------------------------------
All(self, func, ...)                     |pass the element with ... into the function, if the return value is false or nil, the final result is false, if all elements passed the function checking, the final result is true
Any(self, func, ...)                     |pass the element with ... into the function, if any return value is non-false, the final result is true, if all elements can't pass the function checing, the final result is false
Each(self, func, ...)                    |call the function with each elements and the ... argument
Each(self, name, ...)                    |if the `element[name]` is the element's method(function), the object method will be called with those ... argument, otherwise `element[name] = ...` will be used
First(self, func, ...)                   |pass the element with ... into the function, if the return value is non-false, return the current element
First(self)                              |return the first element if existed
FirstOrDefault(self, default, func, ...) |pass the element with ... into the function, if any return value is non-false, return the current element, otherwise return the default value
FirstOrDefault(self, default)            |return the first element if existed, otherwise return the default value
Reduce(self, func[, init])               |used to combine the elements, you can find the example in the above
ToList(self[, listtype])                 |save the elements into a new list type object, the default listtype is the **List**


### The sort of the List

The **List** is an indexed list, so we have orders, we also can sort the elements based on a compare rules, there are several sort methods for the List:

Sort                                            |Description
:-----------------------------------------------|:--------------------------------
Reverse(self[, start[, stop]])                  |Reverse the indexed list, the start's default is 1, the stop is -1, it's a *sort* method since it'd change the list itself
BubbleSort(self, [compare[, start[, stop]]])    |Use the bubble sort on the indexed list, the default compare is function(x, y) return x < y end
CombSort(self, [compare[, start[, stop]]])      |Use the comb sort on the indexed list
HeapSort(self, [compare[, start[, stop]]])      |Use the heap sort on the indexed list
InsertionSort(self, [compare[, start[, stop]]]) |Use the insertion sort on the indexed list
MergeSort(self, [compare[, start[, stop]]])     |Use the merge sort on the indexed list
QuickSort(self, [compare[, start[, stop]]])     |Use the quick sort on the indexed list
SelectionSort(self, [compare[, start[, stop]]]) |Use the selection sort on the indexed list
Sort(self, [compare[, start[, stop]]])          |Use the lua's table.sort on the indexed list
TimSort(self, [compare[, start[, stop]]])       |Use the tim sort on the indexed list

So here is a test code:

```lua
require "PLoop"

PLoop(function(_ENV)
	local random = math.random
	local function val() return random(500000) end

	function test(cnt, sortMethod)
		collectgarbage()

		local st = os.clock()

		for i = 1, cnt do
			local lst = List(1000, val)
			lst[sortMethod](lst)
		end

		print(sortMethod, "Cost", os.clock() - st)
	end

	test(100, "BubbleSort")
	test(100, "CombSort")
	test(100, "HeapSort")
	test(100, "InsertionSort")
	test(100, "MergeSort")
	test(100, "QuickSort")
	test(100, "SelectionSort")
	test(100, "Sort")
	test(100, "TimSort")
end)
```

The test result in Lua 5.1 is :

```
BubbleSort      Cost    13.916
CombSort        Cost    0.422
HeapSort        Cost    0.484
InsertionSort   Cost    4.772
MergeSort       Cost    0.535
QuickSort       Cost    0.281
SelectionSort   Cost    6.417
Sort            Cost    0.109
TimSort         Cost    0.547
```

So the table.sort is still the best choice(but not a stable choice). But for the luajit:

```
BubbleSort      Cost    0.269
CombSort        Cost    0.033
HeapSort        Cost    0.038
InsertionSort   Cost    0.125
MergeSort       Cost    0.046
QuickSort       Cost    0.018
SelectionSort   Cost    0.075
Sort            Cost    0.084
TimSort         Cost    0.036
```

The luajit is very efficient in repeatable works.


### The creation of the Dictionary

Like the **List**, we also have several ways to create a **Dictionary** object:

Constructor                      |Result
:--------------------------------|:--------------------------------
Dictionary()                     |Create an empty dictionary object
Dictionary(table)                |Convert the input table as a dictionary object
Dictionary(table, table)         |the two tables must be array table, the first table's elements would be used as keys and the second table's element would be used as values to create the dictionary
Dictionary(listKey, listValue)   |Use the first list's elements as keys and the second list's elements as values to create the dictionary
Dictionary(dictionary)           |Copy other dictionary's key-value pairs to create a new dictionary
Dictionary(iter, obj, index)     |Use key, value pairs generated by the iterator to create a new dictionary

Here is some examples:

```lua
require "PLoop"

PLoop(function(_ENV)
	Dictionary(_G) -- Convert the _G to a dictionary

	-- key map to key^2
	lst = List(10)
	Dictionary(lst, lst:Map(function(x)return x^2 end))
end)
```

### The method of the Dictionary

The dictionary are normally hash tables, you can use **pairs** to traverse them or use `obj[key] = value` to modify them, the **Dictionary** only provide the **GetIterator** method, it's just the **pairs**.


### The traverse of the Dictionary

Like the **List**, we also have queue methods and final methods for the **Dictionary**.

The queue method:

Method                                   |Description
:----------------------------------------|:--------------------------------
Filter(self, func)                       |Pass the key-value pair into the function, if the return value is non-false, the key-value pair should be used in next operations
Map(self, func)                          |Pass the key-value pair into the function, use the return value as new value with the key into next operations

The final method:

Method                                   |Description
:----------------------------------------|:--------------------------------
Each(self, func, ...)                    |Pass each key-value pairs into the function
GetKeys(self)                            |Return an iterator used like `for index, key in dict:GetKeys() do print(key) end`
GetValues(self)                          |Return an iterator used like `for index, value in deict:GetValues() do print(value) end
Reduce(self, func, init)                 |Combie the key-value pairs, we'll see an example later

There are also final properties for the **Dictionary**:

Property                                 |Description
:----------------------------------------|:--------------------------------
Keys                                     |Get a list stream worker of keys
Values                                   |Get a list stream worker of the values

With the final properties we can use list operations on those keys or values.

Here are some examples:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- print all keys in the _G with order
	Dictionary(_G).Keys:ToList():Sort():Each(print)

	-- Calculate the sum of the values
	print(Dictionary{ A = 1, B = 2, C = 3}:Reduce(function(k, v, init) return init + v end, 0))
end)

```

The queue and final methods are not defined in the **List** and **Dictionary**, so we may create other list or dictionary types and use those methods, we'll see more about it after we have learn the class and interface part.


## Attribute and Thread Pool

We have see how to use classes in the previous example, for the second example, I'll show special usage of the **PLoop** environment:

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

Unlike the `_G`, the **PLoop** environments are very sensitive about new variables, when the *iter* is defiend, the system will check if there is any attribtues should be applied on the function, here we have the `__Iterator__()`.

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

The list stream workers's **GetIterator** is using this mechanism, so it don't need to generate any cache or anonymous function to do the jobs.

Also you can use *coroutine.wrap* to do the same job, but the different is, the **PLoop** is using thread pools to generate coroutines for those functions and recycle the coroutines when those function have done their jobs:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Async__()
	function printco(i, j)
		print(coroutine.running())
	end

	-- you'll get the same thread
	for i = 1, 10 do
		printco()
	end
end)
```

The **Thread Pool** will reduce the cost of the coroutine's creation and also avoid the GC for those coroutines. The attributes like `__Async__` and `__Iterator__` have eliminated the management of coroutines, you only need to focus on the async logics.


## Spell Error Checks And More

There are a lots of troubles in the Lua debugging, if the lua error can be triggered, it's still easy to fix it, but for codes like `if a == ture then`, *ture* is a non-existent variable, Lua treate it as nil so the checking will still working, but the result can't be right.

We'll see how to solve it in the **PLoop**.

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

Another spell error is for object fields:

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

To define an enum within the PLoop, the syntax is

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

### System.Enum

The **System.Enum** is a reflection type for the enums, we can use it to provide informations about the enums, here is a list of usable methods(not all, many are used only by the system):

Static Method                   |Description
:-------------------------------|:-----------------------------
GetDefault(enum)                |Get the default value of the enum
GetEnumValues(enum[, cache])    |if cache existed, save all key-value pairs into the cache and return it, or return an iterator to be used in a generic for
IsFlagsEnum(enum)               |Whether the enum is a flags enumeration
IsImmutable(enum)               |always return true, all enum types are immutable, that means the value won't change when it pass the validation of the enum types
IsSealed(enum)                  |Whether the enum is sealed, so can't be re-defined
Parse(enum, value)              |The same like enum(value), used to convert the value to the key, or return an iterator if the enum is a flags enumeration
ValidateFlags(check, target)    |whether the target contains the check value, used for flags enumerations
ValidateValue(enum, value)      |Used to validate the value with the enum, return nil if not valid, return the value if valid
Validate(target)                |Whether the target is an enumeration

So, there are two unknow APIs in the list : the **GetDefault** and the **IsSealed**, there are also attribute classes related to them :

```lua
require "PLoop"

PLoop(function(_ENV)
	__Default__("North") __AutoIndex__()
	enum "Direction" {
		"North",
		"East",
		"South",
		"West",
	}

	print(Enum.GetDefault(Direction)) -- 1

	--if not sealed, the new definition will override all
	__Sealed__()
	enum "Direction" { North = "N", East = "E", South = "S", West = "W" }

	print(Enum.GetDefault(Direction)) -- nil

	-- We still can add more key-value pairs into it
	enum "Direction" { Center = "C" }

	-- We can't override existed key or values
	-- Error: Usage: enum.AddElement(enumeration, key, value[, stack]) - The key already existed
	enum "Direction" { North = 1 }

	-- Error: Usage: enum.AddElement(enumeration, key, value[, stack]) - The value already existed
	enum "Direction" { C = "N" }
end)
```

The `System.__Default__` attribute is used to set the default value of the enum, it's no use in the enum itself, we'll see the usage in other parts.

The `System.__Sealed__` is used to seal the enum type, so others can't override them, but they may expand it.


## struct

The structures are types for basic and complex organized datas and also the data contracts for value validation. There are three struct types:

### Custom

The basic data types like number, string and more advanced types like nature number. Take the *Number* as an example:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- Env A
	struct "Number" (function(_ENV)
		-- Env B
		function Number(value)
			return type(value) ~= "number" and "the %s must be number, got " .. type(value)
		end
	end)

	v = Number(true)  -- Error : the value must be number, got boolean
end)
```

Like using **PLoop** to run codes in private environment, we also use this calling style on the definition of the struct types(also for class, interface), the function to be called is the type's definition body.

The environment *Env B* for the type's defintion is special designed:

* since the struct is defined in the *Env A*, so the *Env B*'s base environment is the *Env A*,  it can access anything defined or imported in the *Env A*.

* the *Env B* is special designed for struct's defintion, so it'll pass special assignments as the type's definition, the function with the same name of the type should be used as the struct's **validator**, also you could use the `__valid` as the validator's name(for anonymous struct like `struct (function(_ENV) function __valid(val) end end)`).

The validator is used to validate the input value, if the return value is non-false, that means the target value can't pass the validation, normally the return value should be an error message, the `%s` in the message'll be replaced by words based on where it's used, if the return value is true, the system will generate the error message for it.

In some case, we may need to change the input value to another one, that's done within the *initializer* which is declared like :

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "AnyBool" (function(_ENV)
		function __init(value)
			return value and true or fale
		end
	end)
	print(AnyBool(1))  -- true
end)
```

The function named `__init` is the initializer, it's used to modify the target value, if the return value is non-nil, it'll be used as the new value.

We'll see a more usable example for it:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ Callable, Number, Number }
	function Calc(func, a, b)
		print(func(a, b))
	end

	Calc("x,y=>x+y", 1, 11) -- 12
	Calc("x,y=>x*y", 2, 11) -- 22
end)
```

The **System.Callable** is a combine type, it allow functions, callable object and a **System.Lambda** value, the lambda in **PLoop** is a simple string like `"x,y=>x+y"`, it'd be converted by the lambda struct type to a function. So the Calc function will always get a callable value.

The **List** and **Dictionary**'s method(queue, final, sort and etc) also use the **System.Callable** as it's function types, so we also can use them like :

```lua
require "PLoop"

PLoop(function(_ENV)
	List(10):Map("x=>x^2"):Each(print)
end)
```

That's how the initializer works.

The struct type can have one base struct so it will inherit the base struct's validator and initializer, the base struct's validator and initializer will be called before the struct's own:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Integer" (function(_ENV)
		__base = Number

		local floor = math.floor

		function Integer(value)
			return floor(value) ~= value and "the %s must be integer"
		end
	end)

	v = Integer(true)  -- Error : the value must be number, got boolean
	v = Integer(1.23)  -- Error : the value must be integer
end)
```

Like the enum, we also can provide a default value to the custom struct since they are normally basic datas:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Default__(0)
	struct "Integer" (function(_ENV)
		__base = Number
		__default = 0 -- also can use this instead of the __Default__

		local floor = math.floor

		function Integer(value)
			return floor(value) ~= value and "the %s must be integer"
		end
	end)

	print(Struct.GetDefault(Integer)) -- 0
end)
```

Also we can use the `__Sealed__` attribute to seal the struct, so it won't be re-defined:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Sealed__(0)
	struct "AnyBool" (function(_ENV)
		function __init(value)
			return value and true or fale
		end
	end)

	-- Error: Usage: struct.BeginDefinition(structure[, stack]) - The AnyBool is sealed, can't be re-defined
	struct "AnyBool" (function(_ENV)
		function __init(value)
			return value and true or fale
		end
	end)
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

The member structure represent tables with fixed fields of certain types. Take an example to start:

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

We already know the definition environment is special designed for the struct types, so if it found an assignment with a string key, a value of **System.AnyType**, the assignment will be consumed as the creation of a new member, the member type will be used to validate the value fields.

The member sturt can also be used as value constructor(and only the member struct can be used as constructor), the argument order is the same order as the declaration of it members.

The `x = Number` is the simplest way to declare a member to the struct, but there are other details to be filled in, here is the formal version:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		member "x" { type = Number, require = true }
		member "y" { type = Number, default = 0    }
	end)

	loc = Location{}            -- Error: Usage: Location(x, y) - x can't be nil
	loc = Location(100)
	print(loc.x, loc.y)         -- 100  0
end)
```

The **member** is a keyword can only be used in the definition body of a struct, it need a member name and a table contains several settings for the member(the field is case ignored, and all optional):

Field             |Description
:-----------------|:--------------
type              |the member's type, any value that match the **System.AnyType**
require           |boolean, Whether the member can't be nil.
default           |the default value of the member.

The member struct also support the validator and initializer :

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "MinMax" (function(_ENV)
		member "min" { Type = Number, Require = true }
		member "max" { Type = Number, Require = true }

		function MinMax(val)
			return val.min > val.max and "%s.min can't be greater than %s.max"
		end
	end)

	v = MinMax(100, 20) -- Error: Usage: MinMax(min, max) - min can't be greater than max
end)
```

Since the member struct's value are tables, we also can define struct methods that would be saved to those values:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		member "x" { Type = Number, Require = true }
		member "y" { Type = Number, Default = 0    }

		function GetRange(val)
			return math.sqrt(val.x^2 + val.y^2)
		end
	end)

	print(Location(3, 4):GetRange()) -- 5
end
```

We can also declare static methods that can only be used by the struct itself(also for the custom struct):

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		member "x" { Type = Number, Require = true }
		member "y" { Type = Number, Default = 0    }

		__Static__()
		function GetRange(val)
			return math.sqrt(val.x^2 + val.y^2)
		end
	end)

	print(Location.GetRange{x = 3, y = 4}) -- 5
end)
```

The `System.__Static__` is an attribute, it's used here to declare the next defined method is a static one.

In the previous example, we can give the custom struct a default value, now we'll see how the default value is used:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Number" (function(_ENV)
		__default = 0

		function Number(value)
			return type(value) ~= "number" and "the %s must be number"
		end
	end)

	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	loc = Location()
	print(loc.x, loc.y)         -- 0    0
end)
```

So the member would use the type's default value as its default value.

The member struct can also have base struct, it will inherit members, non-static methods, validator and initializer, but it's not recommended.

The system only provide one member struct type:

Member Type                   |Description
:-----------------------------|:-----------------------------
**System.Variable**           |represents variable, we'll see more in the overload topic

### Array

The array structure represent tables that contains a list of same type items. Here is an example to declare an array:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	struct "Locations" (function(_ENV)
		__array = Location
	end)

	v = Locations{ {x = true} } -- Usage: Locations(...) - the [1].x must be number
end)
```

The array structure also support methods, static methods, base struct, validator and initializer.

BTW. when serialize an array data to JSON, the system no need to check the elements in it to make sure it's an array, since it's marked as array struct.

The system only provide one array struct type:

Array Type                    |Description
:-----------------------------|:-----------------------------
**System.Variables**          |represents variables, we'll see more in the overload topics


### Table Style Definition

To simplify the definition of the struct, table can be used instead of the function as the definition body.

```lua
require "PLoop"

PLoop(function(_ENV)
	-- Custom struct
	__Sealed__()
	struct "Number" {
		__default = 0,  -- The default value

		-- the function with number index would be used as validator
		function (val) return type(val) ~= "number" end,

		-- Or you can clearly declare it
		__valid = function (val) return type(val) ~= "number" end,
	}

	struct "AnyBool" {
		__init = function(val) return val and true or false end,
	}

	-- Member struct
	struct "Location" {
		-- Like use the member keyword, just with a name field
		{ name = "x", type = Number, require = true },
		{ name = "y", type = Number, require = true },

		-- Define methods
		GetRange = function(val) return math.sqrt(val.x^2 + val.y^2) end,
	}

	-- Array struct
	-- A valid type with number index, also can use the __array as the key
	struct "Locations" { Location }
end)
```

### Reduce the validation cost

Let's return the first struct **Number**, the error message is generated during runtime, and in **PLoop** there are many scenarios we only care whether the value match the struct type, so we only need validation, not the error message(the overload system use this technique to choose function).

The validator can receive 2nd parameter which indicated whether the system only care if the value is valid, so we can avoid the generate of new strings when we only need validate it like:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Number" (function(_ENV)
		function Number(value, onlyvalid)
			if type(value) ~= "number" then return onlyvalid or "the %s must be number, got " .. type(value) end
		end
	end)

	-- The API to validate value with types (type, value, onlyvald)
	print(Struct.ValidateValue(Number, "test", true))   -- nil, true
	print(Struct.ValidateValue(Number, "test", false))  -- nil, the %s must be number, got string
end)
```

Also you can just return true so the system'll take care of the rest part.


### Combine type

If your value could be two or more types, you can combine those types like :

```lua
require "PLoop"

PLoop(function(_ENV)
	-- nil, the %s must be value of System.Number | System.String
	print(Struct.ValidateValue(Number + String, {}, false))
end)
```

You can combine types like enums, structs, interfaces and classes.


### Sub Type

If you need the value to be a struct who is a sub type of another struct, (a struct type is a sub type of itself), you can create it like `- Number` :

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Integer" { __base = Number, function(val) return math.floor(val) ~= val end }
	print(Struct.ValidateValue( - Number, Integer, false))  -- Integer
end)
```

You also can use the `-` operation on interface or class.


### System.Struct

Like the **System.Enum**, the **System.Struct** is a reflection type for the struct types, here is a usable api list:

Static Method                           |Description
:---------------------------------------|:-----------------------------
GetArrayElement(target)                 |Get the array element type of the target
GetBaseStruct(target)                   |Get the base struct type of the target
GetDefault(target)                      |Get the default value of the target
GetMember(target, name)                 |Get the member of the target with name
GetMembers(target[, cache])             |If cache existed, save all members into the cache with order and return it, otherwise return an iterator used in generic for
GetMethod(target, name)                 |Return the method and a bool value indicate whether the method is static
GetMethods(target[, cache])             |If the cache existed, save all methods with the name into the cache and return it, otherwise return an iterator used in generic for
GetStructCategory(target)               |Return the struct's category: CUSTOM, MEMBER, ARRAY
IsImmutable(target)                     |Whether the struct is immutable, so the value won't be changed through the validation
IsSubType(target, base)                 |Whether the target is a sub type of the base struct type
IsSealed(target)                        |Whether the target is sealed
IsStaticMethod(taret, name)             |Whether the target's method with the name is a static method
ValidateValue(target, value, onlyvalid) |Validate the value with struct type, return the validated value if passed, or return nil and an error message
Validate(target)                        |Whether the target is a struct type


### System.Member

We will get member object from the **Struct.GetMemeber** and **Struct.GetMembers** API, we also have a **System.Member** reflection type to get those member's informations:

Static Method                           |Description
:---------------------------------------|:-----------------------------
GetType(member)                         |Get the member's type
IsRequire(member)                       |Whether the member's value is required, can't be nil
GetName(member)                         |Get the member's name
GetDefault(member)                      |Get the member's default value

As an example:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	for index, member in Struct.GetMembers(Location) do
		print(member.GetName(member), Member.GetType(member))
	end
end)
```

The enum and struct are all data types, normally used for type validation. The interface and class types will provide a full OOP System for us.


## Class

The classes are types that abstracted from a group of similar objects. The objects generated by the classes are tables with fixed meta-tables.

A class can be defined within several parts:

### Class and Object Method

The methods are functions that be used by the classes and their objects. Take an example :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		function SetName(self, name)
			self.name = name
		end

		function GetName(self, name)
			return self.name
		end
	end)

	Ann = Person()
	Ann:SetName("Ann")
	print("Hello " .. Ann:GetName()) -- Hello Ann
end)
```

Like the struct, the definition body of the class _Person_ also should be a function with `_ENV` as its first parameter. In the definition, the global delcared functions will be registered as the class's method. Those functions should use _self_ as the first parameter to receive the objects.

When the definition is done, the class object's meta-table is auto-generated based on the class's definition layout. For the _Person_ class, it should be

```lua
{
	__index = { SetName = function, GetName = function },
	__metatable = Person,
}
```

The class can access the object method directly, and also could have their own method - static method:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Color" (function(_ENV)
		__Static__()
		function FromRGB(r, g, b)
			-- The object construct will be talked later
			return Color {r = r, g = g, b = b}
		end
	end)

	c = Color.FromRGB(1, 0, 1)
	print(c.r, c.g, c.b)
end)
```

The static method don't use _self_ as the first parameter since it's used by the class itself not its objects.

### Meta-data and object construction

The meta-data is a superset of the Lua's meta-method:

Key            |Description
:--------------|:--------------
`__add`        |the addition operation:             a + b  -- a is the object, also for the below operations
`__sub`        |the subtraction operation:          a - b
`__mul`        |the multiplication operation:       a * b
`__div`        |the division operation:             a / b
`__mod`        |the modulo operation:               a % b
`__pow`        |the exponentiation operation:       a ^ b
`__unm`        |the negation operation:             - a
`__idiv`       |the floor division operation:       a // b
`__band`       |the bitwise AND operation:          a & b
`__bor`        |the bitwise OR operation:           a | b
`__bxor`       |the bitwise exclusive OR operation: a~b
`__bnot`       |the bitwise NOToperation:           ~a
`__shl`        |the bitwise left shift operation:   a<<b
`__shr`        |the bitwise right shift operation:  a>>b
`__concat`     |the concatenation operation:        a..b
`__len`        |the length operation:               #a
`__eq`         |the equal operation:                a == b
`__lt`         |the less than operation:            a < b
`__le`         |the less equal operation:           a <= b
`__index`      |the indexing access:                return a[k]
`__newindex`   |the indexing assignment:            a[k] = v
`__call`       |the call operation:                 a(...)
`__gc`         |the garbage-collection
`__tostring`   |the convert to string operation:    tostring(a)
`__ipairs`     |the ipairs iterator:                ipairs(a)
`__pairs`      |the pairs iterator:                 pairs(a)
`__exist`      |the object existence checker
`__field`      |the init object fields, must be a table
`__new`        |the function used to generate the table that'd be converted to an object
`__ctor`       |the object constructor
`__dtor`       |the object destructor

There are several PLoop special meta-data, here are examples :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__ExistPerson = {}

		-- The existence checker, if the object existed, no need to create again
		-- it'll receive all arguments used to create the object
		-- its first argument is the class, this is for sub-classes
		function __exist(cls, name)
			if __ExistPerson[name] then
				print("An object existed with " .. name)
				return __ExistPerson[name]
			end
		end

		-- The Constructor, used to init the object with arguments
		-- the first argument is the new created object
		function __ctor(self, name)
			print("Call the Person's constructor with " .. name)
			__ExistPerson[name] = self
			self.name = name
		end

		-- The destructor, normally used to release the reference
		-- then leave the object to GC
		function __dtor(self)
			print("Dispose the object " .. self.name)
			__ExistPerson[self.name] = nil
		end
	end)

	o = Person("Ann")           -- Call the Person's constructor with Ann

	-- true
	print(o == Person("Ann"))   -- An object existed with Ann

	o:Dispose()                 -- Dispose the object Ann

	-- false
	print(o == Person("Ann"))   -- Call the Person's constructor with Ann
end)
```

Here is the constructor, the destructor and an existence checker. We also can find a non-declared method **Dispose**, all objects that generated by classes who have destructor settings will have the **Dispose** method, used to call it's class, super class and the class's extended interface's destructor with order to destruct the object, normally the destructor is used to release the reference of the object, so the Lua can collect them.

We also can use the **Dispose** instead of the `__dtor` to define the destructor, and use the class's name instead of the `__ctor` to define the constructor.

The `__new` meta is used to generate table that will be used as the object. You can use it to return tables generated by other systems or you can return a well inited table so the object's construction speed will be greatly increased like :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "List" (function(_ENV)
		function __new(cls, ...)
			return { ... }, true
		end
	end)

	v = List(1, 2, 3, 4, 5, 6)
end)
```

The `__new` would recieve the class and all parameters and return a table and a boolean value, if the value is true, all parameters will be discarded so won't pass to the constructor. So for the List class, the `__new` meta will eliminate the rehash cost of the object's initialization.

The `__field` meta is a table, contains several key-value paris to be saved in the object, normally it's used with the **OBJECT_NO_RAWSEST** and the **OBJECT_NO_NIL_ACCESS** options, so authors can only use existing fields to to the jobs, and spell errors can be easily spotted.

```lua
PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST   = true, OBJECT_NO_NIL_ACCESS= true, }

require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__field     = {
			name    = "noname",
		}

		-- Also you can use *field* keyword since `__field` could be error spelled
		field {
			age     = 0,
		}
	end)

	o = Person()
	o.name = "Ann"
	o.age  = 12

	o.nme = "King"  -- Error : The object can't accept field that named "nme"
	print(o.gae)    -- Error : The object don't have any field that named "gae"
end)
```

So, here is a fake code for the object's construction:

```lua
-- Check whether existed
local object = __exist(cls, ...)
if object then return object end

-- Get a table as the new object
object = __new(cls, ...) or {}

-- Clone the field
field:Copyto(object)

-- Wrap to the object
setmetatable(object, objMeta)

-- Call the constructor
__ctor(object, ...)

return object
```

### Super class and Inheritance

the class can and only can have one super class, the class will inherit the super class's object method, meta-datas and other features(event, property and etc).

If the class has override the super's object method, meta-data or other features, the class can use **super** keyword to access the super class's method, meta-data or feature.

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		-- Object method
		function Test(self)
			print("Call A's method")
		end

		-- Constructor
		function A(self)
			print("Call A's ctor")
		end

		-- Destructor
		function Dispose(self)
			print("Dispose A")
		end

		-- Meta-method
		function __call(self)
			print("Call A Object")
		end
	end)

	class "B" (function(_ENV)
		inherit "A"  -- also can use inherit(A)

		function Test(self)
			print("Call super's method ==>")
			super[self]:Test()
			super.Test(self)
			print("Call super's method ==<")
		end

		function B(self)
			super(self)
			print("Call B's ctor")
		end

		function Dispose(self)
			print("Dispose B")
		end

		function __call(self)
			print("Call B Object")
			super[self]:__call()
			super.__call(self)
		end
	end)

	-- Call A's ctor
	-- Call B's ctor
	o = B()

	-- Call super's method ==>
	-- Call A's method
	-- Call A's method
	-- Call super's method ==<
	o:Test()

	-- Call B Object
	-- Call A Object
	-- Call A Object
	o()

	-- Dispose B
	-- Dispose A
	o:Dispose()
end)
```

From the example, here are some details:

* The `inherit "A"` is a syntax sugar, is the same like `inherit(A)`.

* The destructor don't need call super's destructor, they are well controlled by the system, so the class only need to consider itself.

* The constructor need call super's constructor manually, since only the class know use what arguments to call the super class's constructor.

* For the object method and meta-method(include the `__new` and `__exist`, we have two style to call its super:

	* `super.Test(self)` is a simple version, it can only be used to call method or meta-method.

	* `super[self]:Test()` is formal version, since the self is passed to super before access the Test method, the super'd know the class version of the object and used the correct version methods. This is used for multi-version classes(by default, re-define a class would create two different version), also for features like properties and events(we'll see them later).


### System.Class

**System.Class** is a reflection type to provide informations about the classes:

Static Method                               |Description
:-------------------------------------------|:-----------------------------
GetExtends(target[, cache])                 |if cache existed, save extend interfaces into the cache and return it, otherwise return an iterator used in generic for to fetch the extend interfaces
GetFeature(target, name[, isobject])        |Get a type feature from the target with the name. If *isobject* is false, only type feature(include static) defined in the target will be returned, otherwise only object feature(include inherited) will be returned, same as below
GetFeatures(target, [cache[, isobject]])    |If cache existed, save all type features into the cache and return it, otherwise return an iterator used in generic for to fetch them
GetMethod(target, name[, isobject])         |Get a method from the target with the name
GetMethods(target[, cache[, isobject]])     |If cache existed, save all method into the cache and return it, otherwise return an iterator used in generic for to fetch them
GetMetaMethod(target, name[, isobject])     |Get a meta-method from the target with the name
GetMetaMethods(target[, cache[, isobject]]) |If cache existed, save all meta-method into the cache and return it, otherwise return an iterator used in generic for to fetch them
GetObjectClass(object)                      |Get the object's class
GetSuperClass(target)                       |Get the target's super class
GetSuperMethod(target, name)                |Get the target's super method with name
GetSuperMetaMethod(target, name)            |Get the target's super meta-method with the name
GetSuperFeature(target, name)               |Get the target's super type feature with the name
IsAbstract(target[, name])                  |Whether the class's method, meta-method or feature is abstract
IsFinal(target[, name])                     |Whether the class or its method, meta-method, feature is final
IsImmutable(target)                         |Always return true
IsSealed(target)                            |Whether the target is sealed
IsStaticMethod(target, name)                |Whether the class's given name method is static
IsSubType(target, super)                    |Whether the target class is a sub-type of another interface or class
ValidateValue(target, object)               |Whether the value is an object whose class is or inherit the target class
Validate(target)                            |Whether the target is a class


## Interface

The interfaces are abstract types of functionality, it also provided the multi-inheritance mechanism to the class. Like the class, it also support object method, static method and meta-datas.

The class and interface can extend many other interfaces, the **super** keyword also can access the extended interface's object-method and the meta-methods.

The interface use `__init` instead of the `__ctor` as the interface's initializer. The initializer only receive the object as it's parameter, and don't like the constructor, the initializer can't be accessed by **super** keyword. The method defined with the interface's name will also be used as the initializer.

If you only want defined methods and features that should be implemented by child interface or class, you can use `__Abstract__` on the method or the feature, those abstract methods and featuers can't be accessed by **super** keyword.

Let's take an example :

```lua
require "PLoop"

PLoop(function(_ENV)
	interface "IName" (function(self)
		__Abstract__()
		function SetName(self) end

		__Abstract__()
		function GetName(self) end

		-- initializer
		function IName(self) print("IName Init") end

		-- destructor
		function Dispose(self) print("IName Dispose") end
	end)

	interface "IAge" (function(self)
		__Abstract__()
		function SetAge(self) end

		__Abstract__()
		function GetAge(self) end

		-- initializer
		function IAge(self) print("IAge Init") end

		-- destructor
		function Dispose(self) print("IAge Dispose") end
	end)

	class "Person" (function(_ENV)
		extend "IName" "IAge"   -- also can use `extend(IName)(IAge)`

		-- Error: attempt to index global 'super' (a nil value)
		-- Since there is no super method(the IName.SetName is abstract),
		-- there is no super keyword can be use
		function SetName(self, name) super[self]:SetName(name) end

		function Person(self) print("Person Init") end

		function Dispose(self) print("Person Dispose") end
	end)

	-- Person Init
	-- IName Init
	-- IAge Init
	o = Person()

	-- IAge Dispose
	-- IName Dispose
	-- Person Dispose
	o:Dispose()
end)
```

From the example, we can see the initializers are called when object is created and already passed the class's constructor. The dispose order is the reverse order of the object creation. So, the class and interface should only care themselves.

### System.Interface

**System.Interface** is a reflection type to provide informations about the interfaces:

Static Method                               |Description
:-------------------------------------------|:-----------------------------
GetExtends(target[, cache])                 |if cache existed, save extend interfaces into the cache and return it, otherwise return an iterator used in generic for to fetch the extend interfaces
GetFeature(target, name[, isobject])        |Get a type feature from the target with the name. If *isobject* is false, only type feature(include static) defined in the target will be returned, otherwise only object feature(include inherited) will be returned, same as below
GetFeatures(target, [cache[, isobject]])    |If cache existed, save all type features into the cache and return it, otherwise return an iterator used in generic for to fetch them
GetMethod(target, name[, isobject])         |Get a method from the target with the name
GetMethods(target[, cache[, isobject]])     |If cache existed, save all method into the cache and return it, otherwise return an iterator used in generic for to fetch them
GetMetaMethod(target, name[, isobject])     |Get a meta-method from the target with the name
GetMetaMethods(target[, cache[, isobject]]) |If cache existed, save all meta-method into the cache and return it, otherwise return an iterator used in generic for to fetch them
GetSuperMethod(target, name)                |Get the target's super method with name
GetSuperMetaMethod(target, name)            |Get the target's super meta-method with the name
GetSuperFeature(target, name)               |Get the target's super type feature with the name
IsAbstract(target[, name])                  |Whether the interface's method, meta-method or feature is abstract
IsFinal(target[, name])                     |Whether the interface or its method, meta-method, feature is final
IsImmutable(target)                         |Always return true
IsSealed(target)                            |Whether the target is sealed
IsStaticMethod(target, name)                |Whether the target's given name method is static
IsSubType(target, super)                    |Whether the target is a sub-type of another interface
ValidateValue(target, object)               |Whether the value is an object whose class is extend the target interface
Validate(target)                            |Whether the target is an interface


## Event

The events are type features used to notify the outside that the state of class object has changed. Let's take an example to start :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		-- declare an event for the class
		event "OnNameChanged"

		field { name = "anonymous" }

		function SetName(self, name)
			if name ~= self.name then
				-- Notify the outside
				OnNameChanged(self, name, self.name)
				self.name = name
			end
		end
	end)

	o = Person()

	-- Bind a function as handler to the event
	function o:OnNameChanged(new, old)
		print(("Renamed from %q to %q"):format(old, new))
	end

	-- Renamed from "anonymous" to "Ann"
	o:SetName("Ann")
end)
```

The event is a feature type of the class and interface, there are two types of the event handler :

* the final handler     - the previous example has shown how to bind the final handler.

* the stackable handler - The stackable handler are normally used in the class's constructor or interface's initializer:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		-- declare an event for the class
		event "OnNameChanged"

		field { name = "anonymous" }

		function SetName(self, name)
			if name ~= self.name then
				-- Notify the outside
				OnNameChanged(self, name, self.name)
				self.name = name
			end
		end
	end)

	class "Student" (function(_ENV)
		inherit "Person"

		local function onNameChanged(self, name, old)
			print(("Student %s renamed to %s"):format(old, name))
		end

		function Student(self, name)
			self:SetName(name)
			self.OnNameChanged = self.OnNameChanged + onNameChanged
		end
	end)

	o = Student("Ann")

	function o:OnNameChanged(name)
		print("My new name is " .. name)
	end

	-- Student Ann renamed to Ammy
	-- My new name is Ammy
	o:SetName("Ammy")
end)
```

The `self.OnNameChanged` is an object generated by **System.Delegate** who has `__add` and `__sub` meta-methods so it can works with the style like

```lua
self.OnNameChanged = self.OnNameChanged + onNameChanged
```

or

```lua
self.OnNameChanged = self.OnNameChanged - onNameChanged
```

The stackable handlers are added with orders, so the super class's handler'd be called at first then the class's, then the interface's. The final handler will be called at the last, if any handler `return true`, the call process will be ended.

In some scenarios, we need to block the object's event, the **Delegate** can set an init function that'd be called before all other handlers, we can use

```lua
self.OnNameChanged:SetInitFunction(function() return true end)
```

To block the object's *OnNameChanged* event.


### The event of the event handler's changes

When using PLoop to wrap objects generated from other system, we may need to bind the PLoop event to other system's event, there is two parts in it :

* When the PLoop object's event handlers are changed, we need know when and whether there is any handler for that event, so we can register or un-register in the other system.

* When the event of the other system is triggered, we need invoke the PLoop's event.

Take the *Frame* widget from the *World of Warcraft* as an example, ignore the other details, let's focus on the event two-way binding :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Frame" (function(_ENV)
		__EventChangeHandler__(function(delegate, owner, eventname)
			-- delegate is the object whose handlers are changed
			-- owner is the frame object, also the owner of the delegate
			-- eventname is the OnEnter for this case
			if delegate:IsEmpty() then
				-- No event handler, so un-register the frame's script event
				owner:SetScript(eventname, nil)
			else
				-- Has event handler, so we must regiser the frame's script event
				if owner:GetScript(eventname) == nil then
					owner:SetScript(eventname, function(self, ...)
						-- Call the delegate directly
						delegate(owner, ...)
					end)
				end
			end
		end)
		event "OnEnter"
	end)
end)
```

With the `__EventChangeHandler__` attribute, we can bind a function to the target event, so all changes of the event handlers can be checked in the function. Since the event change handler has nothing special with the target event, we can use it on all script events in one system like :

```lua
require "PLoop"

PLoop(function(_ENV)
	local function changehandler (delegate, owner, eventname)
		if delegate:IsEmpty() then
			owner:SetScript(eventname, nil)
		else
			if owner:GetScript(eventname) == nil then
				owner:SetScript(eventname, function(self, ...)
					-- Call the delegate directly
					delegate(owner, ...)
				end)
			end
		end
	end

	function __WidgetEvent__(self)
		__EventChangeHandler__(changehandler)
	end

	class "Frame" (function(_ENV)
		__WidgetEvent__()
		event "OnEnter"

		__WidgetEvent__()
		event "OnLeave"
	end)
end)
```

### Static event

The event can also be marked as static, so it can be used and only be used by the class or interface :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__Static__()
		event "OnPersonCreated"

		function Person(self, name)
			OnPersonCreated(name)
		end
	end)

	function Person.OnPersonCreated(name)
		print("Person created " .. name)
	end

	-- Person created Ann
	o = Person("Ann")
end)
```

### super event

When the class or interface has overridden the event, and they need register handler to super event, we can use the super object access style :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		-- declare an event for the class
		event "OnNameChanged"

		field { name = "anonymous" }

		function SetName(self, name)
			if name ~= self.name then
				-- Notify the outside
				OnNameChanged(self, name, self.name)
				self.name = name
			end
		end
	end)


	class "Student" (function(_ENV)
		inherit "Person"

		event "OnNameChanged"

		local function raiseEvent(self, ...)
			OnNameChanged(self, ...)
		end

		function Student(self)
			super(self)

			-- Use the super object access style
			super[self].OnNameChanged = raiseEvent
		end
	end)

	o = Student()

	function o:OnNameChanged(name)
		print("New name is " .. name)
	end

	-- New name is Test
	o:SetName("Test")
end)
```

As we can see, the child class can listen the super's event and then raise its own event.

### System.Event

**System.Event** is a reflection type to be used to get informations about the event:

Static Method                               |Description
:-------------------------------------------|:-----------------------------
Get(target, object[, nocreation])           |Get the event delegate from the object, if nocreation is non-true, the delegate will be created if not existed
GetEventChangeHandler(target)               |Get the handler registered by `__EventChangeHandler__`
IsStatic(target)                            |Whether the event is static
Validate(target)                          	|Whether the target is an event

A simple example:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__Static__()
		event "OnPersonCreated"
	end)

	for name, feature in Class.GetFeatures(Person) do
		if Event.Validate(feature) then
			print("event", name)
		end
	end
end)
```


## Property

The properties are object states, we can use the table fields to act as the object states, but they lack the value validation, and we also can't track the modification of those fields.

Like the event, the property is also a feature type of the interface and class. The property system provide many mechanisms like get/set, value type validation, value changed handler, value changed event, default value and default value factory. Let's start with a simple example :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String }
		property "Age"  { type = Number }
	end)

	-- If the class has no constructor, we can use the class to create the object based on a table
	-- the table is called the init-table
	o = Person{ Name = "Ann", Age = 10 }

	print(o.Name)-- Ann
	o.Name = 123 -- Error : the Name must be string, got number
end)
```

The **Person** class has two properties: *Name* and *Age*, the table after `property "Name"` is the definition of the *Name* property, it contains a *type* field that contains the property value's type, so when we assign a number value to the *Name*, the operation is failed.

Like the **member** of the **struct**, we use table to give the property's definition, the key is case ignored, here is a full list:

Field           |Usage
:---------------|:-------------
auto            |whether use the auto-binding mechanism for the property see blow example for details.
get             |the function used to get the property value from the object like `get(obj)`, also you can set **false** to it, so the property can't be read
set             |the function used to set the property value of the object like `set(obj, value)`, also you can set **false** to it, so the property can't be written
getmethod       |the string name used to specified the object method to get the value like `obj[getmethod](obj)`
setmethod       |the string name used to specified the object method to set the value like `obj[setmethod](obj, value)`
field           |the table field to save the property value, no use if get/set specified, like the *Name* of the **Person**, since there is no get/set or field specified, the system will auto generate a field for it, it's recommended.
type            |the value's type, if the value is immutable, the type validation can be turn off for release version, just turn on **TYPE_VALIDATION_DISABLED** in the **PLOOP_PLATFORM_SETTINGS**
default         |the default value
event           |the event used to handle the property value changes, if it's value is string, an event will be created:
handler         |the function used to handle the property value changes, unlike the event, the handler is used to notify the class or interface itself, normally this is used combine with **field** (or auto-gen field), so the class or interface only need to act based on the value changes :
static          |true if the property is a static property

We'll see examples for each case:

### get/set

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		field { __name = "anonymous" }

		property "Name" {
			get = function(self) return self.__name end,
			set = function(self, name) self.__name = name end,
		}
	end)

	print(Person().Name)
end)
```

### getmethod/setmethod

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		field { __name = "anonymous" }

		function SetName(self, name)
			self.__name = name
		end

		function GetName(self)
			return self.__name
		end

		property "Name" {
			get = "GetName", -- or getmethod = "GetName"
			set = "SetName", -- or setmethod = "SetName"
		}
	end)

	print(Person().Name)
end)
```

### field & default

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { field = "__name", default = "anonymous" }
	end)

	obj = Person()
	print(obj.Name, obj.__name) -- anonymous   nil
	obj.Name = "Ann"
	print(obj.Name, obj.__name) -- Ann         Ann
end)
```

### default factory

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Age" { field = "__age", default = function(self) return math.random(100) end }
	end)

	obj = Person()
	print(obj.Age, obj.__age) -- 81   81
	obj.Age = nil   -- so the factory will works again
	print(obj.Age, obj.__age) -- 88   88
end)
```

### property-event

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String, event = "OnNameChanged" }
	end)

	o = Person { Name = "Ann" }

	function o:OnNameChanged(new, old, prop)
		print(("[%s] %s -> %s"):format(prop, old, new))
	end

	-- [Name] Ann -> Ammy
	o.Name = "Ammy"
end)
```

### property-handler

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" {
			type = String, default = "anonymous",

			handler = function(self, new, old, prop)
				print(("[%s] %s -> %s"):format(prop, old, new))
			end
		}
	end)

	--[Name] anonymous -> Ann
	o = Person { Name = "Ann" }

	--[Name] Ann -> Ammy
	o.Name = "Ammy"
end)
```

### static property

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__Static__()
		property "DefaultName" { type = String }

		property "Name" {
			type = String, default = function() return Person.DefaultName end,
		}
	end)

	Person.DefaultName = "noname"

	print(Person().Name) -- noname
end)
```

### Auto-binding

If using the auto-binding mechanism and the definition don't provide get/set, getmethod/setmethod and field, the system will check the property owner's method(object method if non-static, static method if it is static), take an example if our property name is "name":

* The *setname*, *Setname*, *SetName*, *setName* will be scanned, if it existed, the method will be used as the **set** setting

* The *getname*, *Getname*, *Isname*, *isname*, *getName*, *GetName*, *IsName*, *isname* will be scanned, if it exsited, the method will be used as the **get** setting

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		function SetName(self, name)
			print("SetName", name)
		end

		property "Name" { type = String, auto = true }
	end)

	-- SetName  Ann
	o = Person { Name = "Ann"}

	-- SetName  Ammy
	o.Name = "Ammy"
end)
```

### super property

When the class or interface has overridden the property, they still can use the super object access style to use the super's property :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String }
	end)

	class "Student" (function(_ENV)
		inherit "Person"

		property "Name" {
			Set = function(self, name)
				-- Use super property to save
				super[self].Name = name
			end,
			Get = function(self)
				-- Use super property to fetch
				return super[self].Name
			end,
		}
	end)

	o = Student()
	o.Name = "Test"
	print(o.Name)   -- Test
end)
```

### indexer property

We also can build indexer properties like :

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function( _ENV )
		__Indexer__()
		property "Items" {
			set = function(self, idx, value)
				self[idx] = value
			end,
			get = function(self, idx)
				return self[idx]
			end,
			type = String,
		}
	end)

	o = A()

	o.Items[1] = "Hello"

	print(o.Items[1])   -- Hello
end)
```

The indexer property can only accept set, get, getmethod, setmethod, type and static definitions.

### Get/Set Modifier

Beside those settings, we still can provide some behavior modifiers on the properties.

For property set, we have **System.PropertySet** to describe the value set behavior:

```lua
__Flags__() __Default__(0)
enum "System.PropertySet" {
	Assign      = 0,  -- assign directly
	Clone       = 1,  -- save the clone of the value
	DeepClone   = 2,  -- save the deep clone of the value
	Retain      = 4,  -- should dispose the old value
	Weak        = 8,  -- save the value as weak mode
}
```

For property get, we have **System.PropertyGet** to describe the value get behavior:

```lua
__Flags__() __Default__(0)
enum "System.PropertyGet" {
	Origin      = 0,  -- return the value directly
	Clone       = 1,  -- return a clone of the value
	DeepClone   = 2,  -- return a deep clone of the value
}
```

To apply them on the property, we need `System.__Set__` and `System.__Get__` attributes:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Data" (function(_ENV)
		extend "ICloneable"  -- cloneable class must extend this interface

		local _Cnt = 0

		-- Implement the Clone method
		function Clone(self)
			return Data() -- for test, just return a new one
		end

		function Dispose(self)
			print("Dispose Data " .. self.Index)
		end

		function __ctor(self)
			_Cnt = _Cnt + 1
			self.Index = _Cnt
		end
	end)

	class "A" (function(_ENV)
		__Set__(PropertySet.Clone + PropertySet.Retain)
		__Get__(PropertySet.Clone)
		property "Data" { type = Data }
	end)

	o = A()

	dt = Data()

	o.Data = dt
	print(dt.Index, o.Data.Index)  -- 1  3
	o.Data = nil   -- Dispose Data 2
end)
```

### System.Property

**System.Property** is a reflection type used to provide informations about the properties.

Static Method                |Description
:----------------------------|:-----------------------------
IsGetClone(target)           |Whether the property should return a clone copy of the value
IsGetDeepClone(target)       |Whether the property should return a deep clone copy of the value
IsIndexer(target)            |Whether the property is an indexer property, used like `obj.prop[xxx] = xxx`
IsReadable(target)   		 |Whether the property is readable
IsSetClone(target)           |Whether the property should save a clone copy to the value
IsSetDeepClone(target)       |Whether the property should save a deep clone copy to the value
IsRetainObject(target)       |Whether the property should dispose the old value
IsStatic(target)             |Whether the property is static
IsWeak(target)               |Whether the property value should kept in a weak table
IsWritable(target)           |Whether the property is writable
GetDefault(target)           |Get the property default value
GetType(target)              |Get the property type
Validate(target)             |Wether the target is a property

Here is an example:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String }
		property "Age"  { type = Number }
	end)

	for name, feature in Class.GetFeatures(Person) do
		if Property.Validate(feature) then
			print(name, Property.GetType(feature))
		end
	end
end)
```

We have see all feature types provided by the **PLoop**, but there are still many details should be discussed.


## Namespace and Anonymous types

The namespaces are used to manage types, we can save types into the namespaces so each type will have an unique access path like **System.Collections.List**. We can use the **import** keyword to import namespaces into private environment, so those types can be shared by anywhere.

Types are saved to namespaces when they are defined, here is an example to show all scenarios:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- we can use the namespace keyword to declare
	-- a namespace for current environment
	-- all types generated in the environment will
	-- be saved to the namespace with its name
	namespace "Test"

	class "A" (function(_ENV)
		-- the namespace of the type's definition body
		-- is the type itself, so any types defined here
		-- will be a sub-namespace of the type(the class A)
		enum "Type" { Data = 1, Object = 2 }
	end)

	-- If we define a type with a full access path
	-- the type won't save to the environment's namespace
	-- it'll be saved to the path
	class "Another.B" (function(_ENV)
		enum "Type" { Data = 1, Object = 2 }
	end)

	print(A)      -- Test.A
	print(A.Type) -- Test.A.Type

	print(B)      -- Another.B
	print(B.Type) -- Another.B.Type
end)
```

We also can define anonymous types that we don't want to share with others, just remove the type name from the definition:

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "Test"

	class "A" (function(_ENV)
		Type = enum { Data = 1, Object = 2 }

		print(Data)      -- 1
		print(Type.Data) -- 1
	end)

	-- we have no way to get the A.Type
	print(A.Type)        -- nil
end)
```

### System.Namespace

We also have a reflection type **System.Namespace** to provide informations about the namespaces(also include those types):

Static Method                        |Description
:------------------------------------|:-----------------------------
ExportNamespace(env, ns[, override]) |Export a namespace and its children to an environment
GetNamespace([root,] path)           |Get the namespace by path
GetNamespaceName(ns, onlyname)       |Get the namespace's path or name
IsAnonymousNamespace(target)         |Whether the target is an anonymous namespace
Validate(target)                     |Whether the target is a namespace


## The Environment

The private environment is the basic element for the **PLoop**.

### Code Isolated

The codes are isolated by those environments, so we don't need to take care the usage of the global variables.

```lua
require "PLoop"

PLoop(function(_ENV)
	function Test()
	end
end)

print(Test) -- nil

PLoop(function(_ENV)
	print(Test)  -- nil
end)
```

We should share those features by types.

### Share types

The environments allow us to import namespaces so we can share types between them easily.

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "Test"

	class "A" (function(_ENV)
		enum "Type" { Data = 1, Object = 2 }
	end)
end)

PLoop(function(_ENV)
	print(A)      -- nil

	-- Root namespace can be accessed directly
	print(Test.A) -- Test.A

	-- Use import keyword to import namespaces
	import "Test"

	-- Now we can access Test.A directly
	print(A)      -- Test.A

	print(Data)   -- nil

	import "Test.A.Type"

	-- The environment check the imported namespace like
	-- ns[name], if the result is not nil, it'll be used
	-- the environment don't care whether the return value
	-- is another namespace or type
	print(Data)   -- 1
end)
```

### Attribute for global functions

Any global functions defined in it can have attributes, so we easily modify those functions or register them for other usages. Take an example from the [PLoop_Web](https://github.com/kurapica/PLoop_Web):

```lua
require "PLoop_Web"

Application "WebApplication"(function(_ENV)
	-- This is used to bind a http request handler to an url like
	-- /nginx?var=request_uri
	-- The __Route__ is used bind the function to the url
	-- The __text__ is used to mark the function's output should
	-- be send to the client as "text/plain"
 	__Route__ "/nginx"
 	__Text__()
	function GetVars(context)
		return ngx.var[context.Request.QueryString["var"] or "nginx_version"]
	end
end)
```

### Namespace as caller

So, what's the **PLoop**, we used it for each examples, it's the root of the namesapces, all root namespaces like **System** is saved as the **PLoop**'s sub-namespace:

```lua
require "PLoop"

print(PLoop.System.Collections.List) -- System.Collections.List
```

So, it's also a namespace but we can't access by paths. We can use other namespaces(the real namespace created by **namespace** keyword, not types) to replace the **PLoop** like:

```lua
require "PLoop"

namespace "Test" (function(_ENV)
	enum "A" {}

	print(A)  -- Test.A
end)
```

So if we use a namespace as the caller, the funtion environment's namespace is the caller.

But this isn't recommend, because **PLoop** will only make sure the **PLoop** in the `_G` is from the **PLoop** lib, the keyword like **class**, **namespace** may come from other systems, this is also why **PLoop** need codes to be processed in those private environments, to make sure The **PLoop** won't conflict with other Lua libs.


### The global variable access

When a global variable not existed in the private environment and the codes has accessed it, the private environment should check it with orders:

* Find in the namespace that the environment belongs

* Find in the namespace of this environment **import**ed

* Find in public namespaces

* Try match the root namespaces, like "**System**"

* Find in the base environment, the private environment can set a base environment, default is the `_G`

The rules for finding variable names in the namespace are:

* Compare to the name of the namespace (the last part of the path, so for the **System.Form**, its name is **Form**), if match return the namespace directly

* Try get value by `ns[name]`, usually the result will be a sub-namespace such as `System["Form"]` which gets **System.Form**, or a type such as `System.Collections[" List "]`, also could be a resource provided by the type, like a static method of the class, enumeration value of a enum type and etc.

```lua
require "PLoop"

PLoop (function(_ENV)
	namespace "Test"

	enum "A" {}
	enum "Test2.B" {}

	namespace "Another"
end)

PLoop (function(_ENV)
	namespace "Test"

	-- Access the type in the same namespace of Test
	print(A)     -- Test.A

	import "Test2"

	-- Access the type in the imported namespace
	print(B)     -- Test2.B

	-- Access the public namespaces
	print(List)  -- System.Collections.List

	-- Access the root namespace
	print(Another) -- Another

	-- Access the base environment
	print(math)    -- table:xxxxxxx
end)
```

### Auto-cache

To improve the performance, when the private environment access a global variable not existed in itself, it'll try to cache the value in it during runtime, but won't do the auto-cache job during the definition phase.

```lua
require "PLoop"

PLoop (function(_ENV)
	-- System.Collections.List  nil
	print(List, rawget(_ENV, "List"))

	_G.Dojob = function()
		print(List, rawget(_ENV, "List"))
	end
end)

-- System.Collections.List  System.Collections.List
Dojob()
```

When the function called by the **PLoop** processing, the codes are running in definition phase, and those codes only will be executed for once, there is no need to cache those global variables since they only will be accessed for one shot.

When we call the `Dojob()`, the codes is processed in runtime phase, we may call the function again and again, so it's time to save those global variables in the private environment.

Those are controlled by the system, so you don't need to take care about it.


## Overload

We have see examples about the function argument validation, but the design goal of the `System.__Arguments__` is for the overload methods.

As we see in the creation of the List objects, we have plenty ways to create the object with different arguments styles, it's very hard for us to write the codes manually to diff those arguments styles, and we also need do the same job for other constructors and methods.

With the `__Arguments__`, we can leave the choice to the system:

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ String }
		function SetInfo(self, name)
			print("The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function SetInfo(self, age)
			print("The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function SetInfo(self, name, age)
			self:SetInfo(name)
			self:SetInfo(age)
		end
	end)

	o = Person()

	-- The name is Ann
	-- The age is 24
	o:SetInfo("Ann", 24)
end)
```

So we can bind several functions as one method, constructor or meta-method.

If we need to call the other overload functions of the same name, we'd keep using the `obj:method(xxx)` format with different arguments styles.


### this For object constructor

It's a little different to call the overload functions for the object constructor : `__exist`, `__new`, `__ctor`. Since we can't call them by using the object-method styles.

The overload system provide a keyword **this**(not provided by the class system, the class know nothing about it), we only need use `this(...)` in those overload functions to call itself:

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ String }
		function __exist(self, name)
			print("[exist]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function __exist(self, age)
			print("[exist]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function __exist(self, name, age)
			this(self, name)
			this(self, age)
		end

		__Arguments__{ String }
		function __new(self, name)
			print("[new]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function __new(self, age)
			print("[new]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function __new(self, name, age)
			this(self, name)
			this(self, age)
		end

		__Arguments__{ String }
		function Person(self, name)
			print("[ctor]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function Person(self, age)
			print("[ctor]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function Person(self, name, age)
			this(self, name)
			this(self, age)
		end
	end)

	-- [exist]The name is Ann
	-- [exist]The age is 12
	-- [new]The name is Ann
	-- [new]The age is 12
	-- [ctor]The name is Ann
	-- [ctor]The age is 12
	o = Person("Ann", 12)
end)
```

You shouldn't use the **this** in other overload functions.


### Call super method with unhandled arguments styles

When we override the super's method or constructor, and we still need the super's method to handle the arguments styles that we don't want to handle.

We can create a functions with `__Arguments__.Rest()` attribute, pass all unhandled arguments styles to the super's method:

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ String, NaturalNumber }
		function Person(self, name, age)
			print("The name is " .. name)
			print("The age is " .. age)
		end
	end)

	class "Student" (function(_ENV)
		inherit "Person"

		__Arguments__{ String, NaturalNumber, Number }
		function Student(self, name, age, score)
			this(self, name, age)
			self.score = score
			print("The score is " .. score)
		end

		-- this means catch all other arguments, leave it to super class
		__Arguments__.Rest()
		function Student(self, ...)
			super(self, ...)
		end
	end)

	-- The name is Ann
	-- The age is 12
	-- The score is 80
	o = Student("Ann", 12, 80)
end)
```

### System.Variable

The previous examples only show require arguments, to describe optional and varargs we need know more about the `__Arguments__`, the `__Arguments__` only accpet one argument, it's type is **System.Variables**, which is an array struct, its element is **System.Variable**, a simple version of the struct is :

```lua
struct "Variable" (function(_ENV)
	name    = NEString
	type    = AnyType
	nilable = Boolean
	default = Any
	islist  = Boolean

	-- generate a varargs with type
	Rest    = function(type, atleastone) end

	-- generate an optional variable
	Optional= function(type, default) end
end)
```

So, we can create optional variable like

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ Variable.Optional(Number, 0) }
		function SetInfo(self, age)
			print("The age is " .. age)
		end
	end)

	o = Person()

	-- The age is 0
	o:SetInfo()
end)
```

And create a varargs like

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ Variable.Rest(String) }
		function AddChild(self, ...)
		end
	end)

	o = Person()

	-- Usage: Person:AddChild([... as System.String]) - the 2nd argument must be System.String
	o:AddChild("Ann", 1)
end)
```

Also we could apply more details like :

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{
			Variable("name", String, true, "anonymous"),
			Variable("age", NaturalNumber, true, 0)
		}
		function SetInfo(self, name, age)
			self:SetInfo(name)
			self:SetInfo(age)
		end
	end)

	o = Person()

	-- Usage: Person:SetInfo([name as System.String = "anonymous"], [age as System.NaturalNumber = 0]) - the 1st argument must be System.String
	o:SetInfo(true)
end)
```

## Throw Exception

There are more checks than the argument check, if we need notify the outside something goes wrong, normally we should use the **error** API, but the stack level is a problem, especially for the constructor and the overload system, so we need a new **Exception** system for them, the **PLoop** provide a keyword named **throw**, it'd convert the error message to an Exception object which can be catch by the pcall.

```lua
class "A" (function(_ENV)
	local function check(self)
		throw("something wrong")
	end

	function A(self)
		check(self)
	end
end)

o = A() -- something wrong
```

The object creation is controlled by the system, so the system can covert the Exception object to error message and throw the error at the right place.

```lua
PLoop(function(_ENV)
	__Arguments__{ String }:Throwable()
	function test(name)
		throw("we have throwable exception here")
	end

	test("HI") -- we have throwable exception here
end)
```

If we need use the throw in some functions or mehods(not constructor), we should use the `__Arguments__` and mark it as *Throwable*.


## Template class

We may create several classes with the same behaviors but for different types, since we use the function as the class's definition body, it's very simple to use them as template classes.

```lua
PLoop(function(_ENV)

	__Template__ { Any }
	class "Array" (function(_ENV, eletype)
		__Arguments__{ Variable.Rest(eletype) }
		function __new(cls, ...)
			return { ... }, true
		end
	end)

	--Error: Usage: Anonymous([... as System.Integer]) - the 4th argument must be System.Integer
	o = Array[Integer](1, 2, 3, "hi", 5)
end)
```

In the example, we use `__Template__` attribute to declare the **Array** class is a template class, the default type is **System.Any**, that means the real type can be any structs, interfaces or classes.

The **Array**'s definition function has one more argument, it's where the real type is passed in.

After the **Array** class is created, we can use **Array[Integer]** to pass in the real type and generate a class to do the jobs.

You also can create multi-types template, just like :

```lua
PLoop(function(_ENV)

	__Template__ { Any, Any }
	class "Dict" (function(_ENV, ktype, vtype)
		__Arguments__{ ktype, vtype }
		function Add(self, key, value)
			self[key] = value
		end
	end)

	o = Dict[{Integer, String}]()

	-- Error: Usage: Anonymous:Add(System.Integer, System.String) - the 2nd argument must be System.String
	o:Add(1, true)
end)
```

You also can create template interface and template struct.


## Namespace And Environment

In the **PLoop** environment, we can easily use types like **Number**, **String** and other attribute types, but within the `_G`, we need use keyword **import** to import the **System** namespace, then we can use them:

```lua
require "PLoop"

import "System"

print(Number) -- System.Number
```

The namespaces are used to organize feature types. Same name features can be saved in different namespaces so there won't be any conflict.

The environment(include the `_G`) can have a root namespace so all features defined in it will be saved to the root namespace.

```lua
PLoop(function(_ENV)
	namespace "MyNs"

	class "A" {}

	print(A) -- MyNs.A
end)
```

Also it can import several other namespaces, features that defined in them can be used in the environment directly.

```lua
PLoop(function(_ENV)
	print(A) -- nil

	import "MyNs"

	print(A) -- MyNs.A
end)
```

The namespace's path is from the root namespace to the sub namepsace, and to the final type. You can also specific the full namespace when define types:

```lua
PLoop(function(_ENV)
	namespace "MyNs"

	class "System.TestNS.A" {}

	print(A) -- System.TestNS.A
end)
```

So, it won't use the environment's namespace as root.


## Module

Using `PLoop(function(_ENV) end)` is a little weird, it's normally used by libraries. The recommend way is using **System.Module**, each file are considered as one module:

```lua
require "PLoop"

_ENV = Module "TestMDL" "1.0.0"

__Async__()
function dotask()
	print(coroutine.running())
end
```

`Module "TestMDL"` is short for `Module("TestMDL")`, so it created a Module object, call the object with a version number (also can be empty string) will change the current environment to the object itself, combine with the `_Env =` will make sure the code can run in Lua 5.1 and above version.

After that, we can enjoy the power of the **PLoop**.

A module object can have many child-modules :

```lua
_ENV = Module "TestMDL.SubMDL" "1.0.0"

dotask() -- ok
```

The child module can access its parent module's global variables, the root module can access the `_G`'s global variables.

When the module have access any variable contains in its parent or `_G`, the module will save the variable in itself.

The child module'll share its parent module's namespace unless it use **namespace** keyword to change it.


## Attribute System

We have seen many attributes, they are used to modify the target's behaviors.

If you only need to decorate some functions, you can simply use the `__Delegate__` attribute on functions like :

```lua
PLoop(function(_ENV)
	function decorate(func, ...)
		print("Call", func, ...)
		return func(...)
	end

	__Delegate__(decorate)
	function test() end

	-- Call function: 02E7B1C8  1   2   3
	test(1, 2, 3)
end)
```

To define an attribute class, we should extend the **System.IAttribute** interface or its extend interfaces :

* **System.IInitAttribute**     represents the interface to modify the target's definitions
* **System.IApplyAttribute**    represents the interface to apply changes on the target(like mark a enum as flags)
* **System.IAttachAttribute**   represents the interface to attach data on the target(binding database table on class)

It's also require several properties if you don't want use the default value:

* AttributeTarget   - the attribute targets, can be combined
	* System.AttributeTargets.All  (Default)
	* System.AttributeTargets.Function  - for common lua functions
	* System.AttributeTargets.Namespace - for namespaces
	* System.AttributeTargets.Enum      - for enumerations
	* System.AttributeTargets.Struct    - for structures
	* System.AttributeTargets.Member    - for sturct's member
	* System.AttributeTargets.Method    - for struct, interface or class methods
	* System.AttributeTargets.Interface - for interfaces
	* System.AttributeTargets.Class     - for classes
	* System.AttributeTargets.Event     - for events
	* System.AttributeTargets.Property  - for properies

* Inheritable       - whether the attribtue is inheritable, default false

* Overridable       - Whether the attribute's attach data is overridable, default true

* Priority          - the attribute's priority, the higher the first be applied
	* System.AttributePriority.Highest
	* System.AttributePriority.Higher
	* System.AttributePriority.Normal  (Default)
	* System.AttributePriority.Lower
	* System.AttributePriority.Lowest

* SubLevel          - the attribute priority's sublevel, if two attribute have the same priority, the bigger sublevel will be first applied, default 0

There are three type attributes:

### System.IInitAttribute

Those attributes are used to modify the target's definitions, normally used on functions or enums:

```lua
PLoop(function(_ENV)
	class "__SafeCall__" (function(_ENV)
		extend "IInitAttribute"

		local function checkret(ok, ...)
			if ok then return ... end
		end

		--- modify the target's definition
		-- @param   target                      the target
		-- @param   targettype                  the target type
		-- @param   definition                  the target's definition
		-- @param   owner                       the target's owner
		-- @param   name                        the target's name in the owner
		-- @param   stack                       the stack level
		-- @return  definition                  the new definition
		function InitDefinition(self, target, targettype, definition, owner, name, stack)
			return function(...)
				return checkret(pcall(definition, ...))
			end
		end

		property "AttributeTarget" { default = AttributeTargets.Function + AttributeTargets.Method }
	end)

	__SafeCall__()
	function test1()
		return 1, 2, 3
	end

	__SafeCall__()
	function test2(i, j)
		return i/j
	end

	print(test1()) -- 1, 2, 3
	print(test2()) -- nothing
end)
```

the attribute class should extend the **System.IInitAttribute** and define the **InitDefinition** method to modify the target's definitions, for a function, the definition is the function itself, if the method return a new definition, the new will be used. And for the enum, the definition is the table that contains the elements. The init attribtues are called before the define process of the target.

### System.IApplyAttribute

Those attributes are used to apply changes on the target, normally this is only used by the system attributes, take the `__Sealed__` as an example:

```lua
class "__Sealed__" (function(_ENV)
	extend "IApplyAttribute"

	--- apply changes on the target
	-- @param   target                      the target
	-- @param   targettype                  the target type
	-- @param   owner                       the target's owner
	-- @param   name                        the target's name in the owner
	-- @param   stack                       the stack level
	function ApplyAttribute(self, target, targettype, owner, name, stack)
		if targettype == AttributeTargets.Enum then
			Enum.SetSealed(target)
		elseif targettype == AttributeTargets.Struct then
			Struct.SetSealed(target)
		elseif targettype == AttributeTargets.Interface then
			Interface.SetSealed(target)
		elseif targettype == AttributeTargets.Class then
			Class.SetSealed(target)
		end
	end

	property "AttributeTarget" { default = AttributeTargets.Enum + AttributeTargets.Struct + AttributeTargets.Interface + AttributeTargets.Class }
end)
```

the attribute should extend the **System.IApplyAttribute** and define the **ApplyAttribute** method. The apply attribtues are applied during the define process of the target.

### System.IAttachAttribute

Those attributes are used to attach attribtue datas on the target, also can be used to register the final result to other systems.

```lua
PLoop(function(_ENV)
	class "__DataTable__" (function(_ENV)
		extend "IAttachAttribute"

		--- apply changes on the target
		-- @param   target                      the target
		-- @param   targettype                  the target type
		-- @param   owner                       the target's owner
		-- @param   name                        the target's name in the owner
		-- @param   stack                       the stack level
		function AttachAttribute(self, target, targettype, owner, name, stack)
			return self.DataTable
		end

		property "AttributeTarget" { default = AttributeTargets.Class }

		property "DataTable" { type = String }
	end)

	__DataTable__{ DataTable = "Persons" }
	class "Person" {}

	-- Persons
	print(IAttribute.GetAttachedData(__DataTable__, Person))
end)
```

the attribute should extend the **System.IAttachAttribute** and defined the **AttachAttribute** method, the return value of the method will be saved, so we can check it later.