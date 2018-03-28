# Changelog
All notable changes to this project will be documented in this file.

## [1.0.0] - 2018-03-22 WangXH <kurapica125@outlook.com>
### Changed
- The project is renamed from "Pure Lua Object-Oriented Program System" to "Prototype Lua Object-Oriented Program System".

### Added
- [file]        **Prototype.lua** added, it provide the whole prototype system and build the type validation and object oriented system based on several prototypes, also provide many fundamental features.

- *PLOOP_PLATFORM_SETTINGS* can be created before loading the PLoop, the settings in it will be used to modify the internal behaviors of the PLoop like: multi-os thread system support, type validation disabled and etc.

- [prototype]  **prototype** added, used to generate prototype types.
- [prototype]  **attribute** added, used to apply changes or attach datas to any targets.
- [prototype]  **environment** added, used to provide standalone environments for type definitions and application codes.
- [prototype]  **namespace** added, used to contain and manage types.
- [prototype]  **enum** added, used to generate enumeration data types.
- [prototype]  **struct** added, used to generate structure data types.
- [prototype]  **interface** & **class** added, used to generate object types, full multi-inheritance support(single super class, multi-extend interfaces), methods and static-methods support, meta-methods support and object or static feature support.
- [prototype]  **event** & **property** added, used to generate features that could be used by interface and class.

- [prototype]  **System.Prototype** added, used to get prototype informations
- [prototype]  **System.Attribute** added, used to get attribute informations
- [prototype]  **System.Environment** added, used to get environment informations
- [prototype]  **System.Namespace** added, used to get namespace informations
- [prototype]  **System.Enum** added, used to get enum informations
- [prototype]  **System.Struct** added, used to get struct informations
- [prototype]  **System.Member** added, used to get member informations
- [prototype]  **System.Interface** added, used to get interface informations
- [prototype]  **System.Class** added, used to get class informations
- [prototype]  **System.Event** added, used to get event informations
- [prototype]  **System.Property** added, used to get property informations
- [prototype]  **System.Platform** added, used to get platform settings

- [attribute]  `System.__Abstract__` added, used to set a class, a method or a feature(like event, property) as abstract
- [attribute]  `System.__AnonymousClass__` added, used to make an interface so it should have anonymous class, so the interface can be used to generate objects
- [attribute]  `System.__AutoIndex__` added, used to generate an auto-index enumeration
- [attribute]  `System.__Base__` added, used to set a base struct type to the target struct type
- [attribute]  `System.__Default__` added, used to set the default value of an enum or a custom struct type
- [attribute]  `System.__EventChangeHandler__`a added, used to set the event change handler for an event
- [attribute]  `System.__Final__` added, used to set a class, an interface, a method or a feature as final
- [attribute]  `System.__Flags__` added, used to set the enum as a flags enumeration
- [attribute]  `System.__Get__` added, used to modify the property's get behaviors, like deep clone
- [attribute]  `System.__Indexer__` added, used to set a property as indexer property that would be used as `obj.Items[index] = value`
- [attribute]  `System.__NoNilValue__` added, used to mark a class's objects, so access non-existent value from them is denied
- [attribute]  `System.__NoRawSet__` added, used to mark a class's objects, so set value to their non-existent fields is denied
- [attribute]  `System.__NoSuperObject__` added, used to mark a class or interface, so they don't use super class style like `super[self]:xxx()`
- [attribute]  `System.__ObjFuncAttr__` added, used to mark a class's objects, so functions that be assigned on them will be modified by the attribute system
- [attribute]  `System.__ObjectSource__` added, with it the class ojbect will save the source where it's created
- [attribute]  `System.__Require__` added, used to mark an interface's require class
- [attribute]  `System.__Sealed__` added, used to seal enum, struct, interface and class, so they can't be re-defined
- [attribute]  `System.__Set__` added, used to modify the property's set behaviors
- [attribute]  `System.__SingleVer__` added, used to mark a class as single version class, so old object will receive re-defined class's new features
- [attribute]  `System.__Static__` added, used to mark the method or feature as static, so it only be used by the type itself
- [attribute]  `System.__Super__` added, used to set the target class's super class

- [enum]       **System.AttributeTargets** added, contains the attribute target types
- [enum]       **System.AttributePriority** added, contains the common attribute priorities
- [enum]       **"System.PropertySet** added, contains the property set behaviors
- [enum]       **System.PropertyGet** added, contains the property get behaviors
- [enum]       **System.StructCategory** added, contains the struct category

- [struct]     **System.Any** added, represents any value
- [struct]     **System.Boolean** added, represents boolean value
- [struct]     **System.String** added, represents string value
- [struct]     **System.Number** added, represents number value
- [struct]     **System.Function** added, represents function value
- [struct]     **System.Table** added, represents table value
- [struct]     **System.Userdata** added, represents userdata value
- [struct]     **System.Thread** added, represents thread value
- [struct]     **System.AnyBool** added, represents anybool value
- [struct]     **System.NEString** added, represents nestring value
- [struct]     **System.RawTable** added, represents rawtable value
- [struct]     **System.Integer** added, represents integer value
- [struct]     **System.NaturalNumber** added, represents natural number value
- [struct]     **System.NegativeInteger** added, represents negative interger value
- [struct]     **System.NamespaceType** added, represents namespace type
- [struct]     **System.EnumType** added, represents enum type
- [struct]     **System.StructType** added, represents struct type
- [struct]     **System.InterfaceType** added, represents interface type
- [struct]     **System.ClassType** added, represents class type
- [struct]     **System.AnyType** added, represents any validation type
- [struct]     **System.Lambda** added, represents lambda value
- [struct]     **System.Callable** added, represents callable value, like function, callable objecct, lambda
- [struct]     **System.Variable** added, represents variable value
- [struct]     **System.Variables** added, represents variables value

