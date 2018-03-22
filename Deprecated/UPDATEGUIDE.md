# From Pure Lua OOP to Prototype Lua OOP
This is a guide for people who want update codes from the Pure Lua OOP to the new Prototype Lua OOP. The new system's performance and stability are greatly improved, so it's recommended to update to the new Prototype Lua OOP System.

## enum

The old enum types are all case-ignored, since there are cost to call the _string.upper_, and also make it can't be used with the _import_, the new PLoop's enumerations are all case sensitive, and only the enumeration value can pass the validation of the enum, you can't use the enumeration name:

        PLoop(function(_ENV)
            enum "Dir" {
                EAST = 1,
                SOUTH = 2,
                WEST = 3,
                NORTH = 4,
            }
            __Arguments__{ Dir }
            function checkdir(dir)
                print(Dir(dir))
            end

            checkdir(Dir.SOUTH) -- SOUTH
            checkdir(NORTH)     -- NORTH, it's also ok, the enumeration name can be used directly where it's imported or created
            checkdir(2)         -- SOUTH
            checkdir("EAST")    -- Error: Usage: checkdir(Dir) - 1st argument must be a value of [Dir]
        end)


## struct

The struct's validation is re-designed to reduce the cost of apis like _pcall_, _assert_. Take _System.Number_ as an example :

This is the definition in old system :

        struct "Number" (function(_ENV)
            function Number(val)
                assert(type(val) == "number", "the %s must be number")
            end
        end)

Here is the definition in new system:

        struct "Number" (function(_ENV)
            function Number(val)
                if type(val) ~= "number" then return "the %s must be number" end
            end
        end)

In the validation, we can remove the call of one _assert_ or _error_, and in the system part, we can remove the usage of _pcall_ that used to call the validation and block the error stop the whole process, so for a simple valiation, we saved two function call.

In the new system, we need the struct validation return an error message if the validation is failed, also you can just return true so the system will auto-generate an error message for you, and it's recommend for basic struct types like :

        struct "Number" (function(_ENV)
            function Number(val)
                return type(val) ~= "number"    --It may looks a little weird in the beginning
            end
        end)

The definition style for memeber struct like

        struct "Pos"
            x = Number
            y = Number
        endstruct "Pos"

is deprecated, the formal style must be

        struct "Pos" (function(_ENV)
            x = Number
            y = Number
        end)

If you really have trouble with it, turn on **TYPE_DEFINITION_WITH_OLD_STYLE** in the **PLOOP_PLATFORM_SETTINGS** like :

        PLOOP_PLATFORM_SETTINGS = { TYPE_DEFINITION_WITH_OLD_STYLE = true }

        require "PLoop"

        struct "Pos"
            x = Number
            y = Number
        endstruct "Pos"

Also the _endclass_, _endinterface_ can't be used unless the option is turn on.

Some struct are renamed, the old name is taken by reflection types :
    * System.Enum       -> System.EnumType
    * System.Struct     -> System.StructType
    * System.Interface  -> System.InterfaceType
    * System.Class      -> System.ClassType
    * System.NameSpace  -> System.NamespaceType


## class

The class are now multi-version types, objects created before the re-definition of the class will still using old definition(also their super methods and features). In many scenarios like the Unity games, the object need using the newest definition, so you can use the `__SingleVer__` attribute on the classes, or just turn on the **CLASS_NO_MULTI_VERSION_CLASS** option in the **PLOOP_PLATFORM_SETTINGS** like :

        PLOOP_PLATFORM_SETTINGS = { CLASS_NO_MULTI_VERSION_CLASS = true }

        require "PLoop"

        class "A" (function(_ENV)
            function Test(self)
                print("old call")
            end
        end)

        o = A()

        class "A" (function(_ENV)
            function Test(self)
                print("new call")
            end
        end)

        o:Test()  -- new call


the `__exist` in the old system only receive all arguments from the object construction, in the new system, it also receive the class as its first argument

the keyword _Super_ and _This_ is changed to _super_, _this_.

## Type changes

OLD                         | New
System.RawBoolean           -> System.Boolean
System.Boolean              -> System.AnyBool
System.NumberNil            -> System.Number
System.Class                -> System.ClassType
System.Interface            -> System.InterfaceType
System.Struct               -> System.StructType
System.Enum                 -> System.EnumType
System.NameSpace            -> System.NamespaceType
System.Guid                 -> [removed]
System.Reflector            -> [removed]
System.__Unique__           -> [removed], easily be done with `__exist`
System.__AttributeUsage__   -> [removed], the attribute system is re-designed
System.Argument             -> System.Variable
System.__AutoCache__        -> [removed], conclict with several design
System.StructType           -> System.StructCategory
System.__InitTable__        -> [removed], easily be done with `__call`
System.__Synthesize__       -> [removed], useless
System.__Event__            -> [removed]
System.__Handler__          -> [removed]
System.__Setter__           -> System.__Set__
System.__Getter__           -> System.__Get__
System.__Doc__              -> [removed]
System.__NameSpace__        -> [removed]
System.__SimpleClass__      -> [removed], easily be done with `__new`
System.__AutoProperty__     -> [removed], get/set/isxxx still can be used
System.__ObjMethodAttr__    -> System.__ObjFuncAttr__
System.__WeakObject__       -> [removed]
System.__NoAutoSet__        -> System.__NoRawSet__


## Reflect

Since the System.Reflector is removed, there are new types to fetch inner datas.

* System.Enum
    * Fetch enumerations:

        for name, value in Enum.GetEnumValues(target) do
            print(name, value)
        end

* System.Struct
    * Fetch array struct element type:

        type = Struct.GetArrayElement(target)

    * Fetch struct members:

        for _, member in Struct.GetMembers(target) do
            print(member:GetName())
            print(member:GetDefault())
            print(member:GetType())
        end

    * Fetch struct methods

        for name, func, isstatic in Struct.GetMethods(target) do
        end

* System.Class | System.Interface
    * Fetch methods

        for name, func, isstaic in Class.GetMethods(target) do
        end

    * Fetch events

        for name, feature in Class.GetFeatures(target) do
            if Event.Validate(feature) then
                print(name)
            end
        end

    * Fetch properties

        for name, feature in Class.GetFeatures(target) do
            if Property.Validate(feature) then
                print(feature:GetType())
            end
        end


## overload changes

The overload system is using System.Variable instead of the System.Argument as variable decalration.

You still can define the System.Argument to avoid changing all your code:

    __Sealed__()
    struct "System.Argument" (function(_ENV)
        Type    = AnyType
        Nilable = Boolean
        Default = Any
        Name    = String
        IsList  = Boolean
    end)


## attributes

The attribute system are greatly re-designed, you need check the new attribute system to know how to re-code them.
