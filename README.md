Loop
====

Lua object-oriented program system, also with a special syntax keyword system. Now, it only works for Lua 5.1. Since the 'getfenv', 'setfenv', 'newproxy' api is removed from Lua 5.2, the system won't works on it now.



How to use
====

Use loadfile or require to load the class.lua file in the folder. Then you can try the below code:

	do
		-- Define a class
		class "MyClass"
			function Greet(self, name)
				print("Hello " .. name .. ", My name is " .. self.Name)
			end

			property "Name" {
				Storage = "_Name",     -- The real field that used to store the value, explain later
				Type = System.String,  -- the property's type used to validate the value,
									   -- System.Sting means the value should be a string, also explain later.
			}
		endclass "MyClass"
	end

Now we create a class with a 'Greet' method and a 'Name' property. Then we can use it like :

	do
		-- Create the class's object, also with init settings, the init table can contains properties settings
		-- and many more settings in it, will be explained later.
		ob = MyClass{ Name = "Kurapica" }

		-- Call the object's method, Output : Hello Ann, My name is Kurapica
		ob:Greet("Ann")

		-- Property settings, 123 is not a string, Error : stdin:10: Name must be a string, got number.
		ob.Name = 123
	end

Here I use 'do ... end' because you may try those code in an interactive programming environment, many definitions like class, struct, interface's definitions should be kept in one piece. After here, I'll not use 'do ... end' again, but just remember to add it yourself.



Features
====

There are some keywords that released into the _G :

* namespace
* import
* enum
* struct
* class
* partclass
* interface
* partinterface
* Module

The 'namespace' & 'import' are used to control the namespace system used to store classes, interfaces, structs and enums.

The 'enum' is used to define an enum type.

The 'struct' is used to start the definition of a struct type. A data of a struct type, is a normal table in lua, without metatable settings or basic lua type data like string, number, thread, function, userdata, boolean. The struct types are used to validate or create the values that follow the explicitly structure that defined in the struct types.

The 'class' & 'partclass' are used to start the definition of a class. In an object-oriented system, the core part is the objects. One object should have methods that used to tell it do some jobs, also would have properties to store the data used to mark the object's state. A class is an abstract of objects, and can be used to create objects with the same properties and methods settings.

The 'interface' & 'partinterface' are used to start the definition of an interface. Sometimes we may not know the true objects that our program will manipulate, or we want to manipulate objects from different classes, we only want to make sure the objects will have some features that our program needs, like we may need every objects have a 'Name' property to used to show all objects's name. So, the interface is bring in to provide such features. Define an interface is the same like define a class, but no objects can be created from an interface.

The 'Module' is used to start a standalone environment with version check, and make the development with the lua-oop system more easily, like we don't need to write down full path of namespaces. This topic will be discussed at last.



namespace & import
====

In an oop project, there would be hundred or thousand classes or other data types to work together, it's important to manage them in groups. The namespace system is bring in to store the classes and other features.

In the namespace system, we can access those features like classes, interfaces, structs with a path string.

A full path looks like 'System.Forms.EditBox', a combination of words separated by '.', in the example, 'System', 'System.Forms' and 'System.Forms.EditBox' are all namespaces, the namespace can be a pure namespace used only to contains other namespaces, but also can be classes, interfaces, structs or enums, only eums can't contains other namespaces.


The 'import' function is used to save the target namespace into current environment, the 1st paramter is a string that contains the full path of the target namespace, so we can share the classes and other features in many lua environments, the 2nd paramter is a boolean, if true, then all the sub-namespace of the target will be saved to the current environment too.

    import (name[, all])


If you already load the class.lua, you can try some example :

	import "System"  -- Short for import( "System" ), just want make it looks like a keyword

	print( System )          -- Output : System
	print( System.Object )   -- Output : System.Object
	print( Object )          -- Output : nil

	import ( "System", true )

	print( Object )          -- Output : System.Object

The System is a root namespace defined in the class.lua file, some basic features are defined in the namespace, such like 'System.Object', used as the super class of other classes.

Also you can see, 'Object' is a sub-namespace in 'System', we can access it just like a field in the 'System'.


The 'namespace' function is used to declare a default namespace for the current environment, so any classes, interfaces, structs and enums that defined after it, will be stored in the namespace as sub-namespaces.

	namespace ( name )

Here a simple example :

	namespace "MySpace.Example"  -- Decalre a new namespace for the current environment

	class "NewClass"             -- The class also be stored in current environment when defined.
	endclass "NewClass"

	print( NewClass )            -- Output : MySpace.Example.NewClass

