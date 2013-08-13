Loop
====

Lua object-oriented program system, also with a special syntax keyword system. Now, it only works for Lua 5.1. Since the 'getfenv', 'setfenv', 'newproxy' api is removed from Lua 5.2, the system won't works on it now.


How to use
====

Use loadfile or require to load the class.lua file in the folder. Then you can try the below code:

------------------------
do  -- Run as a block
	-- Define a class
	class "MyClass"
		function Greet(self, name)
			print("Hello " .. name .. ", My name is " .. self.Name)
		end

		property "Name" {
			Get = function(self) return self._Name end,
			Set = function(self, name) self._Name = name end,
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
------------------------


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

------------------------
do
	import "System"  -- import a namespace path in the current environment, so we can access it,
	                 -- The System namespace is defined in the class.lua, keeps many base features

	print( System.Object )   -- you should get : System.Object, the Object class is defined in the System namespace

	namespace "Root.Example"  -- Decalre a new namespace for the current environment

	class "NewClass"
	endclass "NewClass"

	print( NewClass )   -- you should get : Root.Example.NewClass
	                    -- So when you define new features, they should be keep in the namespace that you declared
end
------------------------


enum
====

enum is used to defined new value types with enumerated values, normally it would be used as the property's type, and when the object's property is changed, it'll be used to validate the new value.

Here is an example to show how to use create a new enum type :

------------------------
do
	enum "Day" {
		SUNDAY = 0,
		MONDAY = 1,
		TUESDAY = 2,
		WEDNESDAY = 3,
	    THURSDAY = 4,
	    FRIDAY = 5,
	    SATURDAY = 6,
	}


end
------------------------