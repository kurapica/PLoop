Pure lua object-oriented program system
====

PLoop provide a oop system with a special sugar syntax system. Several features contains in it:

* Namespace system used to contains custom types.
* Enum system used to define enumeration value types.
* Struct system used to define structure value types.
* Class system used to define object types with methods and properties settings, also with object events and meta-methods.
* Interface system used to define interfaces for class objects.

* Attribute system used to give descriptions for every parts of the system: enum, struct, class, interface, method, property, event. Those are useful for frameworks and adding system features in a good manner.
* Overload system used to apply several definitions for class's constructor, method or meta-method with the same name, will make the config features easily to be defined.


Now, it only works for Lua 5.1. Since the **getfenv**, **setfenv**, **newproxy** api is removed from Lua 5.2, the system won't works on it now, or you can provide them in another way.



How to use
====

Use loadfile or require to load the **PLoop.lua** file in the folder. Then you can try the below code:

	do
		-- Define a class
		class "MyClass"
			property "Name" { Type = System.String }

			function Greet(self, name)
				print("Hello " .. name .. ", My name is " .. self.Name)
			end
		endclass "MyClass"
	end

Now we create a class with a **Greet** method and a **Name** property. Then we can use it like :

	do
		-- Create the class's object, also with init settings, the init table can contains properties settings
		-- and many more settings in it, will be explained later.
		ob = MyClass{ Name = "Kurapica" }

		-- Call the object's method, Output : Hello Ann, My name is Kurapica
		ob:Greet("Ann")

		-- Property settings, 123 is not a string, so Error : Name must be a string, got number.
		ob.Name = 123
	end

Here I use **do ... end** because you may try those code in an interactive programming environment, many definitions like class, struct, interface's definitions should be kept in one piece. After here, I won't use **do ... end** again, but just remember to add it yourself.



Features
====

There are some keywords that the system will released into the _G :

* namespace
* import
* enum
* struct
* class
* interface
* Module

The **namespace** & **import** are used to control the namespace system used to store classes, interfaces, structs and enums.

The **enum** is used to define enum types.

The **struct** is used to start the definition of a struct type. A data of a struct type, is a normal table in lua, without metatable settings, the basic lua value types like string, number, thread, function, userdata, boolean are also defined in the **PLoop** system as struct types. The struct types are used to validate or create the values that follow the explicitly structure that defined in the struct types, like position on a cartesian coordinates, we only need values like { x = 13.4, y = 33 }.

The **class** is used to start the definition of a class. In an object-oriented system, the core part is the objects. One object should have methods that used to show what jobs the object can do, also should have properties to store the data used to mark the object's state. A class is an abstract from objects of the same type, it can contains the definition of the methods and properties so the object won't do these itself.

The **interface** is used to start the definition of an interface. Sometimes we may not know the true objects that our program will manipulate, or we want to manipulate objects from different classes, we only want to make sure the objects will have some features that our program needs, like objects have a **Name** property. So, the interface is bring in to provide such features. No objects can be created from an interface, the interface can be extended by classes.

The **Module** is used to start a standalone environment with version check, and make the development with the **PLoop** system more easily, like we don't need to write down full path of namespaces. This topic will be discussed at last.



namespace & import
====

In an oop project, there may be hundred or thousand classes or other data types to work together, it's important to manage them in groups. The namespace system is bring in to store the classes and other features.

In the namespace system, we can access those features like classes, interfaces, structs with a path string.

A full path looks like **System.Forms.EditBox**, a combination of words separated by '.', in the example, **System**, **System.Forms** and **System.Forms.EditBox** are all namespaces, the namespace can be a pure namespace used only to contains other namespaces, but also can be classes, interfaces, structs or enums, only eums can't contains other namespaces.


The **import** function is used to save the target namespace into current environment, the 1st paramter is a string that contains the full path of the target namespace, so we can share the classes and other features in many lua files(environments), the 2nd paramter is a boolean value, if true, then all the sub-namespace of the target namespace will be saved to the current environment too.

    import (name[, all])


If you already load the PLoop.lua, you can try some example :

	import "System"  -- Short for import( "System" ), just want make it looks like a keyword

	print( System )          -- Output : System
	print( System.Object )   -- Output : System.Object
	print( Object )          -- Output : nil

	import ( "System", true )

	print( Object )          -- Output : System.Object

The System is a root namespace defined in the PLoop.lua file, some basic features are defined in the namespace, such like **System.Object**, could be used as the super class of other classes(Unlike other oop system, there is no default super class, for lua, simple is good).

Also you can see, **Object** is a sub-namespace in **System**, we can access it just like a field in the **System**.

---

The **namespace** function is used to declare a default namespace for the current environment, so any classes, interfaces, structs and enums that defined after it, will be stored in the namespace as sub-namespaces.

	namespace ( name )

Here a simple example :

	namespace "MySpace.Example"  -- Decalre a new namespace for the current environment

	class "NewClass"             -- The class also be stored in current environment when defined.
	endclass "NewClass"

	print( NewClass )            -- Output : MySpace.Example.NewClass

The namespace system is used to share features like classes, if you don't declare a namespace for the environment, those features that defined later will be private.



enum
====

enum is used to define new value types with enumerated values.

First, an example is used to show how to create a new enum type :

	import "System"

	-- Define a enum data type
	enum "Week" {
		"Sunday",
		Monday = "Monday",
		"Tuesday",
		Wednesday = 3,
	    thur = "Thursday",
	    "Friday",
	    "Saturday",
	}

	-- Access the values like table field, case ignored
	print( Week.SuNday )	-- Sunday
	print( Week.Sunday )	-- Sunday
	print( Week.THUR )		-- Thursday

	print( Week.wedNesday )	-- 3

	-- Call the enum as a function, parse the value to the text
	-- Output : 'WEDNESDAY'
	print( Week( 3 ) )


The true format of the 'enum' function is

	enum( name )( table )

The **name** is a common string word, **enum(name)** should return a function to receive a table as the definition of the enum data type.