The namespace system is used to share features like class, if you don't declare a namespace for the environment, those features that defined later will be private.



enum
====

enum is used to defined new value types with enumerated values.

First, an example used to show how to create a new enum type :

	import "System"

	-- Define a enum data type
	enum "Week" {
		SUNDAY = 0,
		MONDAY = 1,
		TUESDAY = 2,
		WEDNESDAY = 3,
	    THURSDAY = 4,
	    FRIDAY = 5,
	    SATURDAY = 6,
	    "None",
	}

	-- All output : 0
	-- Acees the values as table field, just case ignored
	print( Week.sunday )
	print( Week.Sunday )
	print( Week.sundDay )

	-- Output : 'None'
	print( Week.none )

	-- Output : 'WEDNESDAY'
	print( System.Reflector.ParseEnum( Week, 3 ) )

The true format of the 'enum' function is

	enum( name )( table )

The 'name' is a common string word, 'enum(name)' should return a function to receive a table as the definition of the enum data type.

In the 'table', for each key-value pairs, if the key is 'string', the key would be used as the value's name, if the key is a number and the value is a string, the value should be used as the value's name, so the 'None' is the value's name in the enum 'Week'.

In the last line of the example, 'System.Reflecotr' is an interface used to provide some internal informations of the system. Here, 'ParseEnum' is used to get the key of a enum's value.

Sometimes, we may need use the enum values as a combination, like Week.SUNDAY + Week.SATURDAY as the weekend days. We could use the System.__Flags__ attribute to mark the enum data type as bit flags data type (Attributes are special classes, only one for enums, the detail of the Attribute system will be explained later).

Here is the full example :

	import "System"

	System.__Flags__()
	enum "Week" {
		SUNDAY = 1,
		MONDAY = 2,
		TUESDAY = 4,
		WEDNESDAY = 8,
	    THURSDAY = 16,
	    FRIDAY = 32,
	    SATURDAY = 64,
	    "None",
	}

	-- Output : 65
	print( Week.SUNDAY + Week.SATURDAY )

	-- Output : SATURDAY	SUNDAY
	print( System.Reflector.ParseEnum( Week, 65 ) )

	-- Output : true
	print( System.Reflector.ValidateFlags( Week.SATURDAY, 65 ) )

	-- Output : false
	print( System.Reflector.ValidateFlags( Week.TUESDAY, 65 ) )

	-- Ouput : 128
	print( Week.None )


First, the enum values should be 2^n, and the system would provide auto values if no value is set, so the Week.None is 128.

The 'ParseEnum' function can return multi-values of the combination, and 'ValidateFlags' can be used to validate the values.



struct
====

The main purpose of the struct system is used to validate values, for lua, the values can be boolean, number, string, function, userdata, thread and table.

And in the 'System' namespace, all basic data type have a struct :

* System.Boolean - The value should be mapped to true or false, no validation
* System.String  - means the value should match : type(value) == "string"
* System.Number  - means the value should match : type(value) == "number"
* System.Function  - means the value should match : type(value) == "function"
* System.Userdata  - means the value should match : type(value) == "userdata"
* System.Thread  - means the value should match : type(value) == "thread"
* System.Table  - means the value should match : type(value) == "table"

Those are the 'basic' struct types, take the 'System.Number' as an example to show the basic using :

	import "System"

	-- Output : 123
	print( System.Number( 123 ) )

	-- Error : [Number] must be a number, got string.
	print( System.Number( '123' ))

