Loop
====

Lua object-oriented program system, also with a special syntax keyword system. Now, it only works for Lua 5.1. Since the **getfenv**, **setfenv**, **newproxy** api is removed from Lua 5.2, the system won't works on it now.



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
				Field = "_Name",     -- The real field that used to store the value, explain later
				Type = System.String,  -- the property's type used to validate the value,
									   -- System.Sting means the value should be a string, also explain later.
			}
		endclass "MyClass"
	end

Now we create a class with a **Greet** method and a **Name** property. Then we can use it like :

	do
		-- Create the class's object, also with init settings, the init table can contains properties settings
		-- and many more settings in it, will be explained later.
		ob = MyClass{ Name = "Kurapica" }

		-- Call the object's method, Output : Hello Ann, My name is Kurapica
		ob:Greet("Ann")

		-- Property settings, 123 is not a string, Error : stdin:10: Name must be a string, got number.
		ob.Name = 123
	end

Here I use **do ... end** because you may try those code in an interactive programming environment, many definitions like class, struct, interface's definitions should be kept in one piece. After here, I'll not use **do ... end** again, but just remember to add it yourself.



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

The **namespace** & **import** are used to control the namespace system used to store classes, interfaces, structs and enums.

The **enum** is used to define an enum type.

The **struct** is used to start the definition of a struct type. A data of a struct type, is a normal table in lua, without metatable settings or basic lua type data like string, number, thread, function, userdata, boolean. The struct types are used to validate or create the values that follow the explicitly structure that defined in the struct types.

The **class** & **partclass** are used to start the definition of a class. In an object-oriented system, the core part is the objects. One object should have methods that used to tell it do some jobs, also would have properties to store the data used to mark the object's state. A class is an abstract of objects, and can be used to create objects with the same properties and methods settings.

The **interface** & **partinterface** are used to start the definition of an interface. Sometimes we may not know the true objects that our program will manipulate, or we want to manipulate objects from different classes, we only want to make sure the objects will have some features that our program needs, like we may need every objects have a **Name** property to used to show all objects's name. So, the interface is bring in to provide such features. Define an interface is the same like define a class, but no objects can be created from an interface.

The **Module** is used to start a standalone environment with version check, and make the development with the lua-oop system more easily, like we don't need to write down full path of namespaces. This topic will be discussed at last.



namespace & import
====

In an oop project, there would be hundred or thousand classes or other data types to work together, it's important to manage them in groups. The namespace system is bring in to store the classes and other features.

In the namespace system, we can access those features like classes, interfaces, structs with a path string.

A full path looks like **System.Forms.EditBox**, a combination of words separated by '.', in the example, **System**, **System.Forms** and **System.Forms.EditBox** are all namespaces, the namespace can be a pure namespace used only to contains other namespaces, but also can be classes, interfaces, structs or enums, only eums can't contains other namespaces.


The **import** function is used to save the target namespace into current environment, the 1st paramter is a string that contains the full path of the target namespace, so we can share the classes and other features in many lua environments, the 2nd paramter is a boolean, if true, then all the sub-namespace of the target will be saved to the current environment too.

    import (name[, all])


If you already load the class.lua, you can try some example :

	import "System"  -- Short for import( "System" ), just want make it looks like a keyword

	print( System )          -- Output : System
	print( System.Object )   -- Output : System.Object
	print( Object )          -- Output : nil

	import ( "System", true )

	print( Object )          -- Output : System.Object

The System is a root namespace defined in the class.lua file, some basic features are defined in the namespace, such like **System.Object**, used as the super class of other classes.

Also you can see, **Object** is a sub-namespace in **System**, we can access it just like a field in the **System**.

---

The **namespace** function is used to declare a default namespace for the current environment, so any classes, interfaces, structs and enums that defined after it, will be stored in the namespace as sub-namespaces.

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
	print( Week.sunDay )

	-- Output : 'None'
	print( Week.none )

	-- Output : 'WEDNESDAY'
	print( System.Reflector.ParseEnum( Week, 3 ) )

The true format of the 'enum' function is

	enum( name )( table )

The **name** is a common string word, **enum(name)** should return a function to receive a table as the definition of the enum data type.

In the **table**, for each key-value pairs, if the key is **string**, the key would be used as the value's name, if the key is a number and the value is a string, the value should be used as the value's name, so the 'None' is the value's name in the enum **Week**.

In the last line of the example, **System.Reflecotr** is an interface used to provide some internal informations of the system. Here, **ParseEnum** is used to get the key of a enum's value.

---

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

The **ParseEnum** function can return multi-values of the combination, and **ValidateFlags** can be used to validate the values.



struct
====

The main purpose of the struct system is used to validate values, for lua, the values can be boolean, number, string, function, userdata, thread and table.

And in the **System** namespace, all basic data type have a struct :

* System.Boolean - The value should be mapped to true or false, no validation
* System.String  - means the value should match : type(value) == "string"
* System.Number  - means the value should match : type(value) == "number"
* System.Function  - means the value should match : type(value) == "function"
* System.Userdata  - means the value should match : type(value) == "userdata"
* System.Thread  - means the value should match : type(value) == "thread"
* System.Table  - means the value should match : type(value) == "table"

Those are the **basic** struct types, take the **System.Number** as an example to show the basic using :

	import "System"

	-- Output : 123
	print( System.Number( 123 ) )

	-- Error : [Number] must be a number, got string.
	print( System.Number( '123' ))

