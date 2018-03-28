# Prototype Lua Object-Oriented Program System

**PLoop** is a C# like style object-oriented program system for lua. It support Lua 5.1 and above versions, also include the luajit. It's also designed to be used on multi-os thread platforms like the **OpenResty**.

It also provide common useful classes like thread pool, collection, serialization and etc.

You also can find useful features for large enterprise development like code organization, type validation and etc.


## Install

After install the **Lua**, download the **PLoop** and save it to **LUA_PATH**, or you can use

        package.path = package.path .. ";PATH TO PLOOP PARENT FOLDER/?/init.lua;PATH TO PLOOP PARENT FOLDER/?.lua"

        require "PLoop"

to load the **PLoop**. If you need to load files by yourself, you could check the **PLoop/init.lua** for more details.


## Start with the Collections

The common use of collections is **List** and **Dictionary** classes, here is a sample of **List**:

        require "PLoop"

        PLoop(function(_ENV)

            List(10):Each(print)

        end)

The example will create a list with 1-10 numbers and then print each of them.

The first important things is about the `PLoop(function(_ENV) end)`, you may find many other things like it in **PLoop**, such as the definition of a class :

        class "Person" (function(_ENV)
            property "Name" { type = String }
            property "Age"  { type = Number }
        end)

The **PLoop** using standalone environment for normal code and type definitions to avoid the conflict of the global variable abusing and provide many special techniques like namespace accessing, context keywords(you can only use property keyword in class and interface's definition), decorate for functions, code spell error check and etc.

For now, we only need to know, we can use **PLoop** to call a function whose first argument is `_ENV`, the code in the function will be processed in a private environment, you can access anything in the `_G` without any problem, the only different is when you decalre a global variable, it won't be saved in to the `_G`, and that's why it's designed.

Also we can get more features like types defined in the **global namespaces**, the **List** is defined in **System.Collections** namespace, and it's a global namespace that can be accessed by any **PLoop** environment(you also can use it in without the **PLoop** environment, we'll see in the **namespace** part)

Let's see more about the **List** :

        PLoop(function(_ENV)
            -- 950
            print(List(100):Range(2, -1, 2):Filter("x=>x>50"):Map("x=>x/2"):Reduce("x,y=>x+y"))
        end)

In here, we have **List**'s stream operations, we can use *Range* to specific the start, stop, step, the *Filter* to filter the element data, the *Map* to convert the data, and the final *Reduce* to combine all the datas. There are no temp caches or anonymous functions will be generated during those operations, so the cost is very little.

And we have strings like "x=>x/2", it's a simple version of Lambda expressions, it'll be converted to an anonymous function like `function(x) return x/2 end`. We'll see why those methods can accept Lambda expressions in the **overload and validation** part.


## Attribute and Thread Pool

We have see how to use classes in the previous example, for the second example, I'll show special usage of the **PLoop** environment:

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

        print(iter) -- nil, the PLoop environment is private

Unlike the `_G`, the **PLoop** environments are very sensitive about new variables, when the *iter* is defiend, the system will check if there is any attribtues should be applied on the function, here we have the `__Iterator__()`.

The `__Iterator__` is an attribute class, used to modify or attach datas to the target features like a function.

The `__Iterator__` is used to wrap the target function, so it'll be used as a coroutine iterator who use *coroutine.yield* to return values.

Also you can use *coroutine.wrap* to do the same job, but the different is, the **PLoop** is using thread pools to generate coroutines for those functions and recycle the coroutines when those function have done their jobs:

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

The **Thread Pool** will reduce the cost of the coroutine's creation and also avoid the GC for those coroutines. The attributes like `__Async__` and `__Iterator__` have eliminated the management of coroutines, you only need to focus on the async logics.


## Spell Error Checks And More

Before defined the **PLoop**, we can create a **PLOOP_PLATFORM_SETTINGS** table to toggle the **PLoop**'s system settings:

        PLOOP_PLATFORM_SETTINGS = { ENV_ALLOW_GLOBAL_VAR_BE_NIL = false }

        require "PLoop"

        PLoop(function(_ENV)
            local a = ture  -- Error: The global variable "ture" can't be nil.

            if a then
                print("ok")
            end
        end)

When access not existed global variables(normally spell error), the system will help you location the error place.

