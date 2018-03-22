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

The function validation is always a complex part, we need to do many checks before the function logic for the arguments and when need to tell the caller the input is bad, the error is not caused by the function, within **PLoop**, it'll be a small problem:

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