All structs can used to validate values. ( Normally, you won't need to write the 'validation' code yourselves.)

When the value is a table, and we may expect the table contains fields with the expected type values, and the **System.Table** can only be used to check whether the value is a table.

Take a position table as the example, we may expect the table has two fields : **x** - the horizontal position, **y** - the vertical position, and the fields' values should all be numbers. So, we can declare a **member** struct type like :

	import "System"

	struct "Position"
		x = System.Number
		y = System.Number
	endstruct "Position"

Here, **struct** keyword is used to begin the declaration, and **endstruct** keyword is used to end the declaration. Anything defined between them will be definition of the struct.

The expression *x = System.Number*, the left part **x** is the member name, the right part **System.Number** is the member's type, the type can be any classes, interfaces, enums or structs :

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

---

In the previous example, the **x** and **y** field can't be nil, we can re-define it to make the field accpet nil value :

	struct "Position"
		x = System.Number + nil
		y = System.Number + nil
	endstruct "Position"

	-- No error now
	pos = Position {x = 111}

Normally, the type part can be a combination of lots types seperated by '+', **nil** used to mark the value can be nil, so *System.Number + System.String + nil* means the value can be number or string or nil.

---

If we want default values for the fields, we can add a **Validate** method in the definition, this is a special method used to do custom validations, so we can do some changes in the method, and just remeber to return the value in the **Validate** method.

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

---

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

---

In sometimes, we need validate the values and fire new errors, those operations also can be done in the **Validate** method. Take a struct with two members : **min**, **max**, the **min** value can't be greater than the **max** value, so we should write :

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

---

We also may want to validate numeric index table of a same type values, like a table contains only string values :

	a = {"Hello", "This", "is", "a", "index", "table"}

We can declare a **array** struct for those types (A special attribtue for the struct):

	import "System"

	System.__StructType__( System.StructType.Array )
	struct "StringTable"
		element = System.String
	endstruct "StringTable"

	-- Error : Usage : StringTable(...) - [3] must be a string, got number.
	a = StringTable{"Hello", "World", 3}

It's looks like the **member** struct, but the member name **element** has no means, it's just used to decalre the element's type, you can use **element**, **ele** or anything else.

---

The last part about the struct is the struct methods. Any functions that defined in the struct definition, if the name is not the **Validate** and the struct's name, will be treated as the struct methods, and those methods will be copyed to the values when created.

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

The core part of an object-oriented system is object. Objects have data fields (property that describe the object) and associated procedures known as method. Objects, which are instances of classes, are used to interact with one another to design applications and computer programs.

Class is the abstract from a group of similar objects. It contains methods, properties (etc.) definitions so objects no need to declare itself, and also contains initialize function to init the object before using them.


Declare a new class
----

Let's use an example to show how to create a new class :

	class "Person"
	endclass "Person"

Like defining a struct, **class** keyword is used to start the definition of the class, it receive a string word as the class's name, and the **endclass** keyword is used to end the definition of the class, also it need the same name as the parameter, **class**, **endclass** and all keywords in the loop are fake keywords, they are only functions with some lua environment tricks, so we can't use the **end** to do the job for the best.

Now, we can create an object of the class :

	obj = Person()

Since the **Person** class is a empty class, the **obj** just works like a normal table.


Method
----

Calling an object's method is like sending a message to the object, so the object can do some operations. Take the **Person** class as an example, re-define it :

	class "Person"

		function GetName(self)
			return self.__Name
		end

		function SetName(self, name)
			self.__Name = tostring(name)
		end

	endclass "Person"

Any global functions that defined in the class definition with name not start with "_" are the methods of the class's objects. The object methods should have **self** as the first paramter to receive the object.

Here two methods are defined for the **Person**'s objects. **GetName** used to get the person's name, and **SetName** used to set the person's name. The objects are lua tables with special metatable settings, so the name value are stored in the person object itself in the field **__Name**, also you can use a special table to store the name value like :

	class "Person"

		_PersonName = setmetatable( {}, { __mode = "k" } )

		function GetName(self)
			return _PersonName[self]
		end

		function SetName(self, name)
			_PersonName[self] = tostring(name)
		end

	endclass "Person"

So, we can used it like :

	obj = Person()

	-- Thanks to lua's nature
	obj:SetName( "Kurapica" )

	-- Output : Hi Kurapica
	print( "Hi " .. obj:GetName() )

	-- Same like obj:GetName()
	-- The class can access any object methods as its field
	print( "Hi " .. Person.GetName(obj) )


Constructor
----

Well, it's better to give the name to a person object when objects are created. When define a global function with the class name, the function will be treated as the constructor function, like the object methods, it use **self** as the first paramter to receive the objecet, and all other paramters passed in.

	class "Person"

		-- Object Method
		function GetName(self)
			return self.__Name
		end

		function SetName(self, name)
			self.__Name = tostring(name)
		end

		-- Constructor
		function Person(self, name)
			self:SetName(name)
		end

	endclass "Person"

So, here we can use it like :

	obj = Person( "Kurapica" )

	-- Output : Hi Kurapica
	print( "Hi " .. obj:GetName() )


Class Method
----

Any global functions defined in the class's definition with name start with "_" are class methods, can't be used by the class's objects, as example, we can use a class method to count the persons :

	class "Person"

		_PersonCount = _PersonCount or 0

		-- Class Method
		function _GetPersonCount()
			return _PersonCount
		end

		-- Object Method
		function GetName(self)
			return self.__Name
		end

		function SetName(self, name)
			self.__Name = tostring(name)
		end

		-- Constructor
		function Person(self, name)
			_PersonCount = _PersonCount + 1

			self:SetName(name)
		end

	endclass "Person"

	obj = Person("A")
	obj = Person("B")
	obj = Person("C")

	-- Output : Person Count : 3
	print("Person Count : " .. Person._GetPersonCount())


Notice a global variable **_PersonCount** is used to count the persons, it can be decalred as local, but keep global is simple, and when re-define the class, the class won't lose informations about the old version objects(run the code again, you should get 6).


Property & Init with table
----

Properties are used to access the object's state, like **name**, **age** for a person. Normally, we can do this just using the lua table's field, but that lack the value validation and we won't know how and when the states are changed. So, the property system bring in like the other oop system.

So, here is the full definition format for a property :

	property "name" {
		Field = "field",
		Get = "GetMethod" or function(self) end,
		Set = "SetMethod" or function(self, value) end,
		Type = types,
		Default = value,
	}

* Field - optional, the lowest priority, the real field in the object that store the data, can be used to read or write the property.

* Get - optional, the highest priority, if the value is string, the object method with the name same to the value will be used, if the value is a function, the function will be used as the read accessor, can be used to read the property.

* Set - optional, the highest priority, if the value is string, the object method with the name same to the value will be used, if the value is a function, the function will be used as the write accessor, can be used to write the property.

* Type - optional, just like define member types in the struct, if set, when write the property, the value would be validated by the type settings.

* Default - optional, used as the default value if no value existed.

So, re-define the **Person** class with the property :

	class "Person"

		property "Name" {
			Field = "__Name",
			Type = System.String,
		}

	endclass "Person"

With the property system, we can create objects with a new format, called *Init with a table* :

	obj = Person { Name = "A", Age = 20 }

	-- Output : A	A	20
	print( obj.Name, obj.__Name, obj.Age )

If only a normal table passed to the class to create the object, the object will be created with no parameters, and then any key-value paris in the table will be tried to write to the object (just like obj[key] = value). If you want some parameters be passed into the class's constructor, the features will be added in the **Attribute** system.

With the **Field**, the reading and writing are the quickest, but normally, we need to do more things when the object's properties are accessed, like return a default value when data not existed. So, here is a full example to show **Get** and **Set** :

	class "Person"

		-- Object method
		function GetName(self)
			return self.__Name or "Anonymous"
		end

		-- Property
		property "Name" {
			-- Using the object method
			Get = "GetName",

			-- Using special set function
			Set = function(self, name)
				local oldname = self.Name

				self.__Name = name

				print("The name is changed from " .. oldname .. " to " .. self.Name)
			end,

			-- So in set method, no need to valdiate the 'name' value
			Type = System.String + nil,
		}

	endclass "Person"

So, the **Get** part is using the object method **GetName**, and the **Set** part is using an anonymous function to do the job.

	obj = Person()

	-- Output : The name is changed from Anonymous to A
	obj.Name = "A"


Event
----

The events are used to let the outside know changes happened in the objects. The outside can access the object's properties to know what's the state of the object, and call the method to manipulate the objects, but when some state changes, like click on a button, the outside may want know when and how those changes happened, and the event system is used to provide such features, it's used by the objects to send out messages to the outside.

	event "name"

The **event** keyword is used to declare an event with the event name. So, here we declare an event **OnNameChanged** fired when the **Person**'s **Name** property is changed.

	class "Person"

		-- Event
		event "OnNameChanged"

		-- Property
		property "Name" {
			Get = function(self)
				return self.__Name or "Anonymous"
			end,

			Set = function(self, name)
				local oldName = self.Name

				self.__Name = name

				-- Fire the event with parameters
				self:OnNameChanged(oldName, self.Name)
			end,

			Type = System.String + nil,
		}
	endclass "Person"

It looks like we just give the object a **OnNameChanged** method, and call it when needed. The truth is the **self.OnNameChanged** is an object created from **System.EventHandler** class. It's used to control all event handlers (functions), there are two type event handlers :

* Stackable event handler

* Normal event handler

So, it's quick to use an example to show the different :

	obj = Person()

	-- Stackable event handler
	obj.OnNameChanged = obj.OnNameChanged + function(self, old, new)
		print("Stack 1 : ", old, new)
	end

	-- Normal event handler
	function obj:OnNameChanged(old, new)
		print("Normal 1 : ", old, new)
	end

	-- Another global stackable event handler
	function OnNameChangedHandler(self, old, new)
		print("Stack 2 : ", old, new)
	end

	obj.OnNameChanged = obj.OnNameChanged + OnNameChangedHandler

	-- Another normal event handler
	obj.OnNameChanged = function(self, old, new)
		print("Normal 2 : ", old, new)
	end

	-- The last stackable event handler
	obj.OnNameChanged = obj.OnNameChanged + function(self, old, new)
		print("Stack 3 : ", old, new)
	end

	obj.Name = "Kurapica"

	print("------------------")

	obj.OnNameChanged = obj.OnNameChanged - OnNameChangedHandler

	obj.Name = "Another"

	print("------------------")

	-- A handler return true
	obj.OnNameChanged = obj.OnNameChanged + function(self, old, new)
		print("Stack 4 : ", old, new)

		return true
	end

	obj.Name = "Last"

Here is the result :

	Stack 1 : 	Anonymous	Kurapica
	Stack 2 : 	Anonymous	Kurapica
	Stack 3 : 	Anonymous	Kurapica
	Normal 2 : 	Anonymous	Kurapica
	------------------
	Stack 1 : 	Kurapica	Another
	Stack 3 : 	Kurapica	Another
	Normal 2 : 	Kurapica	Another
	------------------
	Stack 1 : 	Another	Last
	Stack 3 : 	Another	Last
	Stack 4 : 	Another	Last


So, we can get detail from the example :

* There can be many stackable event handlers, handlers can be added or removed by + / -.

* There can be only one normal event handler, older one will be replaced by the new one.

* When an event is fired, the stackable event handlers are called at the first time, first registered first be called, the normal event handler will be the last.

* Any handler return true will stop the calling operation, any handlers after it won't be called.


It's not good to use the **EventHandler** directly, anytime access the object's **EventHandler**, the object will create the **EventHandler** when not existed. So, fire an event without any handlers will be a greate waste of memeory. There are two ways to do it :

* Using **System.Reflector.FireObjectEvent**, for the previous example :

		self:OnNameChanged(oldName, self.Name)

		-- Change to

		System.Reflector.FireObjectEvent(self, "OnNameChanged", oldName, self.Name)

* Inherit from **System.Object**, then using the **Fire** method :

		class "Person"
			inherit "System.Object"  -- Explained later

			-- Declare the event
			event "OnNameChanged"

			property "Name" {
				Get = function(self)
					return self.__Name or "Anonymous"
				end,

				Set = function(self, name)
					local oldName = self.Name

					self.__Name = name

					-- Fire the event with parameters
					self:Fire("OnNameChanged", oldName, self.Name)
				end,
				Type = System.String + nil,
			}

		endclass "Person"

The inheritance Systems is a powerful feature in the object-oriented program, it makes the class can using the features in its super class.

Here, the **System.Object** class is a class that should be other classes's super class, contains many useful method, the **Fire** method is used to fire an event, it won't create the **EventHandler** object when not needed.


Meta-method
----

In lua, a table can have many metatable settings, like **__call** use the table as a function, more details can be found in [Lua 5.1 Reference Manual](http://www.lua.org/manual/5.1/manual.html#2.8).

Since the objects are lua tables with special metatable set by the Loop system, setmetatable can't be used to the objects. But it's easy to provide meta-method for the objects, take the **__call** as an example :

	class "Person"

		-- Property
		property "Name" {
			Field = "__Name",
			Type = System.String + nil,
		}

		-- Meta-method
		function __call(self, name)
			print("Hello, " .. name .. ", it's " .. self.Name)
		end

	endclass "Person"

So, just declare a global function with the meta-method's name, and it can be used like :

	obj = Person { Name = "Dean" }

	-- Output : Hello, Sam, it's Dean
	obj("Sam")

All metamethod can used include the **__index** and **__newindex**. Also a new metamethod used by the Loop system : **__exist**, the **__exist** method receive all parameters passed to the constructor, and decide if there is an existed object, if true, return the object directly.

	class "Person"

		_PersonStorage = setmetatable( {}, { __mode = "v" })

		-- Constructor
		function Person(self, name)
			_PersonStorage[name] = self
		end

		-- __exist
		function __exist(name)
			return _PersonStorage[name]
		end

	endclass "Person"

So, here is a test :

	print(Person("A"))

Run the test anytimes, the result will be the same.


Inheritance
----

The inheritance system is the most important system in an oop system. In the Loop, it make the classes can gain the object methods, properties, events, metamethods settings from its superclass.

The format is

	inherit ( superclass )

	or

	inherit "superclass path"

The **inherit** keyword can only be used in the class definition. In the previous example, the **Person** class inherit from **System.Object** class, so it can use the **Fire** method defined in it. One class can only have one super class.

* In many scene, the class should override its superclass's method, and also want to use the origin method in it. The key features is, in the class definition, a var named **Super** can be used as the superclass, so here is an example :

		class "A"

			function Print(self)
				print("Here is A's Print.")
			end

		endclass "A"

		class "B"
			inherit "A"

			function Print(self)
				Super.Print( self )

				print("Here is B's Print.")
			end

		endclass "B"

		-- Test part
		obj = B()

		obj:Print()

	So, we got

		Here is A's Print.
		Here is B's Print.

	It's all right if you want keep the origin method as a local var like, it's the quickest way to call functions :

		class "B"
			inherit "A"

			local oldPrint = Super.Print

			function Print(self)
				oldPrint( self )

				print("Here is B's Print.")
			end

		endclass "B"

	But when re-define the **A** class, the **oldPrint** would point to an old version **Print** method, it's better to avoid, unless you don't need to re-define any features.

* With the inheritance system, go back to the property definition :

		property "name" {
			Field = "field",
			Get = "GetMethod" or function(self) end,
			Set = "SetMethod" or function(self, value) end,
			Type = types,
		}

	Normally, if want the property accessors can be changed in the child-classes, it's better to define the get & set object methods, and using the name of the methods as the **Get** & **Set** part's value in the property definition, so the child-class only need to override the object methods to change the behavior of the property accesses. Like the **Person** class :

		class "Person"

			-- Object method
			function GetName(self)
				return self.__Name
			end

			function SetName(self, name)
				self.__Name = name
			end

			-- Property
			property "Name" {
				Get = "GetName",
				Set = "SetName",
				Type = System.String + nil,
			}

			-- Meta-method
			function __call(self, name)
				print("Hello, " .. name .. ", it's " .. self.Name)
			end

		endclass "Person"

	So, when a child-class of the **Person** re-define the **GetName** or **SetName**, there is no need to override the property **Name**.

	If override the property definition in the child-class, the superclass's property will be removed from the child-class.

* Like the object methods, override the metamethods is the same, take **__call** as example, **super.__call** can be used to retrieve the superclass's **__call** metamethod.

* When the class create an object, the object should passed to its super class's constructor first, and then send to the class's constructor, unlike oop system in the other languages, the child-class can't acess any variables defined in super-class's definition environment, it's simple that the child-class focus on how to manipulate the object that created from the super-class.

		class "A"
			function A(self)
				print ("[A]" .. tostring(self))
			end
		endclass "A"

		class "B"
			inherit "A"

			function B(self)
				print("[B]" .. tostring(self))
			end
		endclass "B"

		obj = B()

	Ouput :

		[A]table: 0x7fe080ca4680
		[B]table: 0x7fe080ca4680

* Focus on the event handlers, so why need two types, take an example first :

		class "Person"
			inherit "System.Object"

			event "OnNameChanged"

			property "Name" {
				Field = "__Name",
				Set = function(self, name)
					local oldName = self.__Name

					self.__Name = name

					return self:Fire("OnNameChanged", oldName, name)
				end,
				Type = System.String,
			}

			property "GUID" {
				Field = "__ID",
				Type = System.String,
			}

			function Person(self)
				math.randomseed(os.time())

				local guid = ""

				for i = 1, 8 do
					guid = guid .. ("%04X"):format(math.random(0xffff))

					if i > 1 and i < 6 then
						guid = guid .. "-"
					end
				end

				self.GUID = guid
			end
		endclass "Person"

	Here is a **Person** class definition, it has two properties, one **Name** used to storage a person's name, a **GUID** used to mark the unique person, so we can diff two person with the same name. When a new person add to the system, we create the object with a new guid like :

		person = Person { Name = "Jane" }

	And a new guid is created for the person like 'C2022B9F-ADC2-BBA6-B911-2F670757AD12', then we can save the person's data to somewhere, and when we need we could read the data, and create the person again like :

		person = Person { Name = "Jane", GUID = "C2022B9F-ADC2-BBA6-B911-2F670757AD12" }

	The **Person** class is a simple class used as the root class, we can create many child-class like **Child** and **Adult**, so **Child** should have a **Guardian** property point to another person object, and so on. So, there is an event **OnNameChanged** that fired when the person's name is changed. Now we define a **Member** class inherited from the **Person**, also it will count person based on the name.

		class "Member"
			inherit "Person"

			_NameCount = {}

			-- Class Method
			function _GetMemberCount(name)
				return _NameCount[name] or 0
			end

			-- Event handler
			local function OnNameChanged(self, old, new)
				if old then
					_NameCount[old] = _NameCount[old] - 1
				end

				if new then
					_NameCount[new] = (_NameCount[new] or 0) + 1
				end
			end

			-- Constructor
			function Member(self)
				self.OnNameChanged = self.OnNameChanged + OnNameChanged
			end
		endclass "Member"

	So, in the **Member** class, a stackable handler is added for the object, normally, the stackable handler is used in the child-class's definition, so the child-class won't remove any handler added by its super classes.

	And for the final using, normal handler is easy to write, and the user won't need to know anything about the stackable handlers.

		a = Member { Name = "Jane" }

		function a:OnNameChanged(old, new)
			print(old .. " rename to " .. new)
		end

		-- Output : Jane rename to Ann
		a.Name = "Ann"

		b = Member { Name = "Ann" }
		c = Member { Name = "King" }

		-- Output : Member count for 'Ann' : 2
		print("Member count for 'Ann' : " .. Member._GetMemberCount( "Ann" ))



partclass & re-define
----

* The class can be re-defined, and the object that created from the old version class, will use the new version's features.

		class "A"
		endclass "A"

		obj = A()

		-- Re-define the class A
		class "A"
			function Hi(self)
				print( "Hello" )
			end
		endclass "A"

		-- Outout : Hello
		obj:Hi()

* When re-define a class, its object methods, class methods, events, properties and meta-methods all will be cleared. So :

		class "A"
			function Hi(self)
				print( "Hello" )
			end
		endclass "A"

		obj = A()

		class "A"
		endclass "A"

		-- Error : attempt to call method 'Hi' (a nil value)
		obj:Hi()

* Any global variables with no function values should be kept in the class definition's environment, so we can used it again :

		class "A"
			_Objs = _Objs or {}

			function A(self, name)
				_Objs[name] = self
			end

			function __exist(name)
				return _Objs[name]
			end
		endclass "A"

		print( A("HI") )

		-- Re-define agian
		class "A"
			_Objs = _Objs or {}

			function A(self, name)
				_Objs[name] = self
			end

			function __exist(name)
				return _Objs[name]
			end
		endclass "A"

		print( A("HI") )

	Output :

		table: 0x7fe080c4a410
		table: 0x7fe080c4a410

* partclass is used to start the class definition without clearance :

		class "A"
			function Hi(self)
				print( "Hello" )
			end
		endclass "A"

		obj = A()

		partclass "A"
		endclass "A"

		-- Output : Hello
		obj:Hi()

* When re-define the class, any sub-class will receive the new features that inherited from the super class, won't receive if they have their owns.

		class "A"
		endclass "A"

		class "B"
			inherit "A"
		endclass "B"

		obj = B()

		class "A"
			function Hi(self)
				print( "Hello" )
			end
		endclass "A"

		-- Output : Hello
		obj:Hi()


interface
====

Using the interface is like the class, the format is

	extend ( interface ) ( interface2 ) ( interface3 ) ...

	or

	extend "interface path" "interface2 path" "interface3 path" ...

The definition of an interface is started with **interface** and end with **endinterface** :

	-- Define an interface has one method
	interface "IFGreet"
		function Greet(self)
			print("Hi, I'm " .. self.Name)
		end
	endinterface "IFGreet"

	-- Define an interface with one property
	interface "IFName"
		property "Name" {
			Field = "__Name",
			Type = System.String,
		}
	endinterface "IFName"

	-- Define a class extend from the interfaces
	class "Person"
		-- so the Person class have one method and one property from the two interfaces
		extend "IFName" "IFGreet"
	endclass "Person"

	obj = Person { Name = "Ann" }

	-- Output : Hi, I'm Ann
	obj:Greet()

In the Loop system, the interface system is used to support multi-inheritance. One class can only inherited from one super class, but can extend from no-limit interfaces, also an interface can extend from other interfaces.

Define an interface is just like define a class with little different :

* The interface can't be used to create objects.

* Define events, properties, object methods is the same like the define them in the classes.

* Global method start with "_" are interface methods, can only be called by the interface itself.

* Global method whose name is the interface name, is initializer , will receive object that created from the classes that extend from the interface without any other paramters.

* No meta-methods can be defined in the interface.

* Re-define interface is like re-define a class, any features would be passed to classes that extend from it.

* like the **partclass**, **partinterface** is used to re-define the interface without clearance.


Init & Dispose
----

In class, there may be a constructor, in interface, there may be a initializer, they are used to do the init jobs to the object, and when we don't need the object anymore, we need to clear the object, so it can be collected by the lua's garbage collector.

Normally, if in the definition, we use some table to cache the object's data, when clear the object, we should clear the cache tables, so no reference will keep the object away from garbage collector.

There are a special method used by all objects named **Dispose**, and any class, interface can define a **Dispose** method to clear reference for themselves.

Take one class as the first example :

	class "A"
		-- Used to store real name values
		_Name = {}

		-- Dispose
		function Dispose(self)
			-- remove the reference from _Name
			_Name[self] = nil
		end

		property "Name" {
			Get = function(self) return _Name[self] or "Anonymous" end,
			Set = function(self, name) _Name[self] = name end,
			Type = System.String + nil,
		}
	endclass "A"

	obj = A { Name = "Jane" }

	-- Dispose the object
	obj:Dispose()
	obj = nil

If your class or interface won't add any reference to the object, there is no need to decalre a **Dispose** method. And remember, the obj.Dispose is not A.Dispose, all objects use a same method, and the method would call the **Dispose** method that defined in the classes and interfaces.

So, that leave one problem, what's the order of the init and dispose in the inheritance system. Just an example will show :

	interface "IFA"
	    function Dispose(self)
	        print("IFA <-", self.Name)
	    end

	    function IFA(self)
	        print("IFA ->", self.Name)
	    end
	endinterface "IFA"

	interface "IFB"
	    function Dispose(self)
	        print("IFB <-", self.Name)
	    end

	    function IFB(self)
	        print("IFB ->", self.Name)
	    end
	endinterface "IFB"

	interface "IFC"
	    extend "IFB"

	    function Dispose(self)
	        print("IFC <-", self.Name)
	    end

	    function IFC(self)
	        print("IFC ->", self.Name)
	    end
	endinterface "IFC"

	class "A"
	    extend "IFA"

	    function Dispose(self)
	        print("A <-", self.Name)
	    end
	    function A(self, name)
	        self.Name = name
	        print("A ->", name)
	    end
	endclass "A"

	class "B"
	    inherit "A"
	    extend "IFC"

	    function Dispose(self)
	        print("B <-", self.Name)
	    end

	    function B(self, name)
	        print("B ->", name)
	    end
	endclass "B"

	obj = B("Test")
	print("-----------------------")
	obj:Dispose()

The result :

	A ->	Test
	B ->	Test
	IFA ->	Test
	IFB ->	Test
	IFC ->	Test
	-----------------------
	IFC <-	Test
	IFB <-	Test
	IFA <-	Test
	B <-	Test
	A <-	Test

So, the rule is :

* For the init :

	* The class's constructor would be called before call the interfaces's initializer.

	* All parameter should be passed into the class and all its superclasses's constructor, and the superclass's constructor will be called first.

	* No other parameter would be passed into the interfaces' initializer, the superclass's interface's initializer would be called first, and if the class has more than one interfaces, first extended will be called first.

* For the dispose : just reversed order of the init.


How to use
----

The oop system is used to describe any real world object into data, using the property to represent the object's state like person's name, birthday, sex, and etc, using the methods to represent what the object can do, like walking, talking and more.

The class is used to descrbie a group of objects with same behaviors. Like **Person** for human beings.

The interface don't represent a group of objects, it don't know what objects will use the features of it, but it know what can be used by the objects.

Take the game as an example, to display the health points of the player, we may display it in text, or something like the health orb in the Diablo, and if using text, we may display it in percent, or some short format like '101.3 k'. So, the text or texture is the objects that used to display the data, and we can use an interface to provide the data like :

	interface "IFHealth"

		_IFHealthObjs = {}

		-- Object method, need override
		function SetValue(self, value)
		end

		-- Interface method
		function _SetValue(value)
			-- Refresh all objects's value
			for _, obj in ipairs(_IFHealthObjs) do
				obj:SetValue(value)
			end
		end

		-- Dispose
		function Dispose(self)
			-- Remove the object
			for i, obj in ipairs(_IFHealthObjs) do
				if obj == self then
					return table.remove(_IFHealthObjs, i)
				end
			end
		end

		-- Initializer
		function IFHealth(self)
			-- Register the object
			table.insert(_IFHealthObjs, self)
		end

	endinterface "IFHealth"

In the interface, a empty method **SetValue** is defined, it will be override by the classes that extended from the **IFHealth**, so in the **_SetValue** interface method, there is no need to check whether the object has a **SetValue** method.

And for a text to display the health point, if we have a **Label** class used to display strings with a **SetText** method to display, we can create a new class to do the job like :

	class "HealthText"
		inherit "Label"
		extend "IFHealth"

		-- Override the method
		function SetValue(self, value)
			self:SetText( ("%d"):format(value) )
		end
	endclass "HealthText"

So, when a **HealthText**'s object is created, it will be stored into the **_IFHealthObjs** table, and when the system call

	IFHealth._SetValue(10000)

The text of the **HealthText** object would be refreshed to the new value.



Document
====

**System.Object** and many other features are used before, it's better if there is a way to show details of them, so, a document system is bring in to bind comments for those features.

Take the **System.Object** as an example :

	import "System"

	print( System.Reflector.Help( System.Object ) )

And you should get :

	[__Final__]
	[Class] System.Object :

		Description :
			The root class of other classes. Object class contains several methodes for common use.

		Event :
			OnEventHandlerChanged　-　Fired when an event's handler is changed

		Method :
			ActiveThread　-　Active the thread mode for special events
			BlockEvent　-　Block some events for the object
			Fire　-　Fire an object's event, to trigger the object's event handlers
			GetClass　-　Get the class type of the object
			HasEvent　-　Check if the event type is supported by the object
			InactiveThread　-　Turn off the thread mode for the events
			IsClass　-　Check if the object is an instance of the class
			IsEventBlocked　-　Check if the event is blocked for the object
			IsInterface　-　Check if the object is extend from the interface
			IsThreadActivated　-　Check if the thread mode is actived for the event
			ThreadCall　-　Call method or function as a thread
			UnBlockEvent　-　Un-Block some events for the object


* The first line : [__Final__] means the class is a final class, it can't be re-defined, it's an attribute description, will be explained later.

* The next part is the description for the class.

* The rest is event, property, method list, since the class has no property, only event and method are displayed.

Also, details of the event, property, method can be get by the **Help** method :

	print( System.Reflector.Help( System.Object, "OnEventHandlerChanged" ) )

	-- Ouput :
	[Class] System.Object - [Event] OnEventHandlerChanged :

		Description :
			Fired when an event's handler is changed

		Format :
			function object:OnEventHandlerChanged(name)
				-- Handle the event
			end

		Parameter :
			name - the changed event handler's event name

	---------------------------------------------------------------
	print( System.Reflector.Help( System.Object, "Fire" ) )

	-- Ouput :
	[Class] System.Object - [Method] Fire :

		Description :
			Fire an object's event, to trigger the object's event handlers

		Format :
			object:Fire(event, ...)

		Parameter :
			event - the event name
			... - the event's arguments

		Return :
			nil


Here is a full example to show how to make documents for all features in the Loop system.


	interface "IFName"

		doc [======[
			@name IFName
			@type interface
			@desc Mark the objects should have a "Name" property and "OnNameChanged" event
			@overridable SetName method, used to set the object's name
			@overridable GetName method, used to get the object's name
		]======]

		------------------------------------------------------
		-- Event
		------------------------------------------------------
		doc [======[
			@name OnNameChanged
			@type event
			@desc Fired when the object's name is changed
			@param old string, the old name of the object
			@param new string, the new name of the object
		]======]
		event "OnNameChanged"

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		doc [======[
			@name SetName
			@type method
			@desc Set the object's name
			@param name string, the object's name
			@return nil
		]======]
		function SetName(self, name)
			local oldname = self.Name

			self.__Name = name

			System.Reflector.FireObjectEvent( self, oldname, self.Name)
		end

		doc [======[
			@name GetName
			@type method
			@desc Get the object's name
			@return string the object's name
		]======]
		function GetName(self, ...)
			return self.__Name or "Anonymous"
		end

		------------------------------------------------------
		-- Property
		------------------------------------------------------
		doc [======[
			@name Name
			@type property
			@desc The name of the object
		]======]
		property "Name" {
			Get = "GetName",
			Set = "SetName",
			Type = System.String + nil,
		}
	endinterface "IFName"

	class "Person"
		inherit "System.Object"
		extend "IFName"

		-- Total person count
		_PersonCount = _PersonCount or 0

		-- Total person count of same name
		_NameCount = _NameCount or {}

		doc [======[
			@name Person
			@type class
			@desc Used to represent a person object
			@param name string, the person's name
		]======]

		------------------------------------------------------
		-- Method
		------------------------------------------------------
		doc [======[
			@name _GetPersonCount
			@type method
			@desc Get the person count of the same name or all person count if no name is set
			@format [name]
			@param name string, the person's name
			@return number the person's count
		]======]
		function _GetPersonCount(name)
			if name then
				return _NameCount[name] or 0
			else
				return _PersonCount
			end
		end

		------------------------------------------------------
		-- Dispose
		------------------------------------------------------
		function Dispose(self)
			if self.Name then
				_NameCount[self.Name] = _NameCount[self.Name] - 1
			end
			_PersonCount = _PersonCount - 1
		end

		------------------------------------------------------
		-- Event Handler
		------------------------------------------------------
		local function OnNameChanged(self, old, new)
			if old then
				_NameCount[old] = _NameCount[old] - 1
			end

			if new then
				_NameCount[new] = (_NameCount[new] or 0) + 1
			end
		end

		------------------------------------------------------
		-- Constructor
		------------------------------------------------------
	    function Person(self, name)
	    	self.OnNameChanged = self.OnNameChanged + OnNameChanged

	    	_PersonCount = _PersonCount + 1
	    	self.Name = name
	    end
	endclass "Person"


Normally, the struct and enum's structure can show the use of them, so no document for them. In the class/interface environment, **doc** function can be used to declare documents for the class/interface. it's simple to replace the **doc** by **--**, so just change the whole document as a comment.

The **doc** receive a format string as the document. Using "@" as seperate of each line, the line breaker would be ignored. After the "@" is the part name, here is a list of those part :

* name - The feature's name
* type - The feature's type, like 'interface', 'class', 'event', 'property', 'method'.
* desc - The description
* format - The function format of the constructor(type is 'class' only), event hanlder(type is 'event') or the method(type is 'method')
* param - The parameters of the function, it receive two part string seperate by the first space, the first part is the parameter's name, the second part is the description.
* return - The return value, also receive two part string seperate by the first space, the first part is the name or type of the value, the second part is the description.
* overridable - The features that can be overrided in the interface.
* The documents can be put in any places of the class/interface, no need to put before it's features.

So, we can use the **System.Reflector.Help** to see the details of the **IFName** and **Person** class like :

	print(System.Reflector.Help(IFName))

	-- Output :
	[Interface] IFName :

	Description :
		Mark the objects should have a "Name" property and "OnNameChanged" event

	Event :
		OnNameChanged　-　Fired when the object's name is changed

	Property :
		Name　-　The name of the object

	Method :
		GetName　-　Get the object's name
		SetName　-　Set the object's name

	Overridable :
		SetName - method, used to set the object's name
		GetName - method, used to get the object's name

	-------------------------------------------

	print( System.Reflector.Help( Person ) )

	-- Output :
	[Class] Person :

		Description :
			Used to represent a person object

		Super Class :
			System.Object

		Extend Interface :
			IFName

		Method :
			_GetPersonCount　-　Get the person count of the same name or all person count if no name is set

		Constructor :
			Person(name)

		Parameter :
			name - string, the person's name

	-------------------------------------------

	print( System.Reflector.Help( Person, "_GetPersonCount" ) )

	-- Ouput :

	[Class] Person - [Method] _GetPersonCount :

		Description :
			Get the person count of the same name or all person count if no name is set

		Format :
			Person._GetPersonCount([name])

		Parameter :
			name - string, the person's name

		Return :
			number - the person's count

	-------------------------------------------

	print( System.Reflector.Help( Person, "SetName" ))

	-- Output :

	[Class] Person - [Method] SetName :

	Description :
		Set the object's name

	Format :
		object:SetName(name)

	Parameter :
		name - string, the object's name

	Return :
		nil

So, you can see the class method and object method's format are different.

The last part, let's get a view of the **System** namespace.

	print( System.Reflector.Help( System ))

	-- Output :

	[NameSpace] System :

		Sub Enum :
			AttributeTargets
			StructType

		Sub Struct :
			Any
			Argument
			Boolean
			Function
			Number
			String
			Table
			Thread
			Userdata

		Sub Interface :
			Reflector

		Sub Class :
			Event
			EventHandler
			Module
			Object
			Type
			__Arguments__
			__AttributeUsage__
			__Attribute__
			__Auto__
			__Cache__
			__Final__
			__Flags__
			__NonExpandable__
			__NonInheritable__
			__StructType__
			__Thread__
			__Unique__


* The **AttributeTargets** is used by the attribute system, explained later.
* The **StructType** is used by `__StructType__` attribtue, in the struct part, an example already existed.
* The structs are basic structs, so no need to care about the non-table value structs.
* The **Reflector** is an interface contains many methods used to get core informations of the Loop system, like get all method names of one class.
* The **Argument** struct is used by `__Arguments__` attribtue to describe the arguments of one mehtod or the constructor, explained later.
* The **Event** and **EventHandler** classes are used to create the whole event system. No need to use it yourself.
* The **Module** class is used to build private environment for common using, explained later.
* The **Object** class may be the root class of others, several useful methods.
* The **Type** class, when using *System.Number + System.String + nil*, the result is a **Type** object, used to validate values.
* The rest classes that started with "__" and end with "__" are the attribute classes, explained later.



Module
====

Private environment
----

The Loop system is built by manipulate the lua's environment with getfenv / setfenv function. Like

	-- Output : table: 0x7fd9fb403f30	table: 0x7fd9fb403f30
	print( getfenv( 1 ), _G)

	class "A"
		-- Output : table: 0x7fd9fb4a2480	table: 0x7fd9fb403f30
		print( getfenv( 1 ), _G)
	endclass "A"

	-- Output : table: 0x7fd9fb403f30
	print(getfenv( 1 ))

So, in the class definition, the environment is a private environment belonged to the class **A**. That's why the system can gather events, properties and methods settings for the class, and the **endclass** will set back the environment.

Beside the definition, the private environment also provide a simple way to access namespaces :

	import "System"

	-- Ouput : System.Object
	print( System.Object )

	-- Ouput : nil
	print( Object )

	namespace "Windows.Forms.DataGrid"

	class "A"
		----------------------------------
		-- Ouput : System
		print( System )

		-- Ouput : Windows.Forms
		print(Windows.Forms)

		-- Ouput : nil
		print( Object )

		----------------------------------
		-- Import a namespace
		import "System"

		-- Output : System.Object
		print( Object )
		----------------------------------
	endclass "A"

* Any root namespace can be accessed directly in the private environment, so we can access the **System** and **Windows** directly.
* When import a namespace, any namespace in it can be accessed directly in the private environment.

Since it's a private environment, so, why **print** and other global variables can be accessed in the environment. As a simple example, the things works like :

	local base = getfenv( 1 )

	env = setmetatable ( {}, { __index = function (self, key)
		local value = base[ key ]

		if value ~=  nil then
			rawset(self, key, value)
		end

		return value
	end })

When access anything not defined in the private environment, the **__index** would try to get the value from its base environment ( normally _G ), and if the value is not nil, the value would be stored in the private environment.

When using the class/interface in the program, as the time passed, all variables that needed from the outside will be stored into the private environment, and since then the private environment will be steady, so no need to call the **__index** again and again, it's useful to reduce the cpu cost.


System.Module
----

Like the definition environment, the Loop system also provide a **Module** class to create private environment for common using. Unlike the other classes in the **System** namespace, the **Module** class will be saved to the _G at the same time the Loop system is installed.

So, we can use it directly with format :

	Module "ModuleA[.ModuleB[.ModuleC ... ]]" "version number"

The **Module(name)** will create a **Module** object, and call the object with a string version will change the current environment to the object itself, a module can contains child-modules, the child-modules can access featrues defined in it's parent module, so the **name** can be a full path of the modules, the ModuleB should be a child-module of the ModuleA, the ModuleC is a child-module of the ModuleB, so ModuleC can access all features in ModuleA and ModuleB.

Here is a list of the features in the **Module** :

	print( System.Reflector.Help( Module ) )

	-- Output :

	[__Final__]
	[Class] System.Module :

		Description :
			Used to create an hierarchical environment with class system settings, like : Module "Root.ModuleA" "v72"


		Super Class :
			System.Object

		Event :
			OnDispose　-　Fired when the module is disposed

		Property :
			_M　-　The module itself
			_Name　-　The module's name
			_Parent　-　The module's parent module
			_Version　-　The module's version

		Method :
			GetModule　-　Get the child-module with the name
			GetModules　-　Get all child-modules of the module
			ValidateVersion　-　Return true if the version is greater than the current version of the module


Take an example as the start (Don't forget **do ... end** if using in the interactive programming environment) :

	-- Output : table: 0x7fe1e9403f30
	print( getfenv( 1 ) )

	Module "A" "v1.0"

	-- Output : table: 0x7fe1e947f500	table: 0x7fe1e947f500
	print( getfenv( 1 ), _M )

As you can see, it's special to use the properties of the object, in the module environment, all properties can be used directly, the **_M** is just like the **_G** in the **_G** table.

When the environment changed to the private environment, you can do whatever you'll do in the _G, any global variables defined in it will only be stored in the private environment, and you can access the namespaces just like in a definition environment. There is only one more rule for the module environment :

* Global variables with the name started with "_" can't be accessed by the module environment except the "_G". Take an example to see :

	do
		_Names = {}

		-- Output : table: 0x7fe1e9483500
		print( _Names )

		Module "A" ""

		_Names = _Names or {}

		-- Output : table: 0x7fe1e9483530
		print( _Names )
	end

So, the **_Names** in the Module "A" is a private table not the one in the **_G**, it's a good way to define some private variables, just mark the variables with a name started with "_".


Version Check
----

When using a same module twice with version settings, there should be a version check :

	do
		Module "A" "v1.0"
	end

	do
		-- Error : The version must be greater than the current version of the module.
		Module "A" "v1.0"
	end

If the existed module has a version, the next version must be greater than the first one, the compare is using the numbers in the tail of the version, like "v1.0.12323.1", the version number is "1.0.12323.1" and '1.0.2' is greater than it.

If you want to skip the version check, just keep empty version like :

	do
		Module "B" ""

		function a() end
	end

	do
		Module "B" ""

		-- Output : function: 0x7faac2c5d8f0
		print( a )
	end

Sometimes you may want an anonymous module, that used once. Just keep the name and version all empty :

	do
		Module "" ""

		-- Ouput : table: 0x7faac2c8ff10
		print( _M )
	end

	do
		Module "" ""

		-- Ouput : table: 0x7faac2c8c620
		print( _M )
	end

So, the anonymous modules can't be reused, it's better to use anonymous modules to create features that you don't want anybody touch it.




`System.__Attribute__`
====

In the previous examples, `__Flags__` is used for enum, `__StructType__` is used for struct, and you can find many attribute classes in the **System**.

The attribute classes's objects are used to make some description for features like class, enum, struct. Unlike the document system, those marks can be used by the system or the custom functions to do some analysis or some special operations.

The attribute class's behavior is quite different from normal classes, Since in lua, we can't do it like

	[SerializableAttribute]
	[ComVisibleAttribute(true)]
	[AttributeUsageAttribute(AttributeTargets.Enum, Inherited = false)]
	public class FlagsAttribute : Attribute

in .Net. The Loop system using "__" at the start and end of the attribute class's name, it's not strict, just good for some editor to color it.

The whole attribute system is built on the `System.__Attribute__` class. Here is a list of it :

	[__Final__]
	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.ALL, Inherited = true, AllowMultiple = false, RunOnce = false }]
	[Class] System.__Attribute__ :

		Description :
			The __Attribute__ class associates predefined system information or user-defined custom information with a target element.


		Method :
			------------ The method could be overrided by the attribute class
			ApplyAttribute　-　Apply the attribute to the target, overridable

			------------ The class method called by the Loop system, don't use them
			_ClearPreparedAttributes　-　Clear the prepared attributes
			_CloneAttributes　-　Clone the attributes
			_ConsumePreparedAttributes　-　Set the prepared attributes for target
			_GetCustomAttribute　-　Return the attributes of the given type for the target
			_IsDefined　-　Check whether the target contains such type attribute

			------------ The class method used by the custom programs
			_GetClassAttribute　-　Return the attributes of the given type for the class
			_GetConstructorAttribute　-　Return the attributes of the given type for the class's constructor
			_GetEnumAttribute　-　Return the attributes of the given type for the enum
			_GetEventAttribute　-　Return the attributes of the given type for the class|interface's event
			_GetInterfaceAttribute　-　Return the attributes of the given type for the interface
			_GetMethodAttribute　-　Return the attributes of the given type for the class|interface's method
			_GetPropertyAttribute　-　Return the attributes of the given type for the class|interface's property
			_GetStructAttribute　-　Return the attributes of the given type for the struct
			_GetFieldAttribute　-　Return the attributes of the given type for the struct's field

			_IsClassAttributeDefined　-　Check whether the target contains such type attribute
			_IsConstructorAttributeDefined　-　Check whether the target contains such type attribute
			_IsEnumAttributeDefined　-　Check whether the target contains such type attribute
			_IsEventAttributeDefined　-　Check whether the target contains such type attribute
			_IsInterfaceAttributeDefined　-　Check whether the target contains such type attribute
			_IsMethodAttributeDefined　-　Check whether the target contains such type attribute
			_IsPropertyAttributeDefined　-　Check whether the target contains such type attribute
			_IsStructAttributeDefined　-　Check whether the target contains such type attribute
			_IsFieldAttributeDefined　-　Check whether the target contains such type attribute


`System.__Final__`
----

The first line show the class is a final class, `System.__Final__` is a class inherited from the `System.__Attribute__` and used to mark the class, interface, struct and enum as final, final features can't be re-defined. Here is an example, Form now on, using **Module** as the environment :

	Module "A" ""

	import "System"

	__Final__()
	class "A"
	endclass "A"

	-- Error : The class is final, can't be re-defined.
	class "A"
	endclass "A"

So, creating an object of the `__Final__` class before the definition, then the features should be set to final.

Like how to use the `__Final__`, using any attribtue class is just create an object with init values before its target.


`System.__AttributeUsage__`
----

The second line :

	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.ALL, Inherited = true, AllowMultiple = false, RunOnce = false }]