In the **table**, for each key-value pairs, if the key is **string**, the key would be used as the value's name, if the key is a number and the value is a string, the value should be used as the value's name, so the 'Sunday' is the value's name in the enum **Week**.

So, you can get the value of an enumeration like a case ignored field, and get the enumeration from the value like a function call, it's a simple value type.


---


Sometimes, we may need use the enum values as a combination, like Week.SUNDAY + Week.SATURDAY as the weekend days. We could use the `System.__Flags__` attribute to mark the enum data type as bit flags data type (The Attribute system will be explained later, using `System.__Flags__` is so simple so just remember it).

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
	    "SATURDAY",
	}

	-- Output : 64
	print( Week.SATURDAY )

	-- Output : 65
	print( Week.SUNDAY + Week.SATURDAY )

	-- Output : SATURDAY	SUNDAY
	print( Week( 65 ) )


The enumeration values should be 2^n, and the system would provide auto values if no value is set or not correct, so the Week.SATURDAY is 64.

So use the enum type as function to parse the value, will return multi-values of the combination.


struct
====

The main purpose of the struct system is used to validate values, for lua, the values can be boolean, number, string, function, userdata, thread and table.

And in the **System** namespace, each basic data type have a **custom** struct type defined for it :

* System.Boolean - The value should be mapped to true or false, no validation
* System.String  - means the value should match : type(value) == "string"
* System.Number  - means the value should match : type(value) == "number"
* System.Function  - means the value should match : type(value) == "function"
* System.Userdata  - means the value should match : type(value) == "userdata"
* System.Thread  - means the value should match : type(value) == "thread"
* System.Table  - means the value should match : type(value) == "table"
* System.RawTable  - means the value should match : type(value) == "table" and getmetatable(value) == nil
* System.Any - Any value

Those are the **basic** struct types, take the **System.Number** as an example to show how to use :

	import "System"

	-- Output : 123
	print( System.Number( 123 ) )

	-- Error : [Number] must be a number, got string.
	print( System.Number( '123' ))

All structs can be used to validate values. ( Normally, you only need to declare where and what type is needed, the validation will be done by the system.)

When the value is a table, and we may expect the table contains fields with expected type values, and the **System.Table** can only be used to check whether the value is a table.

Take a position table as the example, we may expect the table has two fields : **x** - the horizontal position, **y** - the vertical position, and the fields' values should all be numbers. So, we can declare a **member** struct type like :

	struct "Position"
		x = System.Number
		y = System.Number
	endstruct "Position"

Here, **struct** keyword is used to begin the declaration, and **endstruct** keyword is used to end the declaration. Anything defined between them will be the definition of the struct.

The expression *x = System.Number*, the left part **x** is the member name, the right part **System.Number** is the member's type.

the type can be any classes, interfaces, enums or structs :

* For a given class, the value should be objects that created from the class.
* For a given interface, the value should be objects whose class extend from the interface.
* For a given enum, the value should be the enum value or the value's name.
* For a given struct, the value should pass the validation of the struct.

So, we can test the custom struct now :

	-- Use the struct type as a validator
	pos = Position {x = 123, y = 456}

	-- Output : 123	-	456
	print(pos.x, '-', pos.y)

	-- Error : Usage : Position(x, y) - y must be a number, got nil.
	pos = Position {x = 111}

	-- Use the struct type as a constructor,
	-- the 'x' member is first defined, it will receive the 1st argument, so the 'y' member take the 2nd.
	pos = Position(110, 200)

	-- Output : 110	-	200
	print(pos.x, '-', pos.y)


---

In the struct's definition, there is no need to use `import "System"` to import the **System** namespace, the root namespace like **System** can be accessed directly, if you want use **Number** directly, also, can use `import "System"` like :

	struct "Position"
		import "System"

		x = System.Number
		y = System.Number
	endstruct "Position"

The struct is the first type that defined with those special syntax, so here is an explanation :

* PLoop is designed based on controlling lua environment, so all type definitions can be tracke by the PLoop system and won't effect the common lua coding.

* The struct keyword start the declaration, and also changed the current lua environment to a private table for the struct type's definition

* The private environment can access any global features in the outside environment (mostly _G) , also has a cache system to increase performance, so normally you don't need to care how the track system working.

* The private environment can access any root namespaces such like **System** directly, also can access any sub-namespaces of the namespaces that imported, so **Number** can be accessed just by import the **System**, those features can't be done in the _G.

* There is no need to use **namespace** to give a namespace for the private environment, the private environment's namespace is the struct type itself.

* The code of the definition will be running in the private environment, so the PLoop system can track all the special defintions like `x = System.Number`, this is a simple assignment, but the value is a type, so the PLoop system know the **x** is a field of the struct.

* Except the special defintions, other definitions will be passed to do the default job, like :

		struct "Position"
			import "System"

			-- Simple lua code
			a = 123
			print(a)

			-- Special definition
			x = System.Number
			y = System.Number
		endstruct "Position"

		-- nil, a is defined in the private environment, no where get it
		print(a)

* endstruct is used to finished the defintion of the struct, and change back the lua environment, so the **struct ... enstruct** works just like define a function to keep all code in one piece.

