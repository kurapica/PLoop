# Changelog
All notable changes to this project will be documented in this file.

##[1.6.7] - 2020-05-28 WangXH <kurapica125@outlook.com>
### Changed
- Fix the serialization for the combo struct types.


##[1.6.6] - 2020-05-22 WangXH <kurapica125@outlook.com>
### Changed
- Fix the missing of headers and accept of the http inner request class.
- Add more interfaces for cache system.


##[1.6.5] - 2020-05-12 WangXH <kurapica125@outlook.com>
### Changed
- Fix the Serialization system can't recognize the combo struct types.


##[1.6.4] - 2020-05-12 WangXH <kurapica125@outlook.com>
### Changed
- The with keyword will return the values generated from the error hadnler, the operation won't be processed when open method failed.


##[1.6.3] - 2020-05-03 WangXH <kurapica125@outlook.com>
### Changed
- The delegate change handler binding won't consume the attributes.


##[1.6.2] - 2020-03-24 WangXH <kurapica125@outlook.com>
### Changed
- The auto incr data table field don't need to be primary, it's fixed.


##[1.6.1] - 2020-03-20 WangXH <kurapica125@outlook.com>
### Changed
- Fix the problem when provide the return value in an iterator, the next iterator share the same coroutine will trigger error.
- Remove the ServerRedirect from the HttpResponse, since it may be used to terminate the process like in the Openresty, it's done within the framework, so no code should be modified in the projects.


##[1.5.4] - 2020-02-26 WangXH <kurapica125@outlook.com>
### Changed
- The `Environment.Apply(func, ...)` can provide arguments for the target function
- Improve the method validation error message for the data base and data cache system


##[1.5.3] - 2020-02-19 WangXH <kurapica125@outlook.com>
### Changed
- The List and Dictionary can chain same queue method like `List(10):Map("x=>x^2"):Map("x=>x+1"):Each(print)`


##[1.5.2] - 2019-12-27 WangXH <kurapica125@outlook.com>
### Changed
- If use the `System.__Recycable__` mark the classes, the class can collect disposed objects in the `__dtor` method, can re use them by the `__new` method, since they all disposed, they should be used as new object and passed to the `__ctor` method.


##[1.5.1] - 2019-12-17 WangXH <kurapica125@outlook.com>
### Added
- `USE_THIS_FOR_OBJECT_METHODS` platform setting is added, used to make sure the overload object method can use `this(self, ...)` to call the other implementions of the same method, default false(normall you can call the target method directly like `Method(self, ...)`)
- The `UseThis` method is added to the `__Arguments__` attribtue, so we can use `this` keyword in object method like `__Arguments__{...}:UseThis()`
- `System.Collections.Queue` is added
- Now can use `interface (target) (function(_ENV) ... end)` or `class (target) (function(_ENV) ... end)` to define object or static methods for sealed types, can only be used to define un-existed methods, no keywords can be used.
- System.Reactive lib is added.

### Changed
- Fix the class method extension, object method with the same name of the static method should works now.


## [1.4.6] - 2019-12-02 WangXH <kurapica125@outlook.com>
### Added
- `ToXList` method is added to the `System.Collections.IList`, so we can save the link operations to the XList object and start the new link operations.
- `ToXDict` method is added to the `System.Collections.IDictionary`, so we can save the link operations to the XDictionary and start the new link operations.
- `SafeThreadCall` is added to the `System.Threading.ThreadPool`, it works like the ThreadCall, but only use a new coroutine if the caller isn't in a coroutine, also using `__Async__(true)` will wrap the target function by the `SafeThreadCall`.


## [1.4.5] - 2019-11-27 WangXH <kurapica125@outlook.com>
### Added
- `GetSubTypes` Method is added to `System.Class` and `System.Interface`, will return an iterator to get all sub types directly extend or inherit the target interface or class.


## [1.4.4] - 2019-10-29 WangXH <kurapica125@outlook.com>
### Added
- `IsTemporary` Property is added to System.Web.HttpSession, so you can mark a session be cleared when user closed the browser

### Changed
- Add support for `IsTemporary` session settings


## [1.4.3] - 2019-10-29 WangXH <kurapica125@outlook.com>
### Changed
- The System.Data.DataEntityCache can use cache class(extend System.Data.ICache) as its second template parameter, so it can create cache object directly, works like `System.Data.DataCollection[{MyDataContext, NgxLua.Redis }]`


## [1.4.2] - 2019-10-20 WangXH <kurapica125@outlook.com>
### Changed
- The environment will access the `_G` at the last, after read the global namespace, so other oop system won't affect the PLoop


## [1.4.1] - 2019-10-18 WangXH <kurapica125@outlook.com>
### Changed
- The environment will access the global namespaces at last, after read the base environment


## [1.3.2] - 2019-09-03 WangXH <kurapica125@outlook.com>
### Changed
- The class object's default property value won't be serialized.


