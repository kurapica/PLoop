# Changelog
All notable changes to this project will be documented in this file.

## [1.2.3] - 2019-04-02 WangXH <kurapica125@outlook.com>
### Changed
- Fix the inner request, it won't use the http method from the raw quest if the params is specific.

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
-


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