The next is about the object field:

        PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST = true, OBJECT_NO_NIL_ACCESS = true }

        require "PLoop"

        PLoop(function(_ENV)
            class "Person" (function(_ENV)
                property "Name" { type = String }
                property "Age"  { type = Number }
            end)

            o = Person()

            o.Name = "King" -- Ok

            o.name = "Ann"  -- Error: The object can't accept field that named "name"

            print(o.name)   -- Error: The object don't have any field that named "name"
        end)

This three settings will help authors to avoid many spell errors during the development.


## Function Argument Validation

The function validation is always a complex part, we need to do many checks before the function's main logic for the arguments so we can tell the caller where and what is failed. Within the **PLoop**, it'll be a small problem:

        PLoop(function(_ENV)
            __Arguments__{ String, Number }
            function SetInfo(name, age)
            end

            -- Error: Usage: SetInfo(System.String, System.Number) - the 2nd argument must be number, got boolean
            SetInfo("Ann", true)
        end)

The arguments's valiation is a repeatable work, so the **PLoop** have provided a full type validation system to simple those works.

If we need to release the project, there is also no need to remove those `__Arguments__`, you can change a settings for the **PLoop**:

        PLOOP_PLATFORM_SETTINGS = { TYPE_VALIDATION_DISABLED = true }

        require "PLoop"

        PLoop(function(_ENV)
            __Arguments__{ String, Number }
            function SetInfo(name, age)
            end

            -- No error now
            SetInfo("Ann", true)
        end)

If the arguments's type are immutable, the `__Arguments__` won't wrap the target function, so there is no need to remove those attribute declarations for speed.

The achieve such a validation system, we need more types to describe the datas. In **PLoop**, there are four types: enum, struct, interface and class.


## enum

the enumeration is a data type consisting of a set of named values called elements, The enumerator names are usually identifiers that behave as constants.

To define an enum within the PLoop, the syntax is

        enum "Name" { -- key-value pairs }

In the table, for each key-value pair, if the key is string, the key would be used as the element's name and the value is the element's value. If the key is a number and the value is string, the value would be used as both the element's name and value, othwise the key-value pair will be ignored.

Use enumeration[elementname] to fetch the enum element's value, also can use enumeration(value) to fetch the element name from value.

Also can use the element name directly where the enum is defined or imported.

Here is an example :

        PLoop(function(_ENV)
            enum "Direction" { North = 1, East = 2, South = 3, West = 4 }

            print(Direction.South) -- 3
            print(Direction.NoDir) -- nil
            print(Direction(3))    -- South

            print(East)            -- 2
        end)

Since the element value is indexed, we also can define it like

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

The `__AutoIndex__` attribute will give each element an auto-increase index based on the config tables.

Another special enum is the flags enumeration type, the element value should be 2^n, so the element value can be used together :

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

All enum types are immutable, that means the value won't change through the enum validation.


## struct

The structures are types for basic and complex organized datas and also the data contracts for value validation. There are three struct types:

i. **Custom**  The basic data types like number, string and more advanced types like nature number. Take the *Number* as an example:

        PLoop(function(_ENV)
            struct "Number" (function(_ENV)
                function Number(value)
                    return type(value) ~= "number" and "the %s must be number, got " .. type(value)
                end
            end)

            v = Number(true)  -- Error : the value must be number, got boolean
        end)

Unlike the enumeration, the structure's definition is a little complex, the definition body is a function with _ENV as its first parameter, the pattern is designed to make sure the **PLoop** works with Lua 5.1 and all above versions. The code in the body function will be processed in a private context used to define the struct.

The function with the struct's name is the validator, also you can use `__valid` instead of the struct's name(there are anonymous structs). The validator would be called with the target value, if the return value is non-false, that means the target value can't pass the validation, normally the return value should be an error message, the `%s` in the message'll be replaced by words based on where it's used, if the return value is true, the system would generte the error message for it.

If the struct has only the validator, it's an immutable struct that won't modify the validated value. We also need mutable struct like AnyBool :

        struct "AnyBool" (function(_ENV)
            function __init(value)
                return value and true or fale
            end
        end)

        print(AnyBool(1))  -- true

The function named `__init` is the initializer, it's used to modify the target value, if the return value is non-nil, it'll be used as the new value.