The `System.__AttributeUsage__` is also an attribute class inherited from the `System.__Attribute__`, it can be used on an attribute class, and used to describe how the attribute class can be used.

	[__Final__]
	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.CLASS, Inherited = false, AllowMultiple = false, RunOnce = false }]
	[Class] System.__AttributeUsage__ :

	Description :
		Specifies the usage of another attribute class.

	Super Class :
		System.__Attribute__

	Property :
		AllowMultiple　-　whether multiple instances of your attribute can exist on an element. default false
		AttributeTarget　-　The attribute target type, default AttributeTargets.All
		Inherited　-　Whether your attribute can be inherited by classes that are derived from the classes to which your attribute is applied. Default true
		RunOnce　-　Whether the property only apply once, when the Inherited is false, and the RunOnce is true, the attribute will be removed after apply operation

For the attribute system, attributes can be applied to several types (Defined in System.AttributeTargets) :

	[Enum][__Flags__] System.AttributeTargets :
	    ALL = 0
	    CLASS = 1
	    CONSTRUCTOR = 2
	    ENUM = 4
	    EVENT = 8
	    INTERFACE = 16
	    METHOD = 32
	    PROPERTY = 64
	    STRUCT = 128
	    FIELD = 256

* All - for all below features :
* Class - for the class
* Constructor - for the class's constructor, now, only `__Arguments__` attribute needed to set the arguments count and type for the constructor.
* Eum - for the enum
* Event - for the class / interface's event
* Interface - for the interface
* Method - for the method of the class, struct and interface
* Property - for the property of the class and interface
* Struct - for the struct
* Field - for the struct's field

