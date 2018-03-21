# From Pure Lua OOP to Prototype Lua OOP
This is a guide for people who want update codes from the Pure Lua OOP to the new Prototype Lua OOP. The new system's performance and stability are greatly improved, so it's recommended to update to the new Prototype Lua OOP System.

## enum

The old enum types are all case-ignored, there are cost to call the _string.upper_, and also make it can't be used with the _import_. If you have problem with it, and still need case-ignored enumeration, there are two ways :

    * Use the `__CaseIgnored__` attribute on the enum type. Like :

            import "System"

            __CaseIgnored__()
            enum "Test" {
                One = 1,
                Two = 2
            }

            print(Test.one)  -- 1

    * Turn on **ENUM_GLOBAL_IGNORE_CASE** flag in **PLOOP_PLATFORM_SETTINGS** table before loading the PLoop

            PLOOP_PLATFORM_SETTINGS = { ENUM_GLOBAL_IGNORE_CASE = true }

            require "PLoop"

            enum "Test" {
                One = 1,
                Two = 2
            }

            print(Test.one)  -- 1


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