* The struct can be redefined any times(we'll see how to disable it in later), each time a new private environment will be used to make sure the previous defintion won't affect the new one :


		struct "Position"
			import "System"

			-- Simple lua code
			x = 123

			-- Special definition
			y = System.Number
		endstruct "Position"

		struct "Position"
			import "System"

			-- Special definition
			x = System.Number
			y = System.Number
		endstruct "Position"

	If the redefine code using the same private environment, and **x** has a value 123, then `x = System.Number` won't be tracked by the system, so **x** won't be treated as a struct's field. Each time using a new private environment will keep the problem out the way.


---

In the previous example, the **x** and **y** field can't be nil, we can redefine it to make the field accpet nil value :

	struct "Position"
		x = System.Number + nil
		y = System.Number + nil
	endstruct "Position"

	-- No error now
	pos = Position {x = 111}

Normally, the type part can be a combination of lots types seperated by '+', **nil** used to mark the value can be nil, so *System.Number + System.String + nil* means the value can be number or string or nil.

---

If you want default values for the fields, we can add a **Validate** method in the definition, this is a special method used to do custom validations, so we can do some changes in the method.

	struct "Position"
		x = System.Number + nil
		y = System.Number + nil

		function Validate(value)
			value.x = value.x or 0
			value.y = value.y or 0
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
			-- Don't forget use the struct type to validate the return value
			-- It may be looks strange, but remember, the Position here is the struct type not the function
			return Position { x = x or 0, y = y or 0 }
		end
	endstruct "Position"

	-- Use struct type as validator won't go through the constructor
	pos = Position {x = 111}

	-- Output : 111	-	nil
	print(pos.x, '-', pos.y)

	pos = Position (111)

	-- Output : 111	-	0
	print(pos.x, '-', pos.y)

	-- Error : Usage : Position([x, y]) - x must be a number, got string.(Optional)
	pos = Position ('X', 'Y')

	-- Output : X	-	Y
	print(pos.x, '-', pos.y)


There are not many things can be done in the constructor, the struct know how to create tables based on the field settings, and the **Validate** function works better than the constructor, so just forget the constructor.

---

In sometimes, we need validate the values and fire new errors, those operations also can be done in the **Validate** method. Take a struct with two members : **min**, **max**, the **min** value can't be greater than the **max** value, so we should write :

	struct "MinMax"
		min = System.Number
		max = System.Number

		function Validate(value)
			assert(value.min <= value.max, "%s.min can't be greater than %s.max.")
		end
	endstruct "MinMax"

	-- Error : Usage : MinMax(min, max) - min can't be greater than max.
	minmax = MinMax(200, 100)

In the error message, there are two "%s." used to represent the value, and will be replaced by the validation system considered by where it's using. Here an example to show :

	struct "Value"
		value = System.Number
		minmax = MinMax
	endstruct "Value"

	-- Error : Usage : Value(value, minmax) - minmax.min can't be greater than minmax.max.
	v = Value(100, {min = 200, max = 100})

So, you can quickly find where the error happened.

Remember, when a value is passed to the **Validate** method, it has already passed the type checking, so no need to check it again in your custom validation.

---

We also may want to validate numeric index table of a same type values, like a table contains only string values :

	a = {"Hello", "This", "is", "a", "index", "table"}

We can declare a **array** struct for those types (A special attribtue for the struct):

	import "System"

	System.__StructType__( "array" )
	struct "StringTable"
		element = String
	endstruct "StringTable"

	-- Error : Usage : StringTable(...) - [3] must be a string, got number.
	a = StringTable{"Hello", "World", 3}

It's looks like the **member** struct, but the field name **element** has no means, it's just used to declare the element's type, you can use **element**, **ele** or anything else.

The **"array"** is an enumeration value of System.StructType, there are three type structs, **"custom"**, **"member"** and **"array"**, **"custom"** is used for special values that not table, all has be defined in the **System** namespace like **System.Number**, if no struct type is specified by `__StructType__`, **"member"** is the default type, so we only need use the attribute when defining an array struct type.


---

Now, let's defined a special struct type :

	struct "Person"
		import "System"

		__StructType__( "array" )
		struct "Children"
			ele = Person
		endstruct "Children"

		enum "Gender" {
			"male",
			"female",
		}

		name = String
		gender = Gender
		father = Person + nil
		mother = Person + nil
		children = Children + nil

		-- generate the relationship
		function Validate(value)
			if value.children then
				for _, child in ipairs(value.children) do
					if value.gender == Gender.Male then
						child.father = value
					else
						child.mother = value
					end
				end
			end
		end

	endstruct "Person"

The **Person** struct is a **member** struct type, it contains an enum type named **Gender**, like I said, the private environment using the struct type as the namespace, so the enum can be accessed like **Person.Gender**.

Also an **array** struct type is defined in it with name **Children**, specially, it using **Person** as its element's type, when using `struct "Person"`, the **Person** struct type is created and can be used, no matter its definition is finished or not.

The **Person** struct need a **name** field to store its name, **gender** to store its gender, and three optional field to store the relationship between the person objects.

Also a custom validation is added to generate the relationship for person objects, here is the test :

	king = Person {
		name = "King",
		gender = "male",
		children = {
			Person {
				name = "Ann",
				gender = "female",
				children = {
					Person ("Kite", "female"),
				},
			},
		}
	}

	kite = king.children[1].children[1]

	-- king
	print(kite.mother.father.name)

---

The last part about the struct is the struct methods. Any functions that defined in the struct definition, if the name is not the **Validate** and the struct's name, will be treated as the struct methods, and those methods will be copyed to the data when created or validated.

Now we give the **Person** struct type a new method to add child :

	struct "Person"
		import "System"

		__StructType__( "array" )
		struct "Children"
			ele = Person
		endstruct "Children"

		enum "Gender" {
			"male",
			"female",
		}

		name = String
		gender = Gender
		father = Person + nil
		mother = Person + nil
		children = Children + nil

		-- generate the relationship
		function Validate(value)
			if value.children then
				for _, child in ipairs(value.children) do
					if value.gender == Gender.Male then
						child.father = value
					else
						child.mother = value
					end
				end
			end
		end

		-- Add Child
		function AddChild(self, child)
			-- don't forget validate the child
			child = Person( child )

			self.children = self.children or {}

			table.insert(self.children, child)

			if self.gender == Gender.Male then
				child.father = self
			else
				child.mother = self
			end
		end

	endstruct "Person"

	king = Person("King", "male")
	kite = Person("Kite", "female")

	king:AddChild(kite)

	-- King
	print(kite.father.name)

	-- function: 00865FE0
	print( rawget(kite, "AddChild") )


So, the methods are just copied to the datas.It's useful when you don't need some inheritance features.

Those datas are just normal lua tables without metatable settings, so, the struct types are just some constructor or validator.



class
====

The core part of an object-oriented system is object. Objects have data fields (property that describe the object) and associated procedures known as method. Objects, which are instances of classes, are used to interact with one another to design applications and computer programs.

Class is the abstract from a group of similar objects. It contains methods, properties (etc.) definitions so objects no need to declare itself, and also contains initialize function to init the object before using them.


Declare a new class
----

Let's use an example to show how to create a new class :

	class "Person"
	endclass "Person"

Like defining a struct, **class** keyword is used to start the definition of the class, it receive a string word as the class's name, and the **endclass** keyword is used to end the definition of the class, also it need the same name as the parameter, **class**, **endclass** and all keywords in the **PLoop system** are fake keywords, they are only functions with some lua environment tricks, so we can't use the **end** to do the job for the best.

Also the class definition codes are running in a private environment just like defining struct types.

Now, we can create an object of the class :

	obj = Person()

Since the **Person** class is an empty class, the **obj** just works as a normal table.


Method
----

Calling an object's method is like sending a message to the object, so the object can do some operations. Take the **Person** class as an example, redefine it :

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

Now, we can used it like :

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

Well, it's better to give the name to a person object when objects are created. When define a global function with the class name, the function will be treated as the constructor function, like the object methods, it use **self** as the first paramter to receive the object, and all other paramters will be passed in.

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

One class can have many constructors with different paramter settings, so the object methods, those features will be introduced in the attribute system.


Class Method
----

Any global functions defined in the class's definition with name start with "_" are class methods, can't be used by the class's objects, as example, we can use a class method to count the persons :

	class "Person"

		_PersonCount = 0

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


Notice a global variable **_PersonCount** is used to count the persons, it's private to the definition environment, so you won't get it in **_G**.


Property
----

Properties are used to access the object's state, like **name**, **age** for a person. Normally, we can do this just using the lua table's field, but that lack the value validation and we can't track how and when the states are changed. So, the property system is bring in like the other oop system.

As an example, we could define a **Name** property for the **Person** class, so the object don't need to use **GetName** and **SetName** to do the job.

To avoid conflict, we use a new namespace for a new **Person** class, when learn the class's re-definition, you'll know why.

	namespace "TestNS"

	-- Keep the previous class away
	Person = nil

	class "Person"
		import "System"

		property "Name" { Type = String }

		property "Age" { Type = Number }

	endclass "Person"

	o = Person()

	-- Output : string	""
	print(type(o.Name), ('%q'):format(o.Name))

	-- Output : 0
	print(o.Age)

	o.Name = "Kurapica"

	-- Output : Kurapica
	print(o.Name)

	-- Output : _Person_Name	Kurapica
	for k, v in pairs(o) do print(k, v) end

	-- Error : Name must be a string, got number.
	o.Name = 123

To define a **property**, line started with **property** keyword, then the property's name, the end is a table contains the definitions.

Normally, a property need a type to declare what value it can contains, for the **Name** property, it can only accept string values, so, in the table, we set `Type = String`, also can be `type = String`, the **Type** key is case ignored, no matter you use `type = String` or 'TYPE = String`. Then, when we run `o.Name = 123`, the value is not a string, it failed.

In the code `print(type(o.Name), ('%q'):format(o.Name))` and `print(o.Age)`, we can see, the **Name** and **Age** has default values, since the **Name** property can only accept string values, the **system**'ll give it a default value - the empty string, for the **Age** property, only number can be accepted, so the default value is 0, and if it only accept boolean values, the default value is false, for any other types, the default is nil.

Also you can set the default value yourself like :

	class "Person"
		import "System"

		property "Name" { Type = String, Default = "Anonymous" }

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

Using **default** key to set the default value for the property, case ignored. The value must can pass the validation of the type setting, or it'll be changed to nil.

And in the code `for k, v in pairs(o) do print(k, v) end`, we can find the real field that store the **Name** property's value is **_Person_Name**. Also, you change it like :

	class "Person"
		import "System"

		property "Name" { Type = String, Default = "Anonymous", Field = "__Name" }

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

	o = Person()

	o.Name = "Kurapica"

	-- Output : __Name	Kurapica
	for k, v in pairs(o) do print(k, v) end

So, using **Field** (case ignored), you can make sure which field is used to store the values. If you don't care, just leave it to the default settings.

The settings above can only make sure the value can be validated(type setting), and existed(default settings), it can't track when the property has been accessed. In the definition table, we can use **Get** / **Set** key to set functions like :

	class "Person"
		import "System"

		property "Name" {
			Set = function(self, name)
				-- the name is validated by the type setting
				-- So here no need to check the name type
				if name ~= self.Name then
					print("Name is changed from " .. self.Name .. " to " .. name)

					-- Don't use self.Name = name, it will cause infinite recycle
					self.__Name = name
				end
			end,

			Type = String,
			Default = "Anonymous",
			Field = "__Name",
		}

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

	o = Person()

	-- Output : Name is changed from Anonymous to Mary
	o.Name = "Mary"

It may be strange that define a **Set** method with the **Field** settings, so, we can give it a **Get** method too.

	class "Person"
		import "System"

		property "Name" {
			Set = function(self, name)
				-- the name must pass the type validation, then send to here
				-- So, I know name is a string
				if name ~= self.Name then
					print("Name is changed from " .. self.Name .. " to " .. name)

					-- Don't use self.Name = name, it will cause infinite recycle
					self.__Name = name
				end
			end,

			Get = function(self)
				return self.__Name
			end,

			Type = String,
			Default = "Anonymous",
		}

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

Some authors may like using **GetName** and **SetName** methods, and if you do, it's very simple to work with the property system, here is an example :

	class "Person"

		function GetName(self)
			return self.__Name
		end

		-- It's setName not SetName, both ok
		function setName(self, name)
			if type(name) == "string" and name ~= self.Name then
				print("Name is changed from " .. self.Name .. " to " .. name)

				self.__Name = name
			end
		end

		property "Name" { Type = String, Default = "Anonymous" }

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

	o = Person()

	-- Output : Name is changed from Anonymous to Kite
	o.Name = "Kite"

So, the **setName** is used as the **Set** method for the **Name** property, and the **GetName** is used as the **Get** method.

If the property has no **Field** settings, and no **Get** method, it'll check **Get** + property's name or **get** + property's name, if the class has such method, it'll be used as the **Get** method, the same thing will be done for the **Set** part.

BTW, the automatically methods scan works a little complex if the property's type is **System.Boolean**, not only **Get** + propert's name and **Set** + property's name should be scanned, **is** / **Is** + property's name also would be scanned for **Get** method. And if the property name is like **noun + adj**, and the **adj** is converted from a **verb**, the **Is + verb + noun** will be scanned for **Get**, and the **verb + noun** will be scanned for the **Set**, for an example : property's name is **FlagDisabled**, it can receive **DisableFlag** as the **Set** method and **IsFlagDisabled** or **IsDisableFlag** will be used as the **Get**, it's a little complex and just for lazy guys, you can just ignore it. An example :

	class "Flag"
		function DisableFlag(self, flag)
			print("The object is " .. (flag and "disabled" or "enabled" ))

			self.__Flag = flag
		end

		function IsFlagDisabled(self)
			return self.__Flag
		end

		property "FlagDisabled" { Type = System.Boolean }
	endclass "Flag"

	o = Flag()

	-- Output : The object is disabled
	o.FlagDisabled = true

You may think those automatically methods scan not steady, so you can set it yourself :

	class "Person"

		function GetName(self)
			return self.__Name
		end

		-- It's setName not SetName, that's ok
		function setName(self, name)
			if type(name) == "string" and name ~= self.Name then
				print("Name is changed from " .. self.Name .. " to " .. name)

				self.__Name = name
			end
		end

		property "Name" { Type = String, Default = "Anonymous", Get = "GetName", Set = "SetName" }

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

You may ask why not using

	class "Person"

		function GetName(self)
			return self.__Name
		end

		-- It's setName not SetName, that's ok
		function setName(self, name)
			if type(name) == "string" and name ~= self.Name then
				print("Name is changed from " .. self.Name .. " to " .. name)

				self.__Name = name
			end
		end

		property "Name" { Type = String, Default = "Anonymous", Get = GetName, Set = SetName }

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

Yes, both works, the first definition would use the object's methods as the accessor, and the second definiton use the **GetName** and **setName** function directly, when using another class that inherited from the **Person** class, and override the **GetName** method, in the second definition, the object can't use the newest **GetName** method for it's **Name** property, that would cause some problem.

At last, let's see how to declare a read-only or wirte-only property.

* Read-only property : No **Field**, no **Set** (include automatically methods scan) or **Set** is false
* Write-only property : No **Field**, no **Get**  (include automatically methods scan) or **Get** is false

Set **Get** or **Set** to false will block the automatically methods scan :

	class "Person"

		function GetName(self)
			return self.__Name
		end

		-- It's setName not SetName, that's ok
		function setName(self, name)
			if type(name) == "string" and name ~= self.Name then
				print("Name is changed from " .. self.Name .. " to " .. name)

				self.__Name = name
			end
		end

		property "Name" { Type = String, Default = "Anonymous", Set = false }

		property "Age" { Type = Number, default = 99 }

	endclass "Person"

	o = Person()

	-- Error : Name can't be written.
	o.Name = "Mike"


Init table
----

When create an object, and set it's properties like

	o = Person()

	o.Name = "Kite"
	o.Age = 23

It's weird, and sometimes, we may keep the informations in some table loaded from files, like

	info = {
		[1] = { Name = "Kite", Age = 23 },
	}

	o = Person()

	o.Name = info[1].Name
	o.Age = info[1].Age

It would be better if we can build an object on the info table. Normally, you can do it by give a constructor to the **Person** class to handle it, but when you have many classes, it's weird to write some similar code many times, you can do it with the init table system.

If the class has no constructor, an init table can be used when creating objects :

	namespace "TestInitTableNS"

	-- Keep the previous class away
	Person = nil

	class "Person"
		property "Name" { Type = System.String }
		property "Age" { Type = System.Number }
	endclass "Person"

	-- Create a person object with init settings
	o = Person { Name = "Kite", Age = 23, Gender = "Female" }

	-- Output : Kite	23	Female
	print(o.Name, o.Age, o.Gender)

	info = {
		[1] = { Name = "Jane", Age = 21 },
	}

	o2 = Person( info[1] )

	-- Output : Jane	21
	print(o2.Name, o2.Age)


Anything in the init table would be passed into the object like :

	for k, v in pairs(init) do
		pcall(function(self, name, value) self[name] = value end, obj, k, v)
	end

 Normally, you can't use init table on a class with constructors, but we'll see how to make it works with the attribtue system in a later chapter.


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
				return self:OnNameChanged(oldName, self.Name)
			end,

			Type = System.String + nil,
		}
	endclass "Person"

	o = Person()

	o.OnNameChanged = function(self, old, new) print("The name is changed from " .. old .. " to " .. new) end

	-- Output : The name is changed from Anonymous to Ann
	o.Name = "Ann"