So, take the `__Final__` class as an example to show how the `__AttributeUsage__` is used :

	[__Final__]
	[__Unique__]
	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.ENUM + System.AttributeTargets.INTERFACE + System.AttributeTargets.CLASS + System.AttributeTargets.STRUCT, Inherited = false, AllowMultiple = false, RunOnce = true }]
	[Class] System.__Final__ :

	Description :
		Mark the class|interface|struct|enum to be final, and can't be re-defined again


	Super Class :
		System.__Attribute__

	Method :
		ApplyAttribute　-　Apply the attribute to the target, overridable

Since the **AttributeTargets** is a flag enum, the **AttributeTarget** property can be assigned a value combined from several enum values.


`System.__Flags__`
----

As the previous example in the enum part, that's the using of the `System.__Flags__`.


`System.__Unique__`
----

In the list of the `__Final__`, a new attribute is set, the `System.__Unique__` attribute is used to mark the class can only have one object, anytime using the class create object will return an unique object, the object can't be disposed.

Like :

	Module "B" ""

	import "System"

	__Unique__()
	class "A"
	endclass "A"

	obj = A{ Name = "AA" }

	-- Output : table: 0x7f8ed149a290	AA
	print(obj, obj.Name)

	obj = A{ Name = "BB" }

	-- Output : table: 0x7f8ed149a290	BB
	print(obj, obj.Name)

