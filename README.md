PLoop - Pure Lua Object-Oriented Program
====

_PLoop_ is used to provide a full object-oriented program system for lua.

Take an example to start, first let's define a _Person_ class with _Name_ and _Age_ properties, the _Name property's value should be a string, and the _Age_ property's value should be a number. Then we create an object of the _Person_ class, and after that, we give the _Person_ class a _Greet_ method, we'll see how the object call the method at last.

	require "PLoop"

	import "System"	-- import a namespace

	-- Define a Person class with two properties
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

* _import_ and _class_ are all keywords(functions) that defined in PLoop, there are many other keywords like _interface_, _struct_, _enum_, etc.

* _import_ is used to import _namespace_ to current environment for quick access, in the previous code, _System_ is imported, so we can use _Number_ instead of _System.Number_, so for _String_ and `__Arguments__` .

	_PLoop_ use _namespace_ to manage classes, interfaces, enums and structs, so same name features can exist at same time with different _namespace_, such like _System.Widget.Frame_ and _MyNS.Frame_.

* _class_ is used to start the definition of a class, the declaration format is like

		class class-name declaration-body

	The class-name is a string, we can use the name as a variable after we defined it.

	The declaration-body has many forms, it can be a table, a function or a string. In the previous example, we use a table as the declaration-body, it contains two key-value pairs, since the values are types(Technically, _Number_ and _String_ are struct types), the two key-value pairs would be used as property declarations.

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

	The declaration-body must be ended with _endclass_ keyword, and _property_ keyword is used to declare properties, the property's declaration-body must be a table that contains all property informations.

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

	In lua 5.2 and above, if the _debug_ lib is used, the PLoop would try to create setfenv/getfenv api based on it, so the _class_ - _endclass_ declaration format can be used on it.

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

* You can re-define most features(like the _Greet_ method) after define the _class_, and the object created before the re-definition will receive the new features.

	You can re-difine the class by just give it a key-value pair, if the value is a function, it woule be a method, if the value is a type, it would be a property. There are also many re-definition ways.

* `__Arguments__` is an _attribute_ class, the _attribute_ system is used to associate predefined system information or user-defined custom information with a target feature.

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

	There are many other _attribute_s, and custom attributes are fully supported.

* If a _property_ is given a type, the value would be validated before it's set to the property, that would take a tiny cost, but it'll stop the mistake flow to other place where we can't trace back.


For more features, you should go to check the [wiki](https://github.com/kurapica/PLoop/wiki).


Install
====

Download the zip-file, extract it and rename it to PLoop, move it in your **LUA_PATH** folder, or where your lua file saved.