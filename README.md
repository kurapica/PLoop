Pure Lua Object-Oriented Program
====

__PLoop__ is used to provide a C# like style object-oriented program system for lua. It support Lua 5.1 and above versions, also the luajit.

* __namespace__ supported.
* Four data type included : __enum__, __struct__, __class__, __interface__.
* Property supported with several features : getter/setter, value changed handler or event, default value or default value factory, etc.
* Constructor/dispose supported for class, initializer/dispose supported for interface, validator supported for struct.
* Method supported for class, interface and struct.
* Event supported, event handlers are stackable.
* Ovload-method supported.
* Overload-constructor supported.
* Attribute supported to provided predefined system information or user-defined custom information.
* Isolated definition environment for each class, interface and struct.
* Several definition format supported for easy using.
* System.Reflector interface contains everything to get the informations of those features.

----

Take an example to start, Here is a __Person__ class with _Name_ and _Age_ properties.

	require "PLoop"

	import "System"	-- import a namespace

	-- Define a Person class with two properties
	-- String & Number are struct types defined in System namespace,
	-- Full path : System.String, System.Number
	class "Person" {
		Name = String,
		Age = Number,
	}

	-- Create an object of the Person class
	ann = Person{ Name = "Ann", Age = 24 }
	-- Or
	ann = Person()
	ann.Name = "Ann"
	ann.Age = 24

	-- Give the Person class a method, it only accept a person object as argument
	__Arguments__{ Person }
	function Person:Greet( another )
		print( ("Hi %s, my name's %s."):format(another.Name, self.Name) )
	end

	king = Person{ Name = "King" }

	-- Hi King, my name's Ann
	ann:Greet(king)

	-- Try using the Greet method with wrong value
	-- false	Error : Usage : Person:Greet( Person )
	print(pcall(function() ann:Greet("King") end))

	-- Try to set a wrong type value to ann's Name
	-- Error : Name must be a string, got number.
	ann.Name = 123

Here are some details about the example :

* __import__ and __class__ are all keywords(functions) that defined in PLoop, there are many other keywords like __interface__, __struct__, __enum__, etc.

* __import__ is used to import __namespace__ to current environment for quick access, in the previous code, __System__ is imported, so we can use __Number__ instead of __System.Number__, so for __String__ and `__Arguments__` .

	__PLoop__ use __namespace__ to manage classes, interfaces, enums and structs, so same name features can exist at same time with different __namespace__, such like __System.Widget.Frame__ and __MyNS.Frame__.

* __class__ is used to start the definition of a class, the declaration format is like

		class class-name declaration-body

	The _class-name_ is a string, we can use the name as a variable after we defined it.

	The _declaration-body_ has many forms, it can be a table, a function or a string. In the previous example, we use a table as the declaration-body, it contains two key-value pairs, since the values are types(Technically, __Number__ and __String__ are struct types), the two key-value pairs would be used as property declarations.

	Ploop has many different declaration formats for some history reasons.

	The system is first used in World of Warcraft to provide a poweful widget system for addon development, it's designed under lua 5.1 by using setfenv/getfenv to control the declaration-environment.In that time, it's using an extremely rigorous declaration-format :

		import "System"

		class "Person"

			-- Property
			property "Name"	{ Type = String }
			property "Age"	{ Type = Number }

			-- Method
			__Arguments__{ Person }
			function Greet( self, another )
				print( ("Hi %s, my name's %s."):format(another.Name, self.Name) )
			end

		endclass "Person"

	The declaration-body must be ended with __endclass__ keyword, and __property__ keyword is used to declare properties, the property's declaration-body must be a table that contains all property informations.

	When lua 5.2 is released, setfenv/getfenv is replaced by _ENV, so the declaration will be

		import "System"

		_ENV = class "Person"

			-- Property
			property "Name"	{ Type = String }
			property "Age"	{ Type = Number }

			-- Method
			__Arguments__{ Person }
			function Greet( self, another )
				print( ("Hi %s, my name's %s."):format(another.Name, self.Name) )
			end

		_ENV = endclass "Person"

	Although the format is supported, it's not likely to be used. So many other declaration formats are added, you can select whatever you like to define features.

	In lua 5.2 and above, if the _debug_ lib is used, the PLoop would try to create setfenv/getfenv api based on it, so the __class__ - __endclass__ declaration format can be used on it.

	To make sure the PLoop can be used in several lua versions, the common declaration format is using function :

		import "System"

		class "Person" (function(_ENV)

			-- Property
			property "Name"	{ Type = String }
			property "Age"	{ Type = Number }

			-- Method
			__Arguments__{ Person }
			function Greet( self, another )
				print( ("Hi %s, my name's %s."):format(another.Name, self.Name) )
			end

		end)

	It's simple to use table as declaration-body, but use function would make the whole things together.

* You can re-define most features(like the _Greet_ method) after define the __class__, and the object created before the re-definition will receive the new features.

	You can re-difine the class by just give it a key-value pair, if the value is a function, it woule be a method, if the value is a type, it would be a property. There are also many re-definition ways.

* `__Arguments__` is an __attribute__ class, the __attribute__ system is used to associate predefined system information or user-defined custom information with a target feature.

	`__Arguments__` is used to check the arguments to make sure the method only receive the arguments that it want, it can be used to create overload methods :


		import "System"

		class "Person"

			-- Property
			property "Name"	{ Type = String }
			property "Age"	{ Type = Number }

			-- Method
			__Arguments__{ Person }
			function Greet( self, another )
				print( ("Hi %s, my name's %s."):format(another.Name, self.Name) )
			end

			__Arguments__{ String }
			function Greet( self, another )
				print( ("Hi %s, my name's %s."):format(another, self.Name) )
			end
		endclass "Person"

		ann = Person{ Name = "Ann" }

		-- Hi King, my name's Ann.
		ann:Greet( "King" )

		-- Hi King, my name's Ann.
		ann:Greet( Person{ Name = "King"} )

	There are many other attributes, and custom attributes are also fully supported.

* If a __property__ is given a type, the value would be validated before it's set to the property, that would take a tiny cost, but it'll stop the mistake flow to other place where we can't trace back.


For more features, you should go checking the [wiki](https://github.com/kurapica/PLoop/wiki).


Install
====

Download the zip-file, extract it and rename it to PLoop, move it in your **LUA_PATH** folder, or where your lua file saved.