It's useful to pass init table to modify the unique object.

The `__Unique__` attribute normally used on attribute classes, avoid creating too many same functionality objects.


`System.__NonInheritable__`
----

The `System.__NonInheritable__` attribute is used to mark the classs/interface can't be inherited/extended. So no child-class/interface could be created for them.

	Module "C" ""

	import "System"

	__NonInheritable__()
	class "A"
	endclass "A"

	class "B"
		-- Error : A is non-inheritable.
		inherit "A"
	endclass "B"

BTW. if using the `__Unique__` attribute, the class is also non-inheritable, since it can only have one unique object.


`System.__Arguments__`
----

	[__Final__]
	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.CONSTRUCTOR + System.AttributeTargets.METHOD, Inherited = true, AllowMultiple = false, RunOnce = false }]
	[Class] System.__Arguments__ :

		Description :
			The argument definitions of the target method or class's constructor


		Super Class :
			System.__Attribute__

		Method :
			ApplyAttribute　-　Apply the attribute to the target, overridable

The `System.__Arguments__` attribute is used on constructor or method, it's used to mark the arguments's name and types, it use **System.Argument** struct as a partner :

	[__Final__]
	[Struct] System.Argument :

		Field:
			Name = System.String　			-　The name of the argument
			Type = System.Any　				-　The type of the argument
			Default = System.Any　			-　The defalut value of the argument
			IsList = System.Boolean + nil 	-　Whether the rest are a list of the same type argument, only used for the last argument