It looks like we just give the object a **OnNameChanged** method, and call it when needed. The truth is the **self.OnNameChanged** is an object created from **System.EventHandler** class. It's used to control all event handlers (functions), there are two event handler types :

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


It's not good to use the **EventHandler** directly, anytime access the object's **EventHandler**, the object will create the **EventHandler** when not existed. So, fire an event without any handlers will be a greate waste of memory. There are two ways to do it :

* Using **System.Reflector.FireObjectEvent** API, for the previous example :

		self:OnNameChanged(oldName, self.Name)

		-- Change to

		System.Reflector.FireObjectEvent(self, "OnNameChanged", oldName, self.Name)

	Or just add a **Fire** method in your class like :

		class "Person"
			event "OnNameChanged"

			-- Add the API as the object method
			Fire = System.Reflector.FireObjectEvent

			-- Property
			property "Name" {
				Get = function(self)
					return self.__Name or "Anonymous"
				end,

				Set = function(self, name)
					local oldName = self.Name

					self.__Name = name

					-- Fire the event with parameters
					return self:Fire("OnNameChanged", oldName, self.Name)
				end,

				Type = System.String + nil,
			}
		endclass "Person"

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

					if oldName ~= name then
						self.__Name = name

						-- Fire the event with parameters
						return self:Fire("OnNameChanged", oldName, self.Name)
					end
				end,
				Type = System.String + nil,
			}

		endclass "Person"