The struct can have one base struct so it will inherit the base struct's validator and initializer, the base struct's validator and initializer should be called before the struct's own:

        struct "Integer" (function(_ENV)
            __base = Number

            local floor = math.floor

            function Integer(value)
                return floor(value) ~= value and "the %s must be integer"
            end
        end)

        v = Integer(true)  -- Error : the value must be number, got boolean
        v = Integer(1.23)  -- Error : the value must be integer

There system have provide many fundamental custom struct types like :

* **System.Any**                represents any value
* **System.Boolean**            represents boolean value
* **System.String**             represents string value
* **System.Number**             represents number value
* **System.Function**           represents function value
* **System.Table**              represents table value
* **System.Userdata**           represents userdata value
* **System.Thread**             represents thread value
* **System.AnyBool**            represents anybool value
* **System.NEString**           represents nestring value
* **System.RawTable**           represents rawtable value
* **System.Integer**            represents integer value
* **System.NaturalNumber**      represents natural number value
* **System.NegativeInteger**    represents negative interger value
* **System.NamespaceType**      represents namespace type
* **System.EnumType**           represents enum type
* **System.StructType**         represents struct type
* **System.InterfaceType**      represents interface type
* **System.ClassType**          represents class type
* **System.AnyType**            represents any validation type
* **System.Lambda**             represents lambda value
* **System.Callable**           represents callable value, like function, callable objecct, lambda
* **System.Variable**           represents variable
* **System.Variables**          represents variables


ii. **Member**  The member structure represent tables with fixed fields of certain types. Take an example to start:

        struct "Location" (function(_ENV)
            x = Number
            y = Number
        end)

        loc = Location{ x = "x" }    -- Error: Usage: Location(x, y) - x must be number
        loc = Location(100, 20)
        print(loc.x, loc.y)          -- 100  20

The member sturt can also be used as value constructor(and only the member struct can be used as constructor), the argument order is the same order as the declaration of it members.

The `x = Number` is the simplest way to declare a member to the struct, but there are other details to be filled in, here is the formal version:

        struct "Location" (function(_ENV)
            member "x" { type = Number, require = true }
            member "y" { type = Number, default = 0    }
        end)

        loc = Location{}            -- Error: Usage: Location(x, y) - x can't be nil
        loc = Location(100)
        print(loc.x, loc.y)         -- 100  0

The member is a keyword can only be used in the definition body of a struct, it need a member name and a table contains several settings(the field is case ignored) for the member:

* type      - The member's type, it could be any enum, struct, class or interface, also could be 3rd party types that follow rules.
* require   - Whether the member can't be nil.
* default   - The default value of the member.

The member struct also support the validator and initializer :

        struct "MinMax" (function(_ENV)
            member "min" { Type = Number, Require = true }
            member "max" { Type = Number, Require = true }

            function MinMax(val)
                return val.min > val.max and "%s.min can't be greater than %s.max"
            end
        end)

        v = MinMax(100, 20) -- Error: Usage: MinMax(min, max) - min can't be greater than max

Since the member struct's value are tables, we also can define struct methods that would be saved to those values:

        struct "Location" (function(_ENV)
            member "x" { Type = Number, Require = true }
            member "y" { Type = Number, Default = 0    }

            function GetRange(val)
                return math.sqrt(val.x^2 + val.y^2)
            end
        end)

        print(Location(3, 4):GetRange()) -- 5

We can also declare static methods that can only be used by the struct itself(also for the custom struct):

        struct "Location" (function(_ENV)
            member "x" { Type = Number, Require = true }
            member "y" { Type = Number, Default = 0    }

            __Static__()
            function GetRange(val)
                return math.sqrt(val.x^2 + val.y^2)
            end
        end)

        print(Location.GetRange{x = 3, y = 4}) -- 5

The `__Static__` is an attribute, it's used here to declare the next defined method is a static one.

In the example, we declare the default value of the member in the member's definition, but we also can provide the default value in the custom struct like :

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

The member struct can also have base struct, it will inherit members, non-static methods, validator and initializer, but it's not recommended.

iii. **Array**  The array structure represent tables that contains a list of same type items. Here is an example to declare an array:

        struct "Locations" (function(_ENV)
            __array = Location
        end)

        v = Locations{ {x = true} } -- Usage: Locations(...) - the [1].x must be number