So, take a method as the example first :

	Module "D" ""

	import "System"

	class "A"

		__Arguments__{
			Argument{ Name = "Count", Type = Number },
			Argument{ Name = "...", Type = String, IsList = true }
		}
		function Add(self, count, ...)
			for i = 1, count do
				self[i] = select(i, ...)
			end
		end
	endclass "A"

	obj = A()

	-- Error : Usage : A:Add(Count, ...) - Count must be a number, got nil.
	obj:Add()

	-- Error : Usage : A:Add(Count, ...) - ... must be a string, got number.
	obj:Add(3, "hi", 2, 3)

So, you can see, the system would do the arguments validation for the method, this is not recommend.

The `__Arguments__` is very powerful for the constructor part, when talking about *Init the object with a table*, no values should be passed to the constructor, but with the `__Arguments__`, some special variables in the init table should be passed to the constructor:

	Module "E" ""

	import "System"

	class "A"

		__Arguments__{
			Argument{ Name = "Name", Type = String, Default = "Anonymous" },
		}
		function A(self, name)
			print("Init A with name " .. name)
		end
	endclass "A"

	-- Output : Init A with name Hello
	obj = A { Name = "Hello" }

	-- Output : nil
	print(obj.Name)

	-- Output : Init A with name Anonymous
	obj = A {}

	-- Error : Usage : A(Name = "Anonymous") - Name must be a string, got number.
	obj = A { Name = 123 }