The inheritance Systems is a powerful feature in the object-oriented program, it makes the class can using the features defined in its super class.

Here, the **System.Object** class is a class that should be other classes's super class, contains many useful method, the **Fire** method is used to fire an event, it won't create the **EventHandler** object when not needed.

BTW. **__Events** field in the object is used to keep the event handlers, so don't use this field for other purpose.


Propety - Event
----

In the previous example, we give a Set method for the **Name** property, compare the old and new value, then set it and fire the event when different, it's a common operation that we may do it on many properties, and that's weird we should write them down many times.

If we only want to know when the property's value is changed, we can just bind an **Event** to the property, so rewrite the previous example :

	class "Person"
		-- Declare the event
		event "OnNameChanged"

		-- Bind the event to the property
		property "Name" { Type = System.String, Default = "Anonymous", Event = "OnNameChanged" }

	endclass "Person"

It's very simple, just using **Event** field point to the event's name. So, let's use it :

	o = Person()

	o.OnNameChanged = function (self, old, new, prop)
		print(("[%s] %s -> %s "):format(prop, old, new))
	end

	-- Ouput : [Name] Anonymous -> Ann
	o.Name = "Ann"

From the result, you can see the parameters of the event, 1st is **old** value, 2nd is **new** value, 3rd is the property's name, so, in some case we can handle all property changes in one event :

	class "Person"
		-- Declare the event
		event "OnPropertyChanged"

		-- Bind the event to the property
		property "Name" { Type = System.String, Default = "Anonymous", Event = "OnPropertyChanged" }
		property "Age" { Type = System.Number, Default = 1, Event = "OnPropertyChanged" }

	endclass "Person"

	o = Person()

	o.OnPropertyChanged = function (self, old, new, prop)
		print(("[%s] %s -> %s "):format(prop, old, new))
	end

	-- Ouput : [Name] Anonymous -> Ann
	o.Name = "Ann"

	-- Ouput : [Age] 1 -> 22
	o.Age = 22

