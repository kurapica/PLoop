# Prototype Lua Object-Oriented Program System

中文版请点击[README-zh.md](https://github.com/kurapica/PLoop/blob/master/README-zh.md)

**PLoop** is a C# like style object-oriented program system for lua. It support Lua 5.1 and above versions, also include the luajit. It's also designed to be used on multi-os thread platforms like the **OpenResty**.

It also provide common useful classes like thread pool, collection, serialization and etc.

You also can find useful features for large enterprise development like code organization, type validation and etc.

## Table of Contents

* [Install](#install)
* [Start with the Collections](#start-with-the-collections)
    * [The creation of List](#the-creation-of-list)
    * [The method of the List](#the-method-of-the-list)
    * [The traverse of the List](#the-traverse-of-the-list)
    * [The sort of the List](#the-sort-of-the-list)
    * [The creation of the Dictionary](#the-creation-of-the-dictionary)
    * [The method of the Dictionary](#the-method-of-the-dictionary)
    * [The traverse of the Dictionary](#the-traverse-of-the-dictionary)
* [Attribute and Thread Pool](#attribute-and-thread-pool)
* [Spell Error Checks And More](#spell-error-checks-and-more)
    * [Read un-existed global variables](#read-un-existed-global-variables)
    * [Write to illegal global variables](#write-to-illegal-global-variables)
    * [Access un-existed object fields](#access-un-existed-object-fields)
* [Type Validation](#type-validation)
* [enum](#enum)
    * [System.Enum](#systemenum)
* [struct](#struct)
    * [Custom](#custom)
    * [Member](#member)
    * [Array](#array)
    * [Table Style Definition](#table-style-definition)
    * [Reduce the validation cost](#reduce-the-validation-cost)
    * [Combine type](#combine-type)
    * [Sub Type](#sub-type)
    * [System.Struct](#systemstruct)
    * [System.Member](#systemmember)
* [Class](#class)
    * [Class and Object Method](#class-and-object-method)
    * [Meta-data and object construction](#meta-data-and-object-construction)
    * [Super class and Inheritance](#super-class-and-inheritance)
    * [System.Class](#systemclass)
    * [The multi-version class](#the-multi-version-class)
    * [Append methods](#append-methods)
* [Interface](#interface)
    * [System.Interface](#systeminterface)
    * [Interface's anonymous class](#interfaces-anonymous-class)
	* [the require class of the interface](#the-require-class-of-the-interface)
* [Event](#event)
    * [The event of the event handler's changes](#the-event-of-the-event-handlers-changes)
    * [Static event](#static-event)
    * [super event](#super-event)
    * [System.Event](#systemevent)
* [Property](#property)
    * [get/set](#getset)
    * [getmethod/setmethod](#getmethodsetmethod)
    * [field & default](#field--default)
    * [default factory](#default-factory)
    * [property-event](#property-event)
    * [property-handler](#property-handler)
    * [static property](#static-property)
    * [Auto-binding](#auto-binding)
    * [super property](#super-property)
    * [indexer property](#indexer-property)
    * [Get/Set Modifier](#getset-modifier)
    * [System.Property](#system.property)
* [Inheritance and Priority](#inheritance-and-priority)
* [Use other definition style](#use-other-definition-style)
    * [Use string as definition body](#use-string-as-definition-body)
    * [Use table as definition body](#use-table-as-definition-body)
* [Namespace and Anonymous types](#namespace-and-anonymous-types)
    * [System.Namespace](#systemnamespace)
* [The Environment](#the-environment)
    * [Code Isolated](#code-isolated)
    * [Share types](#share-types)
    * [Attribute for global functions](#attribute-for-global-functions)
    * [Namespace as caller](#namespace-as-caller)
    * [The global variable access](#the-global-variable-access)
    * [Auto-cache](#auto-cache)
* [Overload](#overload)
    * [this For object constructor](#this-for-object-constructor)
    * [Call super method with unhandled arguments styles](#call-super-method-with-unhandled-arguments-styles)
    * [System.Variable](#system.variable)
    * [A simple version of the variables](#a-simple-version-of-the-variables)
* [Throw Exception](#throw-exception)
* [Template class](#template-class)
* [System.Module](#systemmodule)
    * [child-modules](#child-modules)
* [Attribute System](#attribute-system)
    * [System.IAttribute](#systemiattribute)
    * [System.IInitAttribute](#systemiinitattribute)
    * [System.IApplyAttribute](#systemiapplyattribute)
    * [System.IAttachAttribute](#systemiattachattribute)
	* [System Attributes](#system-attributes)
		* [`__Abstract__`](#__abstract__)
		* [`__AnonymousClass__`](#__anonymousclass__)
		* [`__AutoIndex__`](#__autoindex__)
		* [`__Arguments__`](#__arguments__)
		* [`__Async__`](#__async__)
		* [`__Base__`](#__base__)
		* [`__Default__`](#__default__)
		* [`__Delegate__`](#__delegate__)
		* [`__EventChangeHandler__`](#__eventchangehandler__)
		* [`__Final__`](#__final__)
		* [`__Flags__`](#__flags__)
		* [`__Get__`](#__get__)
		* [`__Indexer__`](#__indexer__)
		* [`__Iterator__`](#__iterator__)
		* [`__Namespace__`](#__namespace__)
		* [`__NoNilValue__`](#__nonilvalue__)
		* [`__NoRawSet__`](#__norawset__)
		* [`__ObjFuncAttr__`](#__objfuncattr__)
		* [`__ObjectSource__`](#__objectsource__)
		* [`__Require__`](#__require__)
		* [`__Sealed__`](#__sealed__)
		* [`__Set__`](#__set__)
		* [`__SingleVer__`](#__singlever__)
		* [`__Static__`](#__static__)
		* [`__Super__`](#__super__)
		* [`__SuperObject__`](#__superobject__)
		* [`__Template__`](#__template__)
* [keyword](#keyword)
    * [Global keyword](#global-keyword)
        * [export](#export)
    * [Context keyword](#context-keyword)
    * [Features can be used in `_G`](#features-can-be-used-in-_g)
* [Serialization](#serialization)
    * [Start with JSON](#start-with-json)
    * [Serializable Type](#serializable-type)
    * [Custom Serialize & Deserialize](#custom-serialize--deserialize)

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

To use the get call line, the `debug.getinfo` must existed.

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


### The multi-version class

If we don't use the `__Sealed__` to seal the classes, we still can re-define it, unlike the struct, redefine a class
only add or override the previous definition, not wipe them.

Take an example:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	class "A" (function(_ENV)
		function test(self)
			print("hello")
		end
	end)

	o:test()   -- hi
	A():test() -- hello
end)
```

The old object won't receive the updating, so we have two version objects of the same class. It's designed to make sure the new definition won't break the old object(use some new fields don't existed in the old object and etc).

If we need a class whose object will receive all updatings, we must use the `System.__SingleVer__` to mark it, so it'll always keep only one versions:

```lua
require "PLoop"

PLoop(function(_ENV)
	__SingleVer__()
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	class "A" (function(_ENV)
		function test(self)
			print("hello")
		end
	end)

	o:test()   -- hello
	A():test() -- hello
end)
```

So the old object will receive all updatings. If you need this to be default behaviors, you can modify the platform settings like :

```lua
PLOOP_PLATFORM_SETTINGS = { CLASS_NO_MULTI_VERSION_CLASS = true }

require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	class "A" (function(_ENV)
		function test(self)
			print("hello")
		end
	end)

	o:test()   -- hello
	A():test() -- hello
end)
```

Beware, the settings is disabled in the multi os thread platform.


### Append methods

There is another way to append methods without re-define the classes:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Sealed__()
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	function A:test2()
		print("hello")
	end

	o:test2()   -- hello
end)
```

We can assign new object or static method to the classes without a full re-definition. So, all object can receive the new method.

It also can be used on the sealed classes. Also we can use it on the interfaces.

We can't use this on the struct type, the method in a struct is copied to the data, if we add a method to a struct with no method, it'll change the struct from immutable to mutable, it's not allowed.


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

### Interface's anonymous class

If we use `System.__AnonymousClass__` attribute to mark an interface, the interface will create an anonymous class that extend itself, we can't use the anonymous class directly, but we can use the interface like we use a class:

```lua
require "PLoop"

PLoop(function(_ENV)
	__AnonymousClass__()
	interface "ITask" (function(_ENV)
		__Abstract__() function Process()
		end
	end)

	o = ITask{ Process = function() print("Hello") end }

	o:Process()
end)
```

The interface can only accept a table as the init-table to generate the object.

But for the interface with only one abstract method, we can use a simple style

```lua
require "PLoop"

PLoop(function(_ENV)
	__AnonymousClass__()
	interface "ITask" (function(_ENV)
		__Abstract__() function Process()
		end
	end)

	o = ITask(function() print("Hello") end)
	o:Process()
end)
```

We can pass a function as the implement of the abstract method to generate the object.

If you want all interface can be use as this, you can modify the platform settings(not recommend):

```lua
PLOOP_PLATFORM_SETTINGS = { INTERFACE_ALL_ANONYMOUS_CLASS = true }

require "PLoop"

PLoop(function(_ENV)
	interface "ITask" (function(_ENV)
		__Abstract__() function Process()
		end
	end)

	o = ITask(function() print("Hello") end)
	o:Process()
end)
```

### the require class of the interface

We can use the **require** keyword to set a class to the interface, so all classes that extend the interface must be the class's sub-types:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" {}

	interface "IA" (function(_ENV)
		require "A"
	end)

	class "B" (function(_ENV)
		extend "IA" -- Error: interface.AddExtend(target, extendinterface[, stack]) - the class must be A's sub-class
	end)
end)
```


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


## Inheritance and Priority

A class can extend many interfaces and inherit one super class who'll have its own extended interfaces and super class.

If those extend interfaces and super classes have the same name feature(method, property, event, meta-method), the system will choose the nearest:

* check the super class, then the super class's super class, repeat until no more super classes.

* check the interfaces, the latest extended interface should be checked first.

Those are done by the system, so we don't need to control it, but we may affect it by give priority to those features with the `System.__Abstract__` and `System.__Final__` attributes:

* If a feature(method, meta-method, property or event) marked with `__Abstract__`, the feature's priority is the lowest.

* If a feature marked with `__Final__`, the feature's priority is the highest.

Here is an example:

```lua
require "PLoop"

PLoop(function(_ENV)
	interface "IA" (function(_ENV)
		__Final__()
		function Test(self)
			print("Hello IA")
		end

		__Abstract__()
		function Test2(self)
			print("Hello2 IA")
		end
	end)

	class "A" (function(_ENV)
		extend "IA"

		function Test(self)
			print("Hello A")
		end

		function Test2(self)
			print("Hello2 A")
		end
	end)

	o = A()
	o:Test()  -- Hello IA
	o:Test2() -- Hello2 A
end)
```

## Use other definition style

### Use string as definition body

The struct, interface and class can use string as the definition body, it's very simple, just have one example:

```lua
PLoop(function(_ENV)
	class "A" [[
		property "Name" { default = "anonymous" }
	]]

	print(A().Name)
end)
```

Just replace the `function(_ENV)` and `end)` to the start and end of the string.

### Use table as definition body

We already see [Table Style Definition](#table-style-definition) for the struct, it's also possible to define interface or class with tables:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" {
		-- Declare a static event
		-- it's not good to use the event in table
		OnPersonCreated = true,

		-- Declare an object event
		OnNameChanged   = false,

		-- Define property, we can use type
		-- or a table for the property
		Name = String,
		Age  = { type = Number, default = 0 },

		-- Define a object method
		SetName = function(self, name)
			self:OnNameChanged(name, self.Name)
			self.Name = name
		end,

		-- Declare the constructor, we also can use
		-- `__ctor` as the key
		function (self, name)
			Person.OnPersonCreated(name)
			self.Name = name
		end,
	}

	interface "IScore" {
		Person, -- if the type is class, means require it
		ICloneable,  -- if the type is interface, means extend it
	}

	class "Student" {
		Person, -- if the type is class, means inherit it
		IScore, -- if the type is interface, means extend it
	}

	-- We can declare the method later
	function Student:SetScore(score)
	end
end)
```


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

The previous examples only show require arguments, to describe optional and varargs we need know more about the `__Arguments__`, the `__Arguments__` only accpet one argument, it's type is **System.Variables**, which is an array struct whose element is **System.Variable**, a simple version of the struct is :

```lua
struct "Variable" (function(_ENV)
	name    = NEString        -- the variable name
	type    = AnyType         -- the variable type
	optional= Boolean         -- whether this is optional
	default = Any             -- the default value for optional
	varargs = Boolean         -- whether this is varargs
	mincount= NaturalNumber   -- the min count of the varargs, default 0

	-- generate an optional variable with type and default
	Optional= function(type, default) end

	-- generate a varargs with type and min count
	Rest    = function(type, mincount) end
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

### A simple version of the variables

Well, it's a little hard to keep using the **Variables**, the **PLoop** also provide an alternative way to simple it:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String/"anonymouse", Number * 0 }
	function Test(...)
		print(...)
	end

	-- anonymouse
	Test(nil)

	-- Usage: Test([System.String = "anonymouse"], [... as System.Number]) - the 2nd argument must be number, got string
	Test("hi", "next")
end)
```

So we can use `type/default` (`type/nil` also can be used) to decalre an optional variable, and use `type * mincount` to declare a varargs.


## Throw Exception

There are more checks than the argument check, if we need notify the outside something goes wrong, normally we should use the **error** API, but the stack level is a problem, especially for the constructor and the overload system, so we need a new **Exception** system for them, the **PLoop** provide a keyword named **throw**, it'd convert the error message to an Exception object which can be catch by the pcall.

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		local function check(self)
			throw("something wrong")
		end

		function A(self)
			check(self)
		end
	end)

	o = A() -- something wrong
end)
```

The object creation is controlled by the system, so the system can covert the Exception object to error message and throw the error at the right place.

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String }:Throwable()
	function test(name)
		throw("we have throwable exception here")
	end

	test("HI") -- we have throwable exception here
end)
```

If we need use the throw in some functions or mehods(not constructor), we should use the `__Arguments__` and mark it as *Throwable*.

If you want handle the exceptions by yourself, you can follow the example :

```lua
require "PLoop"

PLoop(function(_ENV)
	function safecall(func, ...)
		local ok, ret = pcall(func, ...)

		if not ok then
			if type(ret) == "string" then
				error(ret, 0) -- keep the stack level
			else
				error(tostring(ret), 2) -- convert the exception object to string
			end
		end
	end

	function test()
		throw("some thing not right")
	end

	safecall(test) -- Here: some thing not right
end)
```

You can change the **throw** to **error** to see the different.


## Template class

We may create several classes with the same behaviors but for different types, since we use the function as the class's definition body, it's very simple to use them as template classes.

```lua
require "PLoop"

PLoop(function(_ENV)
	__Template__ { Any }
	class "Array" (function(_ENV, eletype)
		__Arguments__{ eletype * 0 }
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
require "PLoop"

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

You also can create template interface and template struct. This is an experimental feature, and normally we don't really need a strict type system in a dynamic language, so don't abuse it.


## System.Module

**PLoop** is using private environment to isolate codes, but in a project, we still need to share some global features.

To provide the management of those projects, **PLoop** provide the **System.Module**, its objects is designed based on the **PLoop**'s private environment system.

Task an example to start:

```lua
require "PLoop"

_ENV = Module "TestMDL" "1.0.0"

namespace "Test"

__Async__()
function dotask()
	print(coroutine.running())
end
```

`Module "TestMDL"` is short for `Module("TestMDL")`, so it created a Module object, call the object with a version number (also can be empty string) will change the current environment to the object itself, combine with the `_ENV =` will make sure the code can run in Lua 5.1 and above version.

After that, we can use all the features provided by the **PLoop**.

### child-modules

A module object can have many child-modules :

```lua
_ENV = Module "TestMDL.SubMDL" "1.0.0"

enum "A" {}

print(A) -- Test.A

dotask() -- thread: 02E7F75C	false

function dosubtask()
end
```

```lua
_ENV = Module "TestMDL.SubMDL2" "1.0.0"

print(dosubtask) -- nil
```

A module can have no-limit child modules, but can only have one parent module, so there is a root module whose global variables'd be shared by all child-modules.

The child module can access its parent module's global variables, the root module can access the `_G`'s global variables.

The child module'll share its parent module's namespace unless it use **namespace** keyword to change it.

The module can't access global variables defined in its brothers. But you still can share defined types.

You can create any child module of the child module like

```lua
Module "TestMDL.SubMDL2.SSubMDL.XXXX"
```

So the whole project'd be saved to a tree of the modules. The **namespace** is used to save types, and the Modules are used to save codes.


## Attribute System

We have seen many attributes, they are used to modify the target's behaviors.

### System.IAttribute

To define an attribute class, we should extend the **System.IAttribute** interface or its extend interfaces :

* **System.IInitAttribute**     represents the interface to modify the target's definitions
* **System.IApplyAttribute**    represents the interface to apply changes on the target(like mark a enum as flags)
* **System.IAttachAttribute**   represents the interface to attach data on the target(binding database table on class)

It's also require several properties if you don't want use the default value:

* AttributeTarget   - the attribute targets, can be combined
	* System.AttributeTargets.All  (Default)
	* System.AttributeTargets.Function  - for common lua functions, event handlers
	* System.AttributeTargets.Namespace - for namespaces
	* System.AttributeTargets.Enum      - for enumerations
	* System.AttributeTargets.Struct    - for structures
	* System.AttributeTargets.Member    - for sturct's member
	* System.AttributeTargets.Method    - for struct, interface or class methods
	* System.AttributeTargets.Interface - for interfaces
	* System.AttributeTargets.Class     - for classes
	* System.AttributeTargets.Event     - for events
	* System.AttributeTargets.Property  - for properies

* Inheritable       - whether the attribute is inheritable, default false

* Overridable       - Whether the attribute's attach data is overridable, default true

* Priority          - the attribute's priority, the higher the first be applied
	* System.AttributePriority.Highest
	* System.AttributePriority.Higher
	* System.AttributePriority.Normal  (Default)
	* System.AttributePriority.Lower
	* System.AttributePriority.Lowest

* SubLevel          - the attribute priority's sublevel, if two attribute have the same priority, the bigger sublevel will be first applied, default 0

There are three type attributes, the init attributes are called before the definition of the target, the apply attributes are called during the definition of the target and the attach attributes are called after the definition of the target:

### System.IInitAttribute

Those attributes are used to modify the target's definitions, normally used on functions or enums:

```lua
require "PLoop"

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

the attribute class should extend the **System.IInitAttribute** and define the **InitDefinition** method to modify the target's definitions, for a function, the definition is the function itself, if the method return a new definition, the new will be used. And for the enum, the definition is the table that contains the elements. The init attributes are called before the define process of the target.

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

the attribute should extend the **System.IApplyAttribute** and define the **ApplyAttribute** method. The apply attributes are applied during the define process of the target.

### System.IAttachAttribute

Those attributes are used to attach attribute datas on the target, also can be used to register the final result to other systems.

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

### System Attributes

#### `__Abstract__`

Used to mark a class as abstract, so it can't be used to generate objects, or used to mark the method, event or property as abstract, so they need(not must) be implemented by child types.

Attribute Targets:
* System.AttributeTargets.Class
* System.AttributeTargets.Method
* System.AttributeTargets.Event
* System.AttributeTargets.Property

#### `__AnonymousClass__`

See [Interface's anonymous class](#interfaces-anonymous-class) for more details.

Attribute Targets:
* System.AttributeTargets.Interface

#### `__AutoIndex__`

See [enum](#enum) for more details.

Attribute Targets:
* System.AttributeTargets.Enum

#### `__Arguments__`

See [Overload](#overload) for more details.

Attribute Targets:
* System.AttributeTargets.Function
* System.AttributeTargets.Method

#### `__Async__`

See [Attribute and Thread Pool](#attribute-and-thread-pool) for more details.

Attribute Targets:
* System.AttributeTargets.Function
* System.AttributeTargets.Method

#### `__Base__`

See [struct](#struct) for more details.

Attribute Targets:
* System.AttributeTargets.Struct

#### `__Default__`

See [enum](enum) and [struct](#struct) for more details.

Attribute Targets:
* System.AttributeTargets.Enum
* System.AttributeTargets.Struct
* System.AttributeTargets.Member

#### `__Delegate__`

Decorate the target functions.

Attribute Targets:
* System.AttributeTargets.Function
* System.AttributeTargets.Member

Usage:

```lua
require "PLoop"

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

#### `__EventChangeHandler__`

See [The event of the event handler's changes](#the-event-of-the-event-handlers-changes) for more details.

Attribute Targets:
* System.AttributeTargets.Event

#### `__Final__`

Set a class or interface as final, so they can't be inherited or extended by other types. Also can be used to mark the method, event and property as final, so they shouldn't be overridden.

Attribute Targets:
* System.AttributeTargets.Class
* System.AttributeTargets.Interface
* System.AttributeTargets.Method
* System.AttributeTargets.Event
* System.AttributeTargets.Property

#### `__Flags__`

See [enum](#enum) for more details.

Attribute Targets:
* System.AttributeTargets.Enum

#### `__Get__`

See [Get/Set Modifier](#getset-modifier) for more details.

Attribute Targets:
* System.AttributeTargets.Property

#### `__Indexer__`

See [indexer property](#indexer-property) for more details.

Attribute Targets:
* System.AttributeTargets.Property

#### `__Iterator__`

See [Attribute and Thread Pool](#attribute-and-thread-pool) for more details.

Attribute Targets:
* System.AttributeTargets.Function
* System.AttributeTargets.Method

#### `__Namespace__`

Set the namespace for the next created type

Attribute Targets:
* System.AttributeTargets.All

Usage:

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "Test"

	__Namespace__ "MyNS"
	class "A" {}

	print(A)   -- MyNS.A
end)
```

#### `__NoNilValue__`

Get the class's objects so access non-existent fields on them will be denied.

Attribute Targets:
* System.AttributeTargets.Class

Usage:

```lua
require "PLoop"

PLoop(function(_ENV)
	__NoNilValue__()
	class "A" {}

	o = A()
	v = o.age -- Error: The object don't have any field that named "age"
end)
```

#### `__NoRawSet__`

Set the class's objects so save value to non-existent fields on them will be denied.

Attribute Targets:
* System.AttributeTargets.Class

Usage:

```lua
require "PLoop"

PLoop(function(_ENV)
	__NoRawSet__()
	class "A" {}

	o = A()
	o.age = 10 -- Error: The object can't accept field that named "age"
end)
```

#### `__ObjFuncAttr__`

Set the class's objects so functions that be assigned on them will be modified by the attribute system(target type is function)

Attribute Targets:
* System.AttributeTargets.Class

Usage:

```lua
require "PLoop"

PLoop(function(_ENV)
	__ObjFuncAttr__()
	class "A" {}

	o = A()

	__Async__()
	function o:Test()
		print(coroutine.running())
	end

	o:Test() -- thread: 02F195E8
end)
```

#### `__ObjectSource__`

Set the class's objects to save the source where it's created

Attribute Targets:
* System.AttributeTargets.Class

Usage:

```lua
require "PLoop"

PLoop(function(_ENV)
	__ObjectSource__()
	class "A" {}

	o = A()

	print(Class.GetObjectSource(o)) -- @path_to_file\file.lua:7
end)
```

#### `__Require__`

Set a require class to the target interface, see [the require class of the interface](#the-require-class-of-the-interface)

Attribute Targets:
* System.AttributeTargets.Interface

#### `__Sealed__`

Seal the enum, struct, interface or class, so they can't be re-defined.

Attribute Targets:
* System.AttributeTargets.Enum
* System.AttributeTargets.Struct
* System.AttributeTargets.Interface
* System.AttributeTargets.Class

#### `__Set__`

See [Get/Set Modifier](#getset-modifier) for more details.

Attribute Targets:
* System.AttributeTargets.Property

#### `__SingleVer__`

See [The multi-version class](#the-multi-version-class) for more details.

Attribute Targets:
* System.AttributeTargets.Class

#### `__Static__`

Set the object methods or object features as static, so they can only be used by the struct, interface or class itself.

Attribute Targets:
* System.AttributeTargets.Method
* System.AttributeTargets.Event
* System.AttributeTargets.Property

#### `__Super__`

Set a super class to the target class

Attribute Targets:
* System.AttributeTargets.Class

#### `__SuperObject__`

Whether the class's objects use the super object access style like `super[self]:Method()`, `super[self].Name = xxx`.

Attribute Targets:
* System.AttributeTargets.Class

Usage:
```lua
-- make sure class A use the super object access style
__SuperObject__(true)
class "A" {}

-- make sure class B don't use the super object access style
__SuperObject__(false)
class "B" {}
```

#### `__Template__`

See [Template class](#template-class) for more details.

Attribute Targets:
* System.AttributeTargets.Struct
* System.AttributeTargets.Interface
* System.AttributeTargets.Class


## keyword

### Global keyword

There are two types keywords in the **PLoop**, one is for global, you can use them in any private environment of the **PLoop**:

* namespace  -- declare a namespace for current environment
* import     -- import a namespace to current environment
* export     -- export contents to current environment
* enum       -- define a new enum type
* struct     -- define a new struct type
* interface  -- define a new interface type
* class      -- define a new class type
* throw      -- throw an exception

#### export

There is only one unknow keyword **export**, the keyword is designed for multi os thread platform:

```lua
PLOOP_PLATFORM_SETTINGS = { MULTI_OS_THREAD = true }

require "PLoop"

PLoop(function(_ENV)
	export {
		-- cache the global variables
		ipairs 	= ipairs,

		-- also can use the name directly
		"pairs",

		-- import types, the system know their names,
		-- so no need to specific the name
		List,
	}

	_G.test = function()
		print("hi")
	end
end)

-- [PLoop: Warn]The [print] is auto saved to table: 030066C8, need use 'export{ "print" }'@path_to_file\file.lua:16
test()
```

So the system'll warn us that we need use `export { "print" }` in the multi-os-thread mode.

The **export** will save the contents of the table into the current environment directly, so why we need this since the private environment can cache anything they accessed?

Unfortunately, auto-cache mechanism works a little different in the multi os thread platform, we can't risk to trigger the re-hash during runtime, since the environment may be accessed by two or more thread in the same time. So the system will create another table as the cache and replace it when a new global variables is auto saved.

So when we access global variables in the environment, we need get the value from the cache table through a meta-call, it won't cause too much, but we can eliminate the cost by using the **export**.

It's also useful for non-multi-os-thread platform, combine with the [Write to illegal global variables](#write-to-illegal-global-variables), we can declare all global variables with the **export**, and any other global assignment would be treated as illegal:

```lua
PLOOP_PLATFORM_SETTINGS = { GLOBAL_VARIABLE_FILTER = function() return true end, GLOBAL_VARIABLE_FILTER_USE_WARN = true }

require "PLoop"

PLoop(function(_ENV)
	export {
		-- declare constant
		CONST_VAR_DATA  = 1,

		-- declare other global variables
		dotask 			= false,
	}

	function dotask() -- it's ok now
	end

	-- [PLoop: Warn]There is an illegal assignment for "test"@path_to_file\file.lua:17
	function test()
	end
end)
```

### Context keyword

There are other keywords designed for context, like the definition environment of the class, struct and interface.

* struct
	* member   -- define a member of the struct
	* array    -- set the array element type
* interface
	* require  -- set the require class of the interface
	* extend   -- extend other interfaces
	* field    -- add object fields
	* event    -- define an event
	* property -- define a property
* class
	* inherit  -- inheirt a super class
	* extend   -- extend interfaces
	* field    -- add object fields
	* event    -- define an event
	* property -- define a property

### Features can be used in `_G`

The **PLoop** will try to save several keywords and feature types into the `_G`, so you can use them directly:

* PLoop 	 -- the root namespace
* namespace  -- declare a namespace for `_G`
* import     -- save a namespace and its sub namespaces into the `_G`
* enum       -- define a new enum type
* struct     -- define a new struct type
* interface  -- define a new interface type
* class      -- define a new class type
* Module     -- the System.Module

Only the **PLoop** must existed in the `_G`, others won't override the existed in the `_G`.


## Serialization

### Start with JSON

Task an example from the [PLoop_Web](https://github.com/kurapica/PLoop_Web):

```lua
require "PLoop_Web"

PLoop(function(_ENV)
	import "System.Serialization"
	import "System.Web"

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

The example is using **System.Serialization** deserialize a json string to lua data by using **System.Web.JsonFormatProvider**, then use **System.Serialization.StringFormatProvider** to serialize the data to a string.

**System.Serialization.Deserialize** and **System.Serialization.Serialize** are static methods.

The **System.Serialization.Serialize** would convert **PLoop** type data into normal lua data, then passed the lua data to a format provider, the provider would translate the lua data to the target format data.

The **System.Serialization.Deserialize** would use the format provider to translate the target format data into lua data, if a **PLoop** type is provided or contained in the lua data, the lua data would be converted to the type data. 

* Serialize : PLoop object -> lua table -> target format( string, json, xml )
* Deserialize : target format -> lua table -> PLoop object

The **JsonFormatProvider** is defined in **System.Web** in [PLoop_Web](https://github.com/kurapica/PLoop_Web). The **StringFormatProvider** is defined in **System.Serialization**.

### Serializable Type

Not all **PLoop** type data are serializable, the enum are always serializable, a serializable class or serializable custom struct must have the attribute `System.Serialization.__Serializable__`. The array struct is serializable only if it's element type is serializable, the member struct is serializable only if all the members' type is serializable(unless the member is marked as non-serialized).

You can also use `System.Serialization.__NonSerialized__` to mark class's property or struct's member as non-serialized data.

We'll only use string as the target format for examples, so only **StringFormatProvider** would be used.

Take an example :

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	namespace "Test"

	__Serializable__()
	class "Person" {
		Name = String,
		Age  = Number,
		Childs = struct { Person }
	}

	King = Person {
		Name = "King", Age = 65,
		Childs = {
			Person {
				Name = "Ann", Age = 33,
				Childs = {
					Person { Name = "Dio", Age = 12 }
				}
			}
		}
	}

	--	{
	--		__PLoop_Serial_ObjectType = "Test.Person",
	--		Childs = {
	--			[1] = {
	--				__PLoop_Serial_ObjectType = "Test.Person",
	--				Childs = {
	--					[1] = {
	--						__PLoop_Serial_ObjectType = "Test.Person",
	--						Name = "Dio",
	--						Age = 12
	--					}
	--				},
	--				Name = "Ann",
	--				Age = 33
	--			}
	--		},
	--		Name = "King",
	--		Age = 65
	--	}
	print( Serialization.Serialize( StringFormatProvider{ Indent = true }, King ) )
end)
```

**StringFormatProvider** has several properties :

* Indent - Whether using indented format, default false
* LineBreak - The line break, default '\n'
* IndentChar - The char used as the indented character, default '\t'
* ObjectTypeIgnored - Whether ignore the object's type for serialization, default false

Since we turn *Indent* on, the result would be formatted, we would see there were several `__PLoop_Serial_ObjectType`, if the object's type is not anymouse, it would be stored in the string, so when we deserialize the string, we'll know what type the data would be, if we turn on the *ObjectTypeIgnored*, the `__PLoop_Serial_ObjectType` won't be output.

Now, we'll try to deserialize the string :

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	namespace "Test"

	__Serializable__()
	class "Person" {
		Name = String,
		Age  = Number,
		Childs = struct { Person }
	}

	King = Person {
		Name = "King", Age = 65,
		Childs = {
			Person {
				Name = "Ann", Age = 33,
				Childs = {
					Person { Name = "Dio", Age = 12 }
				}
			}
		}
	}

	data = Serialization.Serialize( StringFormatProvider{ Indent = true }, King )

	p = Serialization.Deserialize( StringFormatProvider(), data)

	-- Test.Person	Dio
	print( getmetatable(p), p.Childs[1].Childs[1].Name)
end)
```

So the p is *Person* type data, and we get all data back. Now, if we turn on the ObjectTypeIgnored :

```lua
data = Serialization.Serialize( StringFormatProvider{ ObjectTypeIgnored  = true }, King )

p = Serialization.Deserialize( StringFormatProvider(), data)

-- nil	Dio
print( getmetatable(p), p.Childs[1].Childs[1].Name)
```

The p has no type related, since the system won't know what type it would be. We should provide the type like :

```lua
data = Serialization.Serialize( StringFormatProvider{ ObjectTypeIgnored  = true }, King )

p = Serialization.Deserialize( StringFormatProvider(), data, Person)

-- Test.Person	Dio
print( getmetatable(p), p.Childs[1].Childs[1].Name)
```

Normally, we should provide the type in both **Serialize** and **Deserialize**, but since the King is a *Person* object, the system can easily know how to handle it, so we can ignored it.

But when we using the system on struct, we must provide the type in the **Serialize**, (whether using in **Deserialize** depends on whether using ObjectTypeIgnored or not).

So why provide the struct type on a normal lua data(struct is just normal lua data), the reason is, the type would be passed to the format provider, if the provider know the data is a array struct, it wouldn't check all the data to know it( special for json data format).

### Custom Serialize & Deserialize

Not all the class data are so simple, in some condition, the system can't figure out the true data that need to be serialized(The system can only handle the class's properties not super class's), or the classes have constructor defined(not support the init-table), the system won't know how to create the object.

So, the type should provide the information by itself.

A class need to do custom serialization must extend the **System.Serialization.ISerializable** interface, the interface defined a method **Serialize**, it receive one argument **System.Serialization.SerializationInfo**, the class have two methods:

* obj:SetValue(name, value, valueType)  -- Store the data to the SerializationInfo.
* obj:GetValue(name, valueType)         -- Get the data from the SerializationInfo with data type.

So the class object can save the data to the SerializationInfo object, and then the system can use the SerializationInfo for serialization.

The class also should have an overloaded constructor that only accept the SerializationInfo as argument. Here is an example :

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	namespace "Test"

	__Serializable__()
	class "Person" (function (_ENV)
		extend "ISerializable"

		property "Name" { Type = String }
		property "Age"  { Type = Number }

		function Serialize(self, info)
			-- Set the value with type
			info:SetValue("name", self.Name, String)
			info:SetValue("age",  self.Age, Number)
		end

		__Arguments__{ String, Number }
		function Person(self, name, age)
			self.Name = name
			self.Age = age
		end

		__Arguments__{ SerializationInfo }
		function Person(self, info)
			-- Get the value with type
			this(self, info:GetValue("name", String) or "Noname", info:GetValue("age", Number) or 0)
		end
	end)

	__Serializable__()
	class "Student"(function (_ENV)
		inherit "Person"

		property "Score" { Type = Number }

		function Serialize(self, info)
			-- Set the child class's value with type
			info:SetValue("score", self.Score, Number)

			-- Call the super's Serialize
			super.Serialize(self, info)
		end

		__Arguments__{ SerializationInfo }
		function Student(self, info)
			super(self, info)

			-- Get child class value with type
			self.Score = info:GetValue("score", Number)
		end

		__Arguments__.Rest()
		function Student(self, ...)
			super(self, ...)
		end
	end)

	Ann = Student("Ann", 16)
	Ann.Score = 81

	data = Serialization.Serialize( StringFormatProvider(), Ann)

	-- {__PLoop_Serial_ObjectType="Test.Student",name="Ann",age=16,score=81}
	print(data)

	p = Serialization.Deserialize( StringFormatProvider(), data)

	-- Test.Student	Ann	16	81
	print( getmetatable(p), p.Name, p.Age, p.Score)
end)
```