So, the constructor would take what it need to do the init, and the variables also removed from the init table. So using the `__Arguments__` attribute is a good way to combine the **constructor** and the **init with table**. It's recommended.


`System.__StructType__`
----

Introduced in the struct part.


`System.__Cache__`
----

In the class system, all methods(include inherited) are stored in a class cache for objects to use. Normally, it's enough for the require. But in some scenarios, we need acces those methods very frequently, sure you can do it like :

	class "A"
		function Greet(self) end
	endclass "A"

	obj = A()
	obj.Greet = obj.Greet  -- so next time access the 'Greet' is just a table field

But write the code everytime is just a pain. So, here comes the `System.__Cache__` attribute :

	[__Final__]
	[__Unique__]
	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.CLASS + AttributeTargets.INTERFACE + System.AttributeTargets.METHOD, Inherited = true, AllowMultiple = false, RunOnce = false }]
	[Class] System.__Cache__ :

		Description :
			Mark the class so its objects will cache any methods they accessed, mark the method so the objects will cache the method when they are created, if using on an interface, all object methods defined in it would be marked with **__Cache__** attribute .


		Super Class :
			System.__Attribute__

It can be used on the class, interface or method, when used on the class, all its objects will cache a method when they access the method for the first time. When used on a method, the method should be saved to the object when the object is created :

	Module "F" ""

	import "System"

	__Cache__()
	class "A"

		function Greet(self)
		end

	endclass "A"

	obj = A()

	-- Output : nil
	print(rawget(obj, "Greet"))

	obj:Greet()

	-- Output : function: 0x7feb0842d110
	print(rawget(obj, "Greet"))

	---------------------------

	class "B"

		__Cache__()
		function Greet(self)
		end

	endclass "B"

	obj = B()

	-- Output : function: function: 0x7feb084884d0
	print(rawget(obj, "Greet"))