- [interface]  **System.IAttribtue** added, used as the interface of attributes
- [interface]  **System.IInitAttribute** added, use as the interface to modify the target's definition
- [interface]  **System.IApplyAttribute** added, used as the interface to apply changes on the target
- [interface]  **System.IAttachAttribute** added, used to attach datas to the target
- [interface]  **System.ICloneable** added, used as the interface of the object clone
- [interface]  **System.IEnvironment** added, used as the interface of the code environment
- [interface]  **System.IContext** added, used to share datas within the context, this is designed for multi-os thread platforms

- [attribute]  `System.__Arguments__` added, used to build the overload and validation system for methods or functions
- [attribute]  `System.__Delegate__` added, used to wrap the target function within the given function like pcall
- [attribute]  `System.__Template__` added, make the target struct, interface or class as a template

- [class]      **System.Delegate** added, normally used as event handlers
- [class]      **System.Exception** added, represents errors that occur during application execution
- [class]      **System.Module** added, represents the tree containers for codes, it's the recommended environment for coding with PLoop
- [class]      **System.Context** added, represents the context used as share storages for objects of the **System.IContext**
- [class]      **System.Runtime** added, represents the runtime informations, like add watch for new generated types

- [file]       **System.Date.lua** added, provide types for date management.

- [struct]     **System.TimeFormat** added, represents valid time format strings
- [class]      **System.Date** added, represent the date object

- [file]       **System.Logger.lua** added, provide types for log system:

- [enum]       **System.Logger.LogLevel** added, provide log levels
- [class]      **System.Logger** added, provide the management of loggers

- [file]       **System.Collections.lua** added, provide the interface of collections

- [interface]  **System.Collections.Iterable** added, it's the interface of collections

- [file]       **System.Collections.List.lua** added, provide the collections types for list

- [interface]  **System.Collections.IList** added, represents the list collections that we only care it's elements
- [interface]  **System.Collections.ICountable** added, represents the countable list collections
- [interface]  **System.Collections.IIndexedList** added, represents the indexed list collections who can use obj[idx] to access elements

- [class]      **System.Collections.List** added, it's the basic list collection type
- [class]      **System.Collections.ListStreamWorker** added, it used to provide stream operations for IList objects.

- [file]       **System..Collections.Dictionary.lua** added, provide the collections types for dictionary

- [interface]  **System.Collections.IDictionary** added, represents the key-value pair collection types

- [class]      **System.Collections.Dictionary** added, it's the basic dictionary collection type
- [class]      **System.Collections.DictionaryStreamWorker** added, it used to provide stream operations for IDictionary objects.

- [file]       **System.Collections.IIndexedListSorter.lua** added, used to provide several sort method for IIndexedList objects.

- [file]       **System.Collections.Array.lua** added, it provide the first template class to generate array of objects.

- [class]      **System.Collections.Array** added, you can used it to create object arrays and assign event handlers.

- [file]       **System.Recycle.lua** added, provide type for object recycling

- [class]      **System.Recycle** added, used to generate objects and recycle them

- [file]       **System.Threading.lua** added, provide support for coroutine programming

- [class]      **System.Threading.ThreadPool** added, used to generate recyclable coroutines for thread or iterator
- [class]      **System.Threading.Task** added, represent a task type used to simplify the work of writing asynchronous code
- [attribute]  `System.Threading.__Async__` added, used to wrap a method or function to run it within coroutines fetched from thread pool
- [attribute]  `System.Threading.__Iterator__` added, used to wrap a method or function as iterator which is process within coroutines fetched from thread pool

- [file]       **System.Text.lua** added, provide the interface for encoding

- [class]      **System.Text.Encoding** added, represents the character encoding

- [file]       **System.Text.UTF8Encoding.lua** added, provides the encoding for UTF-8

- [class]      **System.Text.UTF8Encoding** added, represents the UTF-8 encoding

- [file]       **System.Text.UTF16Encoding** added, provides the encoding for UTF-16

- [class]      **System.Text.UTF16EncodingLE** added, represents the utf-16 encoding with little-endian
- [class]      **System.Text.UTF16EncodingBE** added, represents the utf-16 encoding with big-endian.

- [file]       **System.IO.lua** added, provides the basic support for input and ouput

- [class]      **System.IO.TextWriter** added, provides the abstract text writer
- [class]      **System.IO.TextReader** added, provides the abstract text reader

- [file]       **PLoop.System.Serialization.lua** added, provides the types for object serialization & deserialization

- [struct]     **System.Serialization.Serializable** added, represents the serializable objects
- [struct]     **System.Serialization.SerializableType** added, represents the serializable object types

- [interface]  **System.Serialization** provide several APIS to serialize object to data or deserialize data to object
- [interface]  **System.Serialization.ISerializable** added, represents classes that manage the object serialization & deserialization by themselves

- [attribtue]  `System.Serialization.__Serializable__` added, indicates a class or custom struct type is serializable
- [attribute]  `System.Serialization.__NonSerialized__` added, indicates a member in struct or a property in class can't be serialized

- [class]      **System.Serialization.SerializationInfo** added, used by ISerializable classes so they can save or get name-value pairs in it.
- [class]      **System.Serialization.FormatProvider**, provides a format for serialization. Used to serialize the table data to target format or convert the target format data to the table data

- [file]       **System.Serialization.LuaFormatProvider.lua** added, provide format for lua data

- [class]      **System.Serialization.LuaFormatProvider** added, it use the lua table as the serialization format

- [file]       **System.Serialization.StringFormatProvider.lua** added, provide format for string data

- [class]      **System.Serialization.StringFormatProvider** added, it use the string as the serialization format