The array structure also support methods, static methods, base struct, validator and initializer.


To simplify the definition of the struct, table can be used instead of the function as the definition body.

        -- Custom struct
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

Let's return the first struct **Number**, the error message is generated during runtime, and in **PLoop** there are many scenarios we only care whether the value match the struct type, so we only need validation, not the error message(the overload system use this technique to choose function).

The validator can receive 2nd parameter which indicated whether the system only care if the value is valid, so we can avoid the generate of new strings when we only need valida it.

        struct "Number" (function(_ENV)
            function Number(value, onlyvalid)
                if type(value) ~= "number" then return onlyvalid or "the %s must be number, got " .. type(value) end
            end
        end)

        -- The API to validate value with types (type, value, onlyvald)
        print(struct.ValidateValue(Number, "test", true))   -- nil, true
        print(struct.ValidateValue(Number, "test", false))  -- nil, the %s must be number, got string


If your value could be two or more types, you can combine those types like :

        -- nil, the %s must be value of System.Number | System.String
        print(Struct.ValidateValue(Number + String, {}, false))

You can combine types like enums, structs, interfaces and classes.

If you need the value to be a struct who is a sub type of another struct, (a struct type is a sub type of itself), you can create it like `- Number` :

        struct "Integer" { __base = Number, function(val) return math.floor(val) ~= val end }
        print(Struct.ValidateValue( - Number, Integer, false))  -- Integer

You also can use the `-` operation on interface or class.


## Classes

The classes are types that abstracted from a group of similar objects. The objects generated by the classes are tables with fixed meta-tables.

A class can be defined within several parts:

i. **Method**   The methods are functions that be used by the classes and their objects. Take an example :

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

Like the struct, the definition body of the class _Person_ also should be a function with `_ENV` as its first parameter. In the definition, the global delcared functions will be registered as the class's method. Those functions should use _self_ as the first parameter to receive the objects.

When the definition is done, the class object's meta-table is auto-generated based on the class's definition layout. For the _Person_ class, it should be

        {
            __index = { SetName = function, GetName = function },
            __metatable = Person,
        }

The class can access the object method directly, and also could have their own method - static method:

        class "Color" (function(_ENV)
            __Static__()
            function FromRGB(r, g, b)
                -- The object construct will be talked later
                return Color {r = r, g = g, b = b}
            end
        end)

        c = Color.FromRGB(1, 0, 1)
        print(c.r, c.g, c.b)

The static method don't use _self_ as the first parameter since it's used by the class itself not its objects.