It would be very useful to mark some most used methods with the attribute.


`System.__NonExpandable__`
----

Sometimes we may want to expand the existed class/interface with a simple way, like set a function to the class/interface directly. To do this, we can set a function value to the class/interface as a field, if there is no other method with the field name, the function will be added as a method :

	Module "G" ""

	import "System"

	class "A"
	endclass "A"

	obj = A()

	A.Greet = function(self) print("Hello World") end

	-- Output : Hello World
	obj:Greet()

If want forbidden those features, the `__NonExpandable__` attribute is used :

	Module "G2" ""

	import "System"

	__NonExpandable__()
	class "A"
	endclass "A"

	obj = A()

	-- Error : Can't set value for A, it's readonly.
	A.Greet = function(self) end

BTW, mark a class/interface with `__Final__` attribute, the class/interface still can be expanded.


`__Auto__`
----

The attribute is only applied to the properties, here is the detail of it :

	[__Final__]
	[__Unique__]
	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.PROPERTY, Inherited = false, AllowMultiple = false, RunOnce = true }]
	[Class] System.__Auto__ :

		Description :
			Auto-generated property body


		Super Class :
			System.__Attribute__

		Property :
			Default - The default value of the property
			Field - The target field, auto-generated if set to true
			Method - True to use object methods with the name like ('Set/Get' + property's name) as the accessors
			Type - The type of the property

		Method :
			ApplyAttribute - Apply the attribute to the target, overridable

Since lua is a dynamic language, in some non-restricted scene, we may like to the minimum informations for the properties, Like :

	property "Name" {
		Field = "__Name",
	}

Only a field to the property, if you don't want see the real field, a simple way is use the `__Auto__` attribtue :

	class "A"

		__Auto__{ Field = true }
		property "Name" {}

	endclass "A"

So, the attribute would generate a field for the property, in this example, the field is :

	__A_Name

Using the class's name to reduce conflict between super class and its child-classes.

Also, for a class :

	class "A"

		function SetName(self, name)
			self.__Name = name
		end

		function GetName(self)
			return self.__Name
		end

		property "Name" {
			Get = "GetName",
			Set = "SetName",
		}
	endclass "A"

(Btw. `Get = "GetName"` Also can be `Get = GetName,` but since the child-class can override the GetName, it's better to keep using the child-class's newest method.)

We can use the `__Auto__` attribute to re-write like :

	class "A"

		function SetName(self, name)
			self.__Name = name
		end

		function GetName(self)
			return self.__Name
		end

		__Auto__{ Method = true, Type = System.String }
		property "Name" {}
	endclass "A"

The `__Auto__` won't override the existed settings, so you can combine it with normal definitions :

	class "A"

		function SetName(self, name)
			self.__Name = name
		end

		function GetName(self)
			return self.__Name
		end

		__Auto__{ Method = true }
		property "Name" {
			Type = System.String,
			Default = "Anonymous",
		}
	endclass "A"

But it's better to keep it in one format like :

	class "A"

		function SetName(self, name)
			self.__Name = name
		end

		function GetName(self)
			return self.__Name
		end

		__Auto__{ Method = true, Type = System.String, Default = "Anonymous",}
		property "Name" {}
	endclass "A"

Or

	class "A"

		function SetName(self, name)
			self.__Name = name
		end

		function GetName(self)
			return self.__Name
		end

		property "Name" {
			Get = "GetName",
			Set = "SetName",
			Type = System.String,
			Default = "Anonymous",
		}
	endclass "A"


Custom Attributes
----

The above attributes are all used by the core system of the Loop. But also this is a powerful system for common using.

Take a database table as example, a lua table(object) can be used to store the field data of one row of the data table. So, here are the datas :

	DataTable = {
		[1] = {
			ID = 1,
			Name = "Ann",
			Age = 22,
		},
		[2] = {
			ID = 2,
			Name = "King",
			Age = 33,
		},
		[3] = {
			ID = 3,
			Name = "Sam",
			Age = 18,
		}
	}

Now, I need a function to manipulate the datatable, but I don't know the detail of the datatable like the field count, type and orders.

So, the best way is the data can tell us what datatable it is and also the field informations.

We could define a struct used to represent one row of the datatable like :

	Module "DataTable" ""

	import "System"

	struct "Person"
		ID = Number
		Name = String
		Age = Number
	endclass "Person"

But since the function won't know how to use the **Person** table ( we don't want a function to handle only one data type ), we need use some attributes to describe them.

First, two attribute classes are defined here :

	Module "DataTable" ""

	__AttributeUsage__{AttributeTarget = AttributeTargets.Struct}
	class "__Table__"
		inherit "__Attribute__"

		property "Name" {
			Field = "__Name",
			Type = String,
		}
	endclass "__Table__"

	__AttributeUsage__{AttributeTarget = AttributeTargets.Field}
	class "__Field__"
		inherit "__Attribute__"

		property "Name" {
			Field = "__Name",
			Type = String,
		}

		property "Index" {
			Field = "__Index",
			Type = Number,
		}

		property "Type" {
			Field = "__Type",
			Type = String,
		}
	endclass "__Field__"

The `__Table__` attribute is used on the struct, used to mark the struct with the datatable's name, so we can bind it to the real table in the database.

The `__Field__` attribute is used on the field, used to mark the field to a field of a datatable, the **Name** to the field's name, **Index** to the field's display index, and the **Type** to the field's type (not the type of the Loop).

So, here re-define the **Person** struct :

	Module "DataTable" ""

	__Table__{ Name = "Persons" }
	struct "Person"
		__Field__{ Name = "No.", Index = 1, Type = "NUMBER(10, 0)" }
		ID = Number

		__Field__{ Name = "Name", Index = 2, Type = "VARCHAR2(30)" }
		Name = String

		__Field__{ Name = "Age", Index = 3, Type = "NUMBER(3, 0)" }
		Age = Number
	endstruct "Person"

Now, we can use them to store the datatable and make a common function to display the datas (BTW, use **init table** on a struct won't create a new table, only do the validation and return the **init table** as the result) :

	Module "DataTable" ""

	data = {
		Person { ID = 1, Name = "Ann", Age = 22 },
		Person { ID = 2, Name = "King", Age = 33 },
		Person { ID = 3, Name = "Sam", Age = 18 },
	}

	-- Define the function used to print the data of a struct has attributes as descriptions
	function PrintData(strt, objs)
		-- Handle the struct's attribute
		local tbl = __Attribute__._GetStructAttribute(strt, __Table__)

		if tbl then
			print("Table : " .. tbl.Name)
			print("-----------------------")
		end

		-- Handle the field's attribute
		local cols = {}
		local colnames = {}

		for _, part in ipairs(Reflector.GetStructParts(strt)) do
			local field = __Attribute__._GetFieldAttribute(strt, part, __Field__)

			if field then
				cols[field.Index] = part
				colnames[field.Index] = field.Name
			end
		end

		-- Print the data
		local str = ""

		for i, name in ipairs(colnames) do
			str = str == "" and (str .. name) or (str .. "\t\t" .. name)
		end

		print(str)

		for i, data in ipairs(objs) do
			str = ""

			for _, part in ipairs(cols) do
				str = str == "" and (str .. data[part]) or (str .. "\t\t" .. data[part])
			end

			print(str)
		end
	end

	-- Print the data
	PrintData(Person, data)

The final result is :

	Table : Persons
	-----------------------
	No.		Name		Age
	1		Ann			22
	2		King		33
	3		Sam			18

Some points about the function :

* `__Attribute__._GetStructAttribute(strt, __Table__)` will try to get struct attribute of the `__Table__` for the struct, the return value is an object of the `__Table__` if existed. So, then we could get the datatable's name.
* `Reflector.GetStructParts` used to get a list of the struct's all fields. You can use **Help** to see the detail of it.
* `__Attribute__._GetFieldAttribute(strt, part, __Field__)` like **_GetStructAttribute**, only need a more argument : the field's name.



Thread
====

In the **System.Object** class, there is methods like **ActiveThread**, **ThreadCall**, also an attribute **System.__Thread__**, those features are used to bring the coroutine system into the Loop system.

System.Object.ThreadCall
----

	[Class] System.Object - [Method] ThreadCall :

		Description :
			Call method or function as a thread

		Format :
			object:ThreadCall(methodname|function, ...)

		Parameter :
			methodname|function
			... - the arguments

		Return :
			nil




Tips
====













