Loop
====

Lua object-oriented program system, also with a special syntax keyword system. Now, it only works for Lua 5.1. Since the 'getfenv', 'setfenv', 'newproxy' api is removed from Lua 5.2, the system won't works on it now.


How to use
====

Use loadfile or require to load the class.lua file in the folder. Then you can try the below code:

	do  -- Run as a block
		-- Define a class
		class "MyClass"
			function Greet(self, name)
				print("Hello " .. name .. ", My name is " .. self.Name)
			end

			property "Name" {
				Get = function(self)
					return self._Name
				end,
				Set = function(self, name)
					self._Name = name
				end,
				Type = System.String,
			}

			function MyClass(self, name)
				self._Name = name
			end
		endclass "MyClass"

		-- Create the class's object
		ob = MyClass()

		-- Set the object's property
		ob.Name = "Kurapica"

		-- Call the object's method, you should get : Hello Ann, My name is Kurapica
		ob:Greet("Ann")
	end


Features
====

There are some keywords that released into the _G :

* namespace
* import
* enum
* struct
* interface
* partinterface
* class
* partclass
* Module


namespace & import
====

In an oop project, there would be hundred or thousand classes to work together, it's important to manage them in groups. The namespace system is bring in to store the classes and other things.

In the namespace system, we can access those features like classes, interfaces, structs with a path string. Here an example (you can try if you already load the class.lua) :

	do
		import "System"  -- import a namespace path in the current environment, so we can access it
		                 -- Here the System namespace should be set to the _G now
		                 -- The System namespace is defined in the class.lua, keeps many basic features

		print( System.Object )   -- you should get : System.Object, the Object class is defined in the System namespace

		namespace "Root.Example"  -- Decalre a new namespace for the current environment

		class "NewClass"
		endclass "NewClass"

		print( NewClass )   -- you should get : Root.Example.NewClass
		                    -- So when you define new classes, interaces, structs, enums, they should be kept in the namespace that you declared
	end

The namespace system is used to share features like class, if you don't declare a namespace for the environment, those features that defined later will be private.


enum
====

enum is used to defined new value types with enumerated values, normally it would be used as the property's type, and when the object's property is changed, it'll be used to validate the new value.

Here is an example to show how to use create a new enum type :

	do
		import "System"

		-- enum "name" should return a function to receive a table as the enumerated value list
		-- For each key-value in the list, if the key is a string, the key is used as the enumerated field,
		-- if the key is a number and the value is a string, the value is used as the enumerated field
		enum "Day" {
			SUNDAY = 0,
			MONDAY = 1,
			TUESDAY = 2,
			WEDNESDAY = 3,
		    THURSDAY = 4,
		    FRIDAY = 5,
		    SATURDAY = 6,
		    "None",
		}

		-- Use it, all print '0', so the case is ignored for enumerated field
		print(Day.sunday)
		print(Day.Sunday)
		print(Day.sundDay)

		-- print 'None'
		print(Day.none)

		-- get field from value, print 'WEDNESDAY'
		-- The System.Reflector is an interface that contains many functions to get detail of the oop system
		-- will be explained later
		print(System.Reflector.ParseEnum(Day, 3))
	end


struct
====

Lua's table has no limit, but if we have a texture widget to show colors, we may like a 'Color' property for the texture object to change it's color. To make sure the value is validated, struct system is bring in to validate and generate the expected tables.

First, in the System namespace, there are several basic struct types used to validate base value types in lua :

* System.Boolean - The value should be changed to true or false, no validation
* System.String  - means the value should match : type(value) == "string"
* System.Number  - means the value should match : type(value) == "number"
* System.Function  - means the value should match : type(value) == "function"
* System.Table  - means the value should match : type(value) == "table"
* System.Userdata  - means the value should match : type(value) == "userdata"
* System.Thread  - means the value should match : type(value) == "thread"

Define a struct value type is very simple, now we define a file struct, with two field : 'name' for the file name, 'version' for the file version. The name only should be a string, and a file must have a name, the version can be string or number, and also can be nil.

	do
		struct "File"
			import "System"

			name = String
			version = String + Number + nil
		endstruct "File"
	end

Here is the explain :



Let's have some test :

	f1 = File()	-- Error : stdin:1: Usage : File(name, [version]) - name must be a string, got nil.

	f1 = File("Test.lua", File)  -- Error : stdin:1: Usage : File(name, [version]) - version must be a string, got userdata.(Optional)

	f1 = File("Test.lua", 123)
	print(f1.name .. " : " .. f1.version)   -- Print : Test.lua : 123



