And just remember, if the property has a **Set** method, the event won't be fired.



Meta-method
----

In lua, a table can have many metatable settings, like **__call** use the table as a function, more details can be found in [Lua 5.1 Reference Manual](http://www.lua.org/manual/5.1/manual.html#2.8).

Since the objects are lua tables with special metatables set by the PLoop system, setmetatable can't be used to the objects. But it's easy to provide meta-method for the objects, take the **__call** as an example :

	class "Person"

		-- Property
		property "Name" { Type = System.String, Default = "Anonymous" }

		-- Meta-method
		function __call(self, name)
			print("Hello, " .. name .. ", it's " .. self.Name)
		end

	endclass "Person"

So, just declare a global function with the meta-method's name, and it can be used like :

	obj = Person { Name = "Dean" }

	-- Output : Hello, Sam, it's Dean
	obj("Sam")

All metamethod can be used include the **__index** and **__newindex**. Also a new metamethod used by the PLoop system : **__exist**, the **__exist** method receive all parameters passed to the constructor, and decide if there is an existed object, if true, return the object directly.

	class "UniquePerson"

		_PersonStorage = setmetatable( {}, { __mode = "v" })

		-- Constructor
		function UniquePerson(self, name)
			_PersonStorage[name] = self
		end

		-- __exist
		function __exist(name)
			return _PersonStorage[name]
		end

	endclass "UniquePerson"

So, here is a test :

	print(UniquePerson("A"))

Run the test anytimes, the result will be the same.


Inheritance
----

The inheritance system is the most important system in an oop system. In the PLoop, it make the classes can gain the object methods(not class methods), properties, events, meta-methods and constructor settings from its superclass.

The format is

	inherit ( superclass )

	or

	inherit "superclass path"

The **inherit** keyword can only be used in the class definition. In the previous example, the **Person** class inherit from **System.Object** class, so it can use the **Fire** method. One class can only have one super class.

* In many scene, the class should override its superclass's method, and also want to use the origin method in it. The key features is, in the class definition, a var named **Super** can be used as the superclass, so here is an example :

		class "A"

			function Print(self)
				print("Here is A's Print.")
			end

		endclass "A"

		class "B"
			inherit "A"

			function Print(self)
				-- Call the super class's method
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

	It's all right if you want keep the origin method as a local var like(don't keep it as global, it'll be considered as a new object method) :

		class "B"
			inherit "A"

			local oldPrint = Super.Print

			function Print(self)
				oldPrint( self )

				print("Here is B's Print.")
			end

		endclass "B"

	But when redefine the **A** class, the **oldPrint** would point to an old version **Print** method, it's better to avoid, unless you don't need to redefine any features.

* Like the object methods, override the metamethods is the same, take **__call** as example, **super.__call** can be used to retrieve the superclass's **__call** metamethod.

* If the child class has no constructor, its super class's constructor would be used if existed.If the child has own constructor, the system won't call its super class's constructor, so the child class should call super's constructor itself, the reason will be discussed in the overload system in the later chapter.

		class "A"
			function A(self, ...)
				print ("[A]" .. tostring(self), ...)
			end
		endclass "A"

		class "B"
			inherit "A"

			function B(self, ...)
				-- call Super to init the object with parameters
				Super(self, ...) -- Don't use A(self), it would create a new object of class A, Super ~= A

				print("[B]" .. tostring(self))
			end
		endclass "B"

		obj = B(1, 2, 3)

	Ouput :

		[A]table: 0x7feb88628980	1	2	3
		[B]table: 0x7feb88628980


* Focus on the event handlers, so why need two types, take an example first :

		class "Person"
			event "OnNameChanged"

			property "Name" { Type = System.String, Event = "OnNameChanged" }

			property "GUID" {
				Field = "__GUID", Type = System.String,

				Get = function(self)
					-- Create a guid if not set
					if not self.__GUID then
						math.randomseed(os.time())

						local guid = ""

						for i = 1, 8 do
							guid = guid .. ("%04X"):format(math.random(0xffff))

							if i > 1 and i < 6 then
								guid = guid .. "-"
							end
						end

						self.__GUID = guid
					end

					return self.__GUID
				end,
			}
		endclass "Person"

	Here is a **Person** class's definition, it has two properties, one **Name** used to storage a person's name, a **GUID** used to mark the unique person, so we can diff two person with the same name. When a new person add to the system, we create the object with a new guid like :

		person = Person { Name = "Jane" }

		data = data or {}

		table.insert(data, {
			Name = person.Name,
			GUID = person.GUID,	-- Now new guid is generated when need
		})

	And a new guid is created for the person like 'C2022B9F-ADC2-BBA6-B911-2F670757AD12', then we can save the person's data to somewhere, and when we need we could read the data, and create the person again like :

		person = Person { Name = "Jane", GUID = "C2022B9F-ADC2-BBA6-B911-2F670757AD12" }

	The **Person** class is a simple class used as the root class, we can create many child-class like **Child** and **Adult**, so **Child** should have a **Guardian** property point to another person object, and so on.

	There is an event **OnNameChanged** that fired when the person's name is changed. Now we define a **Member** class inherited from the **Person**, also it will count person based on the name.

		class "Member"
			inherit "Person"

			import "System"

			_NameCount = {}

			-- Class Method
			function _GetMemberCount(name)
				return _NameCount[name] or 0
			end

			-- Event handler
			local function OnNameChanged(self, old, new)
				-- Don't forget the Name property has a default value
				if old and old ~= "" then
					_NameCount[old] = _NameCount[old] - 1
				end

				if new then
					_NameCount[new] = (_NameCount[new] or 0) + 1
				end
			end

			-- Constructor
			-- The first line is an attribute object used to describe the next constructor is a 0-arguments constructor
			-- so the the class can still use the init-table feature(as there is no constructor can receive a table as argument)
			-- The constructor would be called before the init-table is used
			-- More details will be discussed later
			__Arguments__{}
			function Member(self)
				-- binding stackable event handler in class constructor
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




interface
====

In the PLoop system, the interface system is used to support multi-inheritance and other design purposes. One class can only inherited from one super class, but can extend from no-limit interfaces, also an interface can extend from other interfaces.

The definition of an interface is started with **interface** and end with **endinterface** :

	-- Define an interface with one property
	-- Any class extend from this interface should contains an event and a property
	interface "IFName"

		event "OnNameChanged"

		property "Name" { Type = System.String, Event = "OnNameChanged", Default = "Anonymous" }

	endinterface "IFName"

	-- Define an interface has one method and extend from the "IFName"
	-- So, the interface know the object should have a Name property of string type
	interface "IFGreet"
		extend "IFName"

		function Greet(self)
			print("Hi, I'm " .. self.Name)
		end

	endinterface "IFGreet"

Using the interface is like inherit from a class, the format is

	extend ( interface ) ( interface2 ) ( interface3 ) ...

	or

	extend "interface path" "interface2 path" "interface3 path" ...

	-- Define a class extend from the interfaces
	class "Person"
		-- so the Person class have one method and one property from the two interfaces
		-- Since the IFGreet extend IFName, [[extend "IFGreet"]] is enough.
		extend "IFName" "IFGreet"

	endclass "Person"

	obj = Person { Name = "Ann" }

	-- Output : Hi, I'm Ann
	obj:Greet()


Define an interface is just like define a class with little different :

* The interface can't be used to create objects.

* Define events, properties, object methods is the same like the define them in the classes.

* Global method start with "_" are interface methods, can only be called by the interface itself.

* Global method whose name is the interface name, is initializer , will receive object that created from the classes that extend from the interface without any other paramters, the initializer will be called by the system when the object is first created and already inited by the constructors of the class, also after the init-table is applied, so the initializer can be used to manage objects with same behaviors based on the object's settings.

		interface "IFProperty"
			event "OnPropertyChanged"

			local function OnPropertyChanged(self, old, new, prop)
				print( ("[%s] %s -> %s"):format(prop, tostring(old), tostring(new)) )
			end

			function IFProperty(self)
				self.OnPropertyChanged = self.OnPropertyChanged + OnPropertyChanged
			end
		endinterface "IFProperty"

		class "PropertyTest"
			extend "IFProperty"

			property "Value" { Type = System.Number, Event = "OnPropertyChanged"}
		endclass "PropertyTest"

		o = PropertyTest{ Value = 123 }

		-- [Value] 123 -> 456
		o.Value = 456

* No meta-methods can be defined in the interface.

* Normally we only give empty definitions of the features, so the class that extended from the interface must define them, there are two attribute used to describe those rules :

	* `System.__Require__`, used to describe the property or method must be override by the class.

			interface "IFA"
				import "System"

				__Require__() function testA() end
				__Require__() property "testB" {}

			endinterface "IFA"

			class "A"
				extend "IFA"
			endclass "A"

		You could get the error :

			stdin:12: A lack declaration of :
    		IFA - [Method]testA [Property]testB

	* `System.__Optional__`, used to describe the property or method should be override by the class, but not strict, it's no harm to keep it.

	* Properties and methodes without those attribute, is designed to be

The PLoop system don't just bring in much keywords to increase features, using attribute is simple and more extendable, we'll see how to declare custom attributes in some later chapter.


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
			Get = function(self) return _Name[self] end,

			Set = function(self, name) _Name[self] = name end,

			Type = System.String,

			Default = "Anonymous",
		}
	endclass "A"

	obj = A { Name = "Jane" }

	-- Dispose the object
	obj:Dispose()
	obj = nil

