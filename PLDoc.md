# PLoop Documentation

To easily generate documentation out of the source codes, like the [LuaDoc][] we'll keep using tags in comments, since we have plenty new features and new development styles that can't be taged by the [LuaDoc][] or [LDoc][], we need expand those tags and comment rules.

## Documented comments

The documented comments should start with at least 3 hyphens:

    --- This is a document comment.
    -- More description.
    -- Other description.

 The documentation ends with the first line of code found.

An empty comment line also can be used:

    ---------------------------
    -- This is a test func
    ---------------------------
    function test()
    end

The second empty comment line would be ignored since the next line is a code and the documentation it started doesn't existed, so the previous documentation without target would be used.

 The block comments with one or more hyphens at the start also count, its end is the documentation's end:

    --[=[-
        This is a document block
    ]=]

Comments like '---xxxxx---' xxxx would be ignored.

If there are no valid feature like type, table, function and others or auto infered tag like @module, @prototype, @method is used, the comment should be ignored.

Comments like

    -------------------------------
    --          xxxxx            --
    --          xxxxx            --
    -------------------------------

will be ignored, there are two documented comments, but all empty.

## Documentation for PLoop

Within PLoop, the codes are mostly organized in nested environments(for Module or Application) or namespaces(for enum, struct class and interface) as features(type or type's feature like property):

    --- The Test module
    Module "Test" "v1.0.0"

    namespace "Test.Model"

    --- The Unit class
    class "Unit" (function(_ENV)

        --- The unit's location type
        struct "Location" (function(_ENV)
            x = Number
            y = Number
        end)

        --- The unit's name
        property "Name" { Type = String }

        --- The unit's location
        property "Location" { Type = Location }

        __Arguments__{ Location }
        function SetLocation(self, loc)
        end
    end)

The codes are already self-documented and the analysis could figure out many informations like whether the type is a class, the type of the property, the method's argument type(from the `__Arguments__`) and etc.

The documented comments should be attached to the next feature, like class, property, method and etc, or use infered tags to force it.

Since those features already has informations that can be fetched, they should be generated to the documentation no matter if they have documented comments attached or not.


## Comment tags

Although many informations can be figured out by analysing the code, we still need comment tags to explict provide informations like:

    import "System"

    --- A unit class
    -- @prototype class
    -- @type TestProject.Unit
    class "Unit" (function(_ENV)
        --- Unit's name
        -- @property-type System.String
        property "Name" { Type = String }
    end)

The @type used for the Unit could provide the namespace path, so the system don't need to figure it out, the @prop-type will also do the same work.

The comment tags should started with "@" and must be the head of the comment line, and end with next comment tag or code.

Here is a list of comment tags used in the PLDoc:

    * feature tags:
        * prototype <word>      -- the prototype name.                  <auto infered>
        * namespace <word>      -- the namespace.                       <auto infered>
        * enum <word>           -- the enum namespace.                  <auto infered>
        * struct <word>         -- the struct namespace.                <auto infered>
        * class <word>          -- the class namespace.                 <auto infered>
        * interface <word>      -- the interface namespace.             <auto infered>
        * enum <word>           -- the enum namespace.                  <auto infered>
        * member <word>         -- the struct's member.                 <auto infered>
            * -type <word>      -- the member's type.                   <auto infered>
            * -default <word>   -- the member's default value.          <auto infered>
            * -required <word>  -- whether the member is required.      <auto infered>
        * property|prop <word>  -- the property name.                   <auto infered>
            * -type <word>      -- the property type.                   <auto infered>
            * -default <word>   -- the property default value.          <auto infered>
            * -readonly <bool>  -- whether the property is readonly.    <auto infered>
            * -writeonly <bool> -- whether the property is writeonly.   <auto infered>
        * event <word>          -- the event name.                      <auto infered>
        * meta-method <word>    -- supported meta-method name.          <auto infered>
        * method <word>         -- the method name.                     <auto infered>
        * static                -- the feature is static.               <auto infered>

    * common tags:
        * @author <text>        -- the author of the Module, class, interface or other features.
        * @copyright <text>     -- the copyright notice of the feature.
        * @description <text>   -- the description of the next feature. <auto infered>
        * @field <text>         -- the description of a table's field.
        * @param <word> (<type>) <text>  -- the function's parameter with its type and description, multi supported.
        * @release <text>       -- the release description.
        * @return <text>        -- the return value's description, multi supported.
        * @section <text>       --
        * @see <text>           -- the refer to other feature's descriptions.
        * @table <text>         -- the table name.
        * @usage <text>         -- the usage of the feature.
        * @region <text>        -- start of a region.
        * @endregion <text>     -- end of a region, shoud be pairs with the @region.
        * @owner <word>         -- the owner of the features, must be declared in the same file and before the feature.
        * @format (params) <text>        -- the format of the paramerters with description.
        * @rformat (returns) <text>       -- the format of the return values with description.


Infered Tags
The following tags would be normally infered by LuaDoc, but they can be used to override the infered value.

@class <word>
If LuaDoc cannot infer the type of documentation (function, table or module definition), the programmer can specify it explicitally.
@description
The description of the function or table. This is usually infered automatically.
@name <word>
The name of the function or table definition. This is usually infered from the code analysis, and the programmer does not need to define it. If LuaDoc can infer the name of the function automatically it's even not recomended to define the name explicitally, to avoid redundancy.


@module A Lua module containing functions and tables, which may be inside sections
@classmod Like @module but describing a class
@submodule A file containing definitions that you wish to put into the named master module
@script A Lua program
@author (multiple), @copyright, @license, @release only used for project-level tags like @module
@function, @lfunction. Functions inside a module
@param formal arguments of a function (multiple)
@return returned values of a function (multiple)
@raise unhandled error thrown by this function
@local explicitly marks a function as not being exported (unless --all)
@see reference other documented items
@usage give an example of a function's use. (Has a somewhat different meaning when used with @module)
@table a Lua table
@field a named member of a table
@section starting a named section for grouping functions or tables together
@type a section which describes a class
@within puts the function or table into an implicit section
@fixme, @todo and @warning are annotations, which are doc comments that occur inside a function body.


## Documentation for normal lua codes

Unlike PLoop's development style, normal lua codes also could be used, to generate documentation out from them, the comments should


[LuaDoc]: http://keplerproject.github.com/luadoc/ "LuaDoc"
[LDoc]: https://github.com/stevedonovan/LDoc "LDoc"