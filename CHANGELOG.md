# Changelog
All notable changes to this project will be documented in this file.

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