All structs can used to validate values. ( Normally, you won't need to write the 'validation' code yourselves.)

When the value is a table, and we may expect the table contains fields with the expected type values, and the 'System.Table' can only be used to check whether the value is a table.

Take a position table as the example, we may expect the table has two fields : 'x' - the horizontal position, 'y' - the vertical position, and the fields' values should all be numbers. So, we can declare a 'member' struct type like :

	import "System"

	struct "Position"
		x = System.Number
		y = System.Number
	endstruct "Position"

Here, 'struct' keyword is used to begin the declaration, and 'endstruct' keyword is used to end the declaration. Anything defined between them will be definition of the struct.

The expression 'x = System.Number', the left part 'x' is the member name, the right part 'System.Number' is the member's type, the type can be any classes, interfaces, enums or structs :

* For a given class, the value should be objects that created from the class.
* For a given interface, the value should be objects whose class extend from the interface.
* For a given enum, the value should be the enum value or the value's name.
* For a given struct, the value that can pass the validation of the struct.

So, we can test the custom struct now :

	-- Short for Position( {x = 123, y = 456} )
	pos = Position {x = 123, y = 456}

	-- Output : 123	-	456
	print(pos.x, '-', pos.y)

	-- Error : Usage : Position(x, y) - y must be a number, got nil.
	pos = Position {x = 111}

	-- Use the struct type as a table constructor
	pos = Position(110, 200)

	-- Output : 110	-	200
	print(pos.x, '-', pos.y)


In the previous example, the 'x' and 'y' field can't be nil, we can re-define it to make the field accpet nil value :

	struct "Position"
		x = System.Number + nil
		y = System.Number + nil
	endstruct "Position"

	-- No error now
	pos = Position {x = 111}

Normally, the type part can be a combination of lots types seperated by '+', 'nil' used to mark the value can be nil, so 'System.Number + System.String + nil' means the value can be number or string or nil.

If we want default values for the fields, we can add a 'Validate' method in the definition, this is a special method used to do custom validations, so we can do some changes in the method, and just remeber to return the value in the 'Validate' method.

	struct "Position"
		x = System.Number + nil
		y = System.Number + nil

		function Validate(value)
			value.x = value.x or 0
			value.y = value.y or 0

			return value
		end
	endstruct "Position"

	pos = Position {x = 111}

	-- Output : 111	-	0
	print(pos.x, '-', pos.y)

Or you can use a method with the name of the struct, the method should be treated as the constructor :

	struct "Position"
		x = System.Number + nil
		y = System.Number + nil

		-- The constructor should create table itself
		function Position(x, y)
			return { x = x or 0, y = y or 0 }
		end
	endstruct "Position"

	-- Validate won't go through the constructor
	pos = Position {x = 111}

	-- Output : 111	-	nil
	print(pos.x, '-', pos.y)

	pos = Position (111)

	-- Output : 111	-	0
	print(pos.x, '-', pos.y)

	-- The constructor should do the validate itself
	pos = Position ('X', 'Y')

	-- Output : X	-	Y
	print(pos.x, '-', pos.y)

There are many disadvantages in using the constructor, so, just leave the table creation to the struct system.

In sometimes, we need validate the values and fire new errors, those operations also can be done in the 'Validate' method. Take a struct with two members : 'min', 'max', the 'min' value can't be greater than the 'max' value, so we should write :

	struct "MinMax"
		min = System.Number
		max = System.Number

		function Validate(value)
			assert(value.min <= value.max, "%s.min can't be greater than %s.max.")

			return value
		end
	endstruct "MinMax"

	-- Error : Usage : MinMax(min, max) - min can't be greater than max.
	minmax = MinMax(200, 100)

In the error message, there are two "%s" used to represent the value, and will be replaced by the validation system considered by where it's using. Here an example to show :

	struct "Value"
		value = System.Number
		minmax = MinMax
	endstruct "Value"

	-- Error : Usage : Value(value, minmax) - minmax.min can't be greater than minmax.max.
	v = Value(100, {min = 200, max = 100})

So, you can quickly find where the error happened.


We also may want to validate numeric index table of a same type values, like a table contains only string values :

	a = {"Hello", "This", "is", "a", "index", "table"}

We can declare a 'array' struct for those types (A special attribtue for the struct):

	import "System"

	System.__StructType__( System.StructType.Array )
	struct "StringTable"
		element = System.String
	endstruct "StringTable"

	-- Error : Usage : StringTable(...) - [3] must be a string, got number.
	a = StringTable{"Hello", "World", 3}

It's looks like the 'member' struct, but the member name 'element' has no means, it's just used to decalre the element's type, you can use 'element', 'ele' or anything else.


The last part about the struct is the struct methods. Any functions that defined in the struct definition, if the name is not the 'Validate' and the struct's name, will be treated as the struct methods, and those methods will be copyed to the values when created.

	struct "Position"
		x = System.Number
		y = System.Number

		function Print(self)
			print(self.x .. " - " .. self.y)
		end
	endstruct "Position"

	pos = Position { x = 123, y = 456 }

	-- Output : 123 - 456
	pos:Print()

	pos = Position (1, 2)

	-- Output : 1 - 2
	pos:Print()

Only using the struct to validate a value or create a value, will fill the methods into the value.

Normally, creating a class is better than using the struct methods, unless you want do some optimizations.



class
====



interface
====



Module
====



Tips
====