If your class or interface won't add any reference to the object, there is no need to declare a **Dispose** method. And remember, the obj.Dispose is not A.Dispose, all objects use a same method, and the method would call the **Dispose** method that defined in the classes and interfaces.

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
	    	-- Don't forget call the super class's constructor
	    	Super(self, name)

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

	* The class's constructor would be called first, then the init-table if existed(Don't show in the example), the last is the interfaces's initializer.

	* The system would try to find the class's constructor, if existed, call it, if not, go to its super class, continue the search. The super class's constructor should be called by the child class's constructor.

	* No other parameter would be passed into the interfaces' initializer, the superclass's interface's initializer would be called first, and if the class has more than one interfaces, first extended will be called first.

* For the dispose :

	* The interface's dispose methods are called first, the order is reversed.

	* The class and its super class's dispose methods can called later, the class's dispose method is called first, then the super class's.

	* There are no parameters for dipose methods.


How to use the interface
----

The oop system is used to describe any real world object into data, using the property to represent the object's state like person's name, birthday, sex, and etc, using the methods to represent what the object can do, like walking, talking and more.

The class is used to descrbie a group of objects with same behaviors. Like **Person** for human beings.

The interface don't represent a group of objects, it don't know what objects will use the features of it, but it know what can be used by the objects.