ii. **Meta-data**    The meta-data is a superset of the Lua's meta-method:

    *  `__add`        the addition operation:             a + b  -- a is the object, also for the below operations
    *  `__sub`        the subtraction operation:          a - b
    *  `__mul`        the multiplication operation:       a * b
    *  `__div`        the division operation:             a / b
    *  `__mod`        the modulo operation:               a % b
    *  `__pow`        the exponentiation operation:       a ^ b
    *  `__unm`        the negation operation:             - a
    *  `__idiv`       the floor division operation:       a // b
    *  `__band`       the bitwise AND operation:          a & b
    *  `__bor`        the bitwise OR operation:           a | b
    *  `__bxor`       the bitwise exclusive OR operation: a~b
    *  `__bnot`       the bitwise NOToperation:           ~a
    *  `__shl`        the bitwise left shift operation:   a<<b
    *  `__shr`        the bitwise right shift operation:  a>>b
    *  `__concat`     the concatenation operation:        a..b
    *  `__len`        the length operation:               #a
    *  `__eq`         the equal operation:                a == b
    *  `__lt`         the less than operation:            a < b
    *  `__le`         the less equal operation:           a <= b
    *  `__index`      The indexing access:                return a[k]
    *  `__newindex`   The indexing assignment:            a[k] = v
    *  `__call`       The call operation:                 a(...)
    *  `__gc`         the garbage-collection
    *  `__tostring`   the convert to string operation:    tostring(a)
    *  `__ipairs`     the ipairs iterator:                ipairs(a)
    *  `__pairs`      the pairs iterator:                 pairs(a)
    *  `__exist`      the object existence checker
    *  `__field`      the init object fields, must be a table
    *  `__new`        the function used to generate the table that'd be converted to an object
    *  `__ctor`       the object constructor
    *  `__dtor`       the object destructor

 There are several PLoop special meta-data, here are examples :

        class "Person" (function(_ENV)
            __ExistPerson = {}

            -- The Constructor
            function __ctor(self, name)
                print("Call the Person's constructor with " .. name)
                __ExistPerson[name] = self
                self.name = name
            end

            -- The existence checker
            function __exist(cls, name)
                if __ExistPerson[name] then
                    print("An object existed with " .. name)
                    return __ExistPerson[name]
                end
            end

            -- The destructor
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
        print(o == Person("Ann")) -- Call the Person's constructor with Ann

Here is the constructor, the destructor and an existence checker. We also can find a non-declared method **Dispose**, all objects that generated by classes who have destructor settings will have the **Dispose** method, used to call it's class, super class and the class's extended interface's destructor with order to destruct the object, normally the destructor is used to release the reference of the object, so the Lua can collect them.

The constructor receive the object and all the parameters, the existence checker receive the class and all the parameters, and if it return a non-false value, the value will be used as the object and return it directly. The destructor only receive the object.

The `__new` meta is used to generate table that will be used as the object. You can use it to return tables generated by other systems or you can return a well inited table so the object's construction speed will be greatly increased like :

        class "List" (function(_ENV)
            function __new(cls, ...)
                return { ... }, true
            end
        end)

        v = List(1, 2, 3, 4, 5, 6)

The `__new` would recieve the class and all parameters and return a table and a boolean value, if the value is true, all parameters will be discarded so won't pass to the constructor. So for the List class, the `__new` meta will eliminate the rehash cost of the object's initialization.

The `__field` meta is a table, contains several key-value paris to be saved in the object, normally it's used with the **OBJECT_NO_RAWSEST** and the **OBJECT_NO_NIL_ACCESS** options, so authors can only use existing fields to to the jobs, and spell errors can be easily spotted.

        PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST   = true, OBJECT_NO_NIL_ACCESS= true, }

        require "PLoop"

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

For the constructor and destructor, there are other formal names: the class name will be used as constructor, and the **Dispose** will be used as the destructor:

        class "Person" (function(_ENV)
            -- The Constructor
            function Person(self, name)
                self.name = name
            end

            -- The destructor
            function Dispose(self)
            end
        end)


iii. **Super class** the class can and only can have one super class, the class will inherit the super class's object method, meta-datas and other features(event, property and etc). If the class has override the super's object method, meta-data or other features, the class can use **super** keyword to access the super class's method, meta-data or feature.

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

From the example, here are some details:

* The destructor don't need call super's destructor, they are well controlled by the system, so the class only need to consider itself.

* The constructor need call super's constructor manually, we'll learned more about it within the overload system.

* For the object method and meta-method, we have two style to call its super, `super.Test(self)` is a simple version, but if the class has multi versions, we must keep using the `super[self]:Test()` code style, because the super can know the object's class version before it fetch the *Test* method. We'll see more about the super call style in the event and property system.


## Interface

The interfaces are abstract types of functionality, it also provided the multi-inheritance mechanism to the class. Like the class, it also support object method, static method and meta-datas.

The class and interface can extend many other interfaces, the **super** keyword also can access the extended interface's object-method and the meta-methods.

The interface use `__init` instead of the `__ctor` as the interface's initializer. The initializer only receive the object as it's parameter, and don't like the constructor, the initializer can't be accessed by **super** keyword. The method defined with the interface's name will also be used as the initializer.

If you only want defined methods and features that should be implemented by child interface or class, you can use `__Abstract__` on the method or the feature, those abstract methods and featuers can't be accessed by **super** keyword.

Let's take an example :

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

From the example, we can see the initializers are called when object is created and already passed the class's constructor. The dispose order is the reverse order of the object creation. So, the class and interface should only care themselves.


## Event