## [1.3.1] - 2019-08-30 WangXH <kurapica125@outlook.com>
### Changed
- ProcessInnerRequest will return the status code as the first value, then the redirected path or the json data.


## [1.2.15] - 2019-08-23 WangXH <kurapica125@outlook.com>
### Changed
- Fix the error message stack level for un-supported type settings in `__Arguments__`.
- Add variable checking for Enum.ValidateFlags, the check will be disabled when set PLOOP_PLATFORM_SETTINGS.TYPE_VALIDATION_DISABLED to true.


## [1.2.14] - 2019-08-18 WangXH <kurapica125@outlook.com>
### Added
- The `System.__Recyclable__` attribtue is added for classes, so their objects are recylable, the system won't wipe them when Dispose them, and the *Disposed* field won't be set to true since we need to re-use them. The recycle part must be done by the classes themselves.


## [1.2.11] - 2019-06-03 WangXH <kurapica125@outlook.com>
### Added
- The prototype.lua keeps using no old style to avoid some problem caused by the environment changing, there is no need to keep using the old definition style.


## [1.2.10] - 2019-06-03 WangXH <kurapica125@outlook.com>
### Added
- The `System.Web.__InnerRequest__` is added, so the web request handler(function or action) can only be processed for inner request.


## [1.2.9] - 2019-05-19 WangXH <kurapica125@outlook.com>
### Changed
- The queue and final method system added for System.Data.DataCollection, only suppor on data entity query, so we can use codes like `ctx.Users:Where("Telno like '%s'", telno):OrderBy("id"):Limit(10):Offset(30):Query()`, the query key in Where and OrderBy could be the data entity property, it'll be changed to the real field name.


## [1.2.8] - 2019-05-17 WangXH <kurapica125@outlook.com>
### Changed
- System.Data.DataCollection.Query method changed, can no longer be used to process sql directly, we can use `ctx.Users:Where("id in (%s)", {1, 2, 3, 4}):OrderBy{ "id" }:Query()`, the Lock method is also changed.


## [1.2.7] - 2019-04-21 WangXH <kurapica125@outlook.com>
### Changed
- Fix the Date.Parse for custom format.


## [1.2.6] - 2019-04-09 WangXH <kurapica125@outlook.com>
### Changed
- The inner request will also return the redirected path and code as result.


## [1.2.5] - 2019-04-05 WangXH <kurapica125@outlook.com>
### Changed
- The `__View__` attribute don't require the function must have a return value as the view data now.


## [1.2.4] - 2019-04-03 WangXH <kurapica125@outlook.com>
### Changed
- The data view's property is not read only now, so they can be serialized.


## [1.2.3] - 2019-04-02 WangXH <kurapica125@outlook.com>
### Changed
- Fix the inner request, it won't use the http method from the raw quest if the params is specific.
- The default template system in the web, can use tables as params for inner request or embed pages like `@[~/test { id = 1}]`, no need use the parentheses.


## [1.2.2] - 2019-04-01 WangXH <kurapica125@outlook.com>
### Changed
- The System.Web.HttpSession have a new property "Context" used to get the context where it's generated.
- Fix the spell error for method "TrySetItems" of System.Web.ICacheSessionStorageProvider.
- Struct.GetErrorMessage will only have one return value now, others are discarded.
- Fix the System.Web.__Form__ can't validate single value for array types.
- Send the Json data in an inner request will just return the json data to where the `context:ProcessInnerRequest(...)` is called, the system won't try to serialize and output it.
- The inner request will use the raw request's http method if not specific, also will use the raw request's querystring or form if not specific.
- The System.Web.ParseString will also convert the Lua table(object) values to json format string, so we can use the lua table in the template directly.
- Fix the System.Web.JsonFormatProvider fail to parse 1-byte json data.


## [1.2.1] - 2019-03-26 WangXH <kurapica125@outlook.com>
### Changed
- The System.Data.Cache add an abstract method: TrySet, used to try add a key value pair when the key not existed, this is used to replace the Exist-Set operation so used to make sure the operation is thread-safe.


## [1.1.0] - 2019-03-19 WangXH <kurapica125@outlook.com>
### Added
- dictionary struct type can be created like `struct { [String] = Number }`, used to specific the type of the keys and values
- Struct.GetDictionaryKey & Struct.GetDictionaryValue added to fetch the types of the dict struct types
- IDictionary.ToDict method added, used to save the key-value pairs to a new dictionary

### Changed
- System.Serialization added support to the dict struct type, the key must be serializable custom struct type and the value type must be serializable, but nothing stop you convert them to **Dictionary** for serialization.
- `System.Web.__Form__` will refuse to use dict struct type.
- System.Web.JsonFormatProvider added check on member or dict struct type, so it won't check all elements to find out the value is an array.


## [1.0.0] - 2019-03-17 WangXH <kurapica125@outlook.com>