Take the game as an example, to display the health points of the player, we may display it in text, or something like the health orb in the Diablo, and if using text, we may display it in percent, or some short format like '101.3 k'. So, the text or texture is the objects that used to display the data, and we can use an interface to provide the data like :

	interface "IFHealth"
		import "System"

		_IFHealthObjs = {}

		-- Object method, need override
		__Require__()
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

In the interface, an empty method **SetValue** is defined, it will be override by the classes that extended from the **IFHealth**, so in the **_SetValue** interface method, there is no need to check whether the object has a **SetValue** method.

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



Redefine features
====

For now, we introduced the namespace, enum, struct, class and interface. Let's dig deep to get some more details.

The first thing is about the type's redefinition.

* Only features defined in the same namespace or the same private environment can be redefined, so, if there is a class **System.Widget.Frame**, in your program, you import "System.Widget", and define a new class **Frame**, it won't redefine the **System.Widget.Frame**, but if you declare your program in **System.Widget** namespace, you can redefine it.

* For Enum : redefine enums would clear all settings.

		enum "EnumType" {
			"First",
			"Second",
			"Third",
		}

		-- Output : Third
		print(EnumType.Third)

		enum "EnumType" {
			"First",
			"Second",
		}

		-- Output : Third is not an enumeration value of EnumType.
		print(EnumType.Third)

* For Struct : redefine struct would clear all settings.

		struct "Position"
			x = System.Number
			y = System.Number
			z = System.Number
		endstruct "Position"

		struct "Position"
			x = System.Number
			y = System.Number
		endstruct "Position"

		p = Position(1, 2, 3)

		-- Output : 1	2	nil
		print(p.x, p.y, p.z)

* For Class : redefine class wouldn't clear previous settings. Object would receive new features. If you want add new method to it, just set the new method to the class is okay.

		class "ClsA"
			property "Name" { Type = System.String }
		endclass "ClsA"

		o = ClsA{ Name = "Oliva" }

		-- Redefine the class
		class "ClsA"
			function Hi(self)
				print("Hi, " .. self.Name)
			end
		endclass "ClsA"

		-- Output : Hi, Oliva
		o:Hi()

		-- Give the class a new method
		ClsA.Walk = function(self)
			print(self.Name .. " is walking")
		end

		-- Output : Oliva is walking
		o:Walk()


＊ For Interface : redefine interface wouldn't clear previous settings. Object would receive new features. If you want add new method to it, just set the new method to the interface is okay.

		-- Follow previous example
		interface "IFAge"
			property "Age" { Type = System.Number }
		endinterface "IFAge"

		class "ClsA"
			extend "IFAge"
		endclass "ClsA"

		-- Error : Age must be a number, got string.
		o.Age = "test"

		-- Give a new method to the interface
		IFAge.HowOld = function(self)
			print(self.Name .. " is " .. self.Age .. " older.")
		end

		o.Age = 123

		-- Output : Oliva is 123 older.
		o:HowOld()



Document(Pass just re-designing, a new xml base document system with attribute would be added)
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


* The first line : [__Final__] means the class is a final class, it can't be redefined, it's an attribute description, will be explained later.

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


Here is a full example to show how to make documents for all features in the PLoop system.


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
* The **Reflector** is an interface contains many methods used to get core informations of the PLoop system, like get all method names of one class.
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

The PLoop system is built by manipulate the lua's environment with getfenv / setfenv function. Like

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

Like the definition environment, the PLoop system also provide a **Module** class to create private environment for common using. Unlike the other classes in the **System** namespace, the **Module** class will be saved to the _G at the same time the PLoop system is installed.

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

in .Net. The PLoop system using "__" at the start and end of the attribute class's name, it's not strict, just good for some editor to color it.

The whole attribute system is built on the `System.__Attribute__` class. Here is a list of it :

	[__Final__]
	[__AttributeUsage__{ AttributeTarget = System.AttributeTargets.ALL, Inherited = true, AllowMultiple = false, RunOnce = false }]
	[Class] System.__Attribute__ :

		Description :
			The __Attribute__ class associates predefined system information or user-defined custom information with a target element.


		Method :
			------------ The method could be overrided by the attribute class
			ApplyAttribute　-　Apply the attribute to the target, overridable

			------------ The class method called by the PLoop system, don't use them
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

The first line show the class is a final class, `System.__Final__` is a class inherited from the `System.__Attribute__` and used to mark the class, interface, struct and enum as final, final features can't be redefined. Here is an example, Form now on, using **Module** as the environment :

	Module "A" ""

	import "System"

	__Final__()
	class "A"
	endclass "A"

	-- Error : The class is final, can't be redefined.
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
		Mark the class|interface|struct|enum to be final, and can't be redefined again


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

The above attributes are all used by the core system of the PLoop. But also this is a powerful system for common using.

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
	endstruct "Person"

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

The `__Field__` attribute is used on the field, used to mark the field to a field of a datatable, the **Name** to the field's name, **Index** to the field's display index, and the **Type** to the field's type (not the type of the PLoop).

So, here redefine the **Person** struct :

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

In the **System.Object** class, there is methods like **ActiveThread**, **ThreadCall**, also an attribute **System.__Thread__**, those features are used to bring the coroutine system into the PLoop system.

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