The events are used to notify the outside that the state of class object has changed. Let's take an example to start :

        class "Person" (function(_ENV)
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

The event is a feature type of the class and interface, there are two types of the event handler :

* the final handler     - the previous example has shown how to bind the final handler.

* the stackable handler - The stackable handler are normally used in the class's constructor or interface's initializer:

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

The `self.OnNameChanged` is an object generated by **System.Delegate** who has `__add` and `__sub` meta-methods so it can works with the style like

            self.OnNameChanged = self.OnNameChanged + onNameChanged
or

            self.OnNameChanged = self.OnNameChanged - onNameChanged

The stackable handlers are added with orders, so the super class's handler'd be called at first then the class's, then the interface's. The final handler will be called at the last, if any handler `return true`, the call process will be ended.

In some scenarios, we need to block the object's event, the **Delegate** can set an init function that'd be called before all other handlers, we can use

        self.OnNameChanged:SetInitFunction(function() return true end)

To block the object's *OnNameChanged* event.

When using PLoop to wrap objects generated from other system, we may need to bind the PLoop event to other system's event, there is two parts in it :

* When the PLoop object's event handlers are changed, we need know when and whether there is any handler for that event, so we can register or un-register in the other system.

* When the event of the other system is triggered, we need invoke the PLoop's event.

Take the *Frame* widget from the *World of Warcraft* as an example, ignore the other details, let's focus on the event two-way binding :

        class "Frame" (function(_ENV)
            __EventChangeHandler__(function(delegate, owner, eventname)
                -- owner is the frame object
                -- eventname is the OnEnter for this case
                if delegate:IsEmpty() then
                    -- No event handler, so un-register the frame's script event
                    owner:SetScript(eventname, nil)
                else
                    -- Has event handler, so we must regiser the frame's script event
                    if owner:GetScript(eventname) == nil then
                        owner:SetScript(eventname, function(self, ...)
                            -- Call the delegate directly
                            delegate(self, ...)
                        end)
                    end
                end
            end)
            event "OnEnter"
        end)

With the `__EventChangeHandler__` attribute, we can bind a function to the target event, so all changes of the event handlers can be checked in the function. Since the event change handler has nothing special with the target event, we can use it on all script events in one system like :

        -- A help class so it can be saved in namespaces
        class "__WidgetEvent__" (function(_ENV)
            local function handler (delegate, owner, eventname)
                if delegate:IsEmpty() then
                    owner:SetScript(eventname, nil)
                else
                    if owner:GetScript(eventname) == nil then
                        owner:SetScript(eventname, function(self, ...)
                            -- Call the delegate directly
                            delegate(self, ...)
                        end)
                    end
                end
            end

            function __WidgetEvent__(self)
                __EventChangeHandler__(handler)
            end
        end)

        class "Frame" (function(_ENV)
            __WidgetEvent__()
            event "OnEnter"

            __WidgetEvent__()
            event "OnLeave"
        end)

The event can also be marked as static, so it can be used and only be used by the class or interface :

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

When the class or interface has overridden the event, and they need register handler to super event, we can use the super object access style :

        class "Person" (function(_ENV)
            property "Name" { event = "OnNameChanged" }
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
        o.Name = "Test"


## Property

The properties are object states, we can use the table fields to act as the object states, but they lack the value validation, and we also can't track the modification of those fields.

Like the event, the property is also a feature type of the interface and class. The property system provide many mechanisms like get/set, value type validation, value changed handler, value changed event, default value and default value factory. Let's start with a simple example :

        class "Person" (function(_ENV)
            property "Name" { type = String }
            property "Age"  { type = Number }
        end)

        -- If the class has no constructor, we can use the class to create the object based on a table
        -- the table is called the init-table
        o = Person{ Name = "Ann", Age = 10 }

        print(o.Name)-- Ann
        o.Name = 123 -- Error : the Name must be [String]

The **Person** class has two properties: *Name* and *Age*, the table after `property "Name"` is the definition of the *Name* property, it contains a *type* field that contains the property value's type, so when we assign a number value to the *Name*, the operation is failed.

Like the **member** of the **struct**, we use table to give the property's definition, the key is case ignored, here is a full list:

* auto          whether use the auto-binding mechanism for the property see blow example for details.

* get           the function used to get the property value from the object like `get(obj)`, also you can set **false** to it, so the property can't be read

* set           the function used to set the property value of the object like `set(obj, value)`, also you can set **false** to it, so the property can't be written

* getmethod     the string name used to specified the object method to get the value like `obj[getmethod](obj)`

* setmethod     the string name used to specified the object method to set the value like `obj[setmethod](obj, value)`

* field         the table field to save the property value, no use if get/set specified, like the *Name* of the **Person**, since there is no get/set or field specified, the system will auto generate a field for it, it's recommended.

* type          the value's type, if the value is immutable, the type validation can be turn off for release version, just turn on **TYPE_VALIDATION_DISABLED** in the **PLOOP_PLATFORM_SETTINGS**

* default       the default value

* event         the event used to handle the property value changes, if it's value is string, an event will be created:

        class "Person" (function(_ENV)
            property "Name" { type = String, event = "OnNameChanged" }
        end)

        o = Person { Name = "Ann" }

        function o:OnNameChanged(new, old, prop)
            print(("[%s] %s -> %s"):format(prop, old, new))
        end

        -- [Name] Ann -> Ammy
        o.Name = "Ammy"

* handler       the function used to handle the property value changes, unlike the event, the handler is used to notify the class or interface itself, normally this is used combine with **field** (or auto-gen field), so the class or interface only need to act based on the value changes :

        class "Person" (function(_ENV)
            property "Name" {
                type = String, default = "anonymous",
                handler = function(self, new, old, prop) print(("[%s] %s -> %s"):format(prop, old, new)) end
            }
        end)

        --[Name] anonymous -> Ann
        o = Person { Name = "Ann" }

        --[Name] Ann -> Ammy
        o.Name = "Ammy"

* static        true if the property is a static property

If the **auto** auto-binding mechanism is using and the definition don't provide get/set, getmethod/setmethod and field, the system will check the property owner's method(object method if non-static, static method if it is static), if the property name is **name**:

* The *setname*, *Setname*, *SetName*, *setName* will be scanned, if it existed, the method will be used as the **set** setting

        class "Person" (function(_ENV)
            function SetName(self, name)
                print("SetName", name)
            end

            property "Name" { type = String }
        end)

        -- SetName  Ann
        o = Person { Name = "Ann"}

        -- SetName  Ammy
        o.Name = "Ammy"

* The *getname*, *Getname*, *Isname*, *isname*, *getName*, *GetName*, *IsName*, *isname* will be scanned, if it exsited, the method will be used as the **get** setting

When the class or interface has overridden the property, they still can use the super object access style to use the super's property :

        class "Person" (function(_ENV)
            property "Name" { event = "OnNameChanged" }
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

You also can build indexer properties like :

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

The indexer property can only accept set, get, getmethod, setmethod, type and static definitions.


## Overload

We have see examples about the function argument validation, the real usage of the `__Arguments__` is for the overload methods.

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

With the `__Arguments__`, we can bind several functions as one class(interface|struct) method, constructor or meta-method.

        class "Person" (function(_ENV)
            __Arguments__{ String }
            function Person(self, name)
                self.name = name
            end

            __Arguments__{ NaturalNumber }
            function Person(self, age)
                self.age = age
            end

            __Arguments__{ String, NaturalNumber }
            function Person(self, name, age)
                this(self, name)
                this(self, age)
            end
        end)

        o = Person("Ann", 24)

        print(o.name, o.age)  -- Ann    24

For the constructor, we can use **this** keyword to call the constructor with other arguments. If a child class has overridden the parent's method or constructor, it can use **super** keyword to do the job :

        class "Student" (function(_ENV)
            inherit "Person"

            __Arguments__{ String, NaturalNumber, Number }
            function Student(self, name, age, score)
                this(self, name, age)
                self.score = score
            end

            __Arguments__.Rest()  -- this means catch all other arguments, leave it to super class
            function Student(self, ...)
                super(self, ...)
            end
        end)

The previous examples only show require arguments, to describe optional and varargs we need know more about the `__Arguments__`, the `__Arguments__` only accpet one argument, it's type is **System.Variables**, which is a array struct, its element is **System.Variable**, a simple version of the struct is :

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

So, we can create optional variable like

        Variable.Optional(Number, 0)

And create a varargs like

        Variable.Rest(Number)


## Throw Exception

There are more checks than the argument check, if we need notify the outside something goes wrong, normally we should use the **error** API, but the stack level is a problem, especially for the constructor and the overload system, so we need a new **Exception** system for them, the **PLoop** provide a keyword named **throw**, it'd convert the error message to an Exception object which can be catch by the pcall.

        class "A" (function(_ENV)
            local function check(self)
                throw("something wrong")
            end

            function A(self)
                check(self)
            end
        end)

        o = A() -- something wrong

The object creation is controlled by the system, so the system can covert the Exception object to error message and throw the error at the right place.

        PLoop(function(_ENV)
            __Arguments__{ String }:Throwable()
            function test(name)
                throw("we have throwable exception here")
            end

            test("HI") -- we have throwable exception here
        end)

If we need use the throw in some functions or mehods(not constructor), we should use the `__Arguments__` and mark it as *Throwable*.


## Template class

We may create several classes with the same behaviors but for different types, since we use the function as the class's definition body, it's very simple to use them as template classes.

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

In the example, we use `__Template__` attribute to declare the **Array** class is a template class, the default type is **System.Any**, that means the real type can be any structs, interfaces or classes.

The **Array**'s definition function has one more argument, it's where the real type is passed in.

After the **Array** class is created, we can use **Array[Integer]** to pass in the real type and generate a class to do the jobs.

You also can create multi-types template, just like :

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

You also can create template interface and template struct.


## Namespace And Environment

In the **PLoop** environment, we can easily use types like **Number**, **String** and other attribute types, but within the `_G`, we need use keyword **import** to import the **System** namespace, then we can use them:

        require "PLoop"

        import "System"

        print(Number) -- System.Number

The namespaces are used to organize feature types. Same name features can be saved in different namespaces so there won't be any conflict.

The environment(include the `_G`) can have a root namespace so all features defined in it will be saved to the root namespace.

        PLoop(function(_ENV)
            namespace "MyNs"

            class "A" {}

            print(A) -- MyNs.A
        end)

Also it can import several other namespaces, features that defined in them can be used in the environment directly.

        PLoop(function(_ENV)
            print(A) -- nil

            import "MyNs"

            print(A) -- MyNs.A
        end)

The namespace's path is from the root namespace to the sub namepsace, and to the final type. You can also specific the full namespace when define types:

        PLoop(function(_ENV)
            namespace "MyNs"

            class "System.TestNS.A" {}

            print(A) -- System.TestNS.A
        end)

So, it won't use the environment's namespace as root.


## Module

Using `PLoop(function(_ENV) end)` is a little weird, it's normally used by libraries. The recommend way is using **System.Module**, each file are considered as one module:

        require "PLoop"

        _ENV = Module "TestMDL" "1.0.0"

        __Async__()
        function dotask()
            print(coroutine.running())
        end

`Module "TestMDL"` is short for `Module("TestMDL")`, so it created a Module object, call the object with a version number (also can be empty string) will change the current environment to the object itself, combine with the `_Env =` will make sure the code can run in Lua 5.1 and above version.

After that, we can enjoy the power of the **PLoop**.

A module object can have many child-modules :

        _ENV = Module "TestMDL.SubMDL" "1.0.0"

        dotask() -- ok

The child module can access its parent module's global variables, the root module can access the `_G`'s global variables.

When the module have access any variable contains in its parent or `_G`, the module will save the variable in itself.

The child module'll share its parent module's namespace unless it use **namespace** keyword to change it.


## Attribute System

We have seen many attributes, they are used to modify the target's behaviors.

If you only need to decorate some functions, you can simply use the `__Delegate__` attribute on functions like :

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

i.  modify the target's definitions, normally used on functions or enums:

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

the attribute class should extend the **System.IInitAttribute** and define the **InitDefinition** method to modify the target's definitions, for a function, the definition is the function itself, if the method return a new definition, the new will be used. And for the enum, the definition is the table that contains the elements. The init attribtues are called before the define process of the target.

ii. Apply changes on the target, normally this is only used by the system attributes, take the `__Sealed__` as an example:

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

the attribute should extend the **System.IApplyAttribute** and define the **ApplyAttribute** method. The apply attribtues are applied during the define process of the target.

iii. Attach attribtue datas on the target, also can be used to register the final result to other systems.

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

the attribute should extend the **System.IAttachAttribute** and defined the **AttachAttribute** method, the return value of the method will be saved, so we can check it later.