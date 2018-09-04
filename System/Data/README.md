System.Data
====

The **System.Data** provide an ORM framework based on the [PLoop][], to use it on a data base, you should have or create the implementation of several interfaces.


An example for the mysql
====

You can find an implementation in [NgxLua][] named **MySQLProvider** tested with mysql 8.0.

As an example, we have a data base named EM used to manage the employees, we should define a data base context to represent it:

```lua
import "System.Data"

enum "EmployeeType" {
	Worker 		= 1,
	Officer 	= 2,
}

__DataContext__()  -- declare the class is a data base context
class "EM" (function(_ENV)
	-- export the connection class of mysql
	export { NgxLua.MySQL.MySQLConnection }

	-- Init the connection when a context object is created
	function __ctor(self)
		self.Connection = MySQLConnection {
			host = "127.0.0.1",
			port = 3306,
			database = "EM",
			user = "root",
			password = "xxxxxx",
			charset = "utf8mb4",
			max_packet_size = 2 * 1024 * 1024,
		}
	end

	-- Declare the entity classes for data tables
	__DataTable { indexes = {
			{ fields = { "id" }, primary = true }
		}
	}
	class "employee" (function(_ENV)
		-- autoincr means the id is auto given by the data base when inserted
		__DataField__{ autoincr = true }
		property "id"           { type = NaturalNumber }

		__DataField__{ notnull = true }
		property "type" 		{ type = EmployeeType }

		__DataField__{ notnull = true }
		property "joindate"     { type = Date }

		__DataField__{ notnull = true }
		property "leavedate"    { type = Date }

		__DataField__{ notnull = true }
		property "name"         { type = String }

		__DataField__{ unique = true }
		property "telno"        { type = String }

		__DataField__{ unique = true }
		property "email"        { type = String }
	end)
end)
```

Now we can use the context objects to do the CRUD works:

```lua
-- Create data row
function addEmployee(name, type, telno, email)
	local employee

	with(EM())(function(ctx)
		-- Open the data base connection

		with(ctx.Transaction)(function(trans)
			-- Start a transaction

			-- Add a new employee to the data table
			-- the employees is an auto-create property of the context object
			-- it provide a data collection of the employee entity class
			ctx.employees:Add{
				type 	= type,
				name 	= name,
				telno 	= telno,
				email 	= email,
				joindate= Date.Now,
			}

			-- Save the data to data base
			ctx:SaveChanges()
		end)
	end)

	-- we can get employee id after it's inserted
	return employee and employee.id
end

--- Read a data row
function getEmployee(id)
	local employee

	if id then
		with(EM())(function(ctx)
			-- The query method will return a List[employee] object
			-- we can use First method to get the only result
			employee = ctx.employees:Query{ id = id }:First()
		end)
	end

	-- the employee is an object of the EM.employess class
	return employee
end

--- Update a data row
function fireEmployee(id)
	if not id then return end

	with(EM())(function(ctx)
		-- Open the data base connection

		with(ctx.Transaction)(function(trans)
			-- Start a transaction

			-- Query and Lock the employee
			local employee = ctx.employees:Lock{ id = id }:First()

			if employee the
				employee.leavedate = Date.Now

				-- Save the operation to data base
				ctx:SaveChanges()
			else
				-- Cancel the transaction
				trans:Rollback()
			end
		end)
	end)
end

-- Delete a data row
function deleteEmployee(id)
	if not id then return end

	with(EM())(function(ctx)
		-- Open the data base connection

		with(ctx.Transaction)(function(trans)
			-- Start a transaction

			-- Query and Lock the employee
			local employee = ctx.employees:Lock{ id = id }:First()

			if employee the
				employee:Delete()

				-- Save the operation to data base
				ctx:SaveChanges()
			else
				-- Cancel the transaction
				trans:Rollback()
			end
		end)
	end)
end
```

We'll see the more details from those examples.


The Keyword - with
====

In the previous examples, all data base operations are processed under the **with** keywords.

The data context object, the data base connection, the data base transaction are all extend the System.IAutoClose interface.

So we can keep those features auto closed no matter whether the codes raised errors.


The Data Context
====

The classes declared with `__DataContext__` attribtue would extend the **System.Data.IDataContext** automatically.

Here is a simple view of the interface :

Property          |Type                      |Description
:-----------------|:-------------------------|:-----------------
Connection 	      |System.Data.IDbConnection |The data base connection object
Transaction       |System.Data.IDbTransaction|Read-only, The data base transaction, if not existed or closed, a new transaction will be created

Method            |Arguments                 |Description
:-----------------|:-------------------------|:-----------------
Open              |(null)                    |Open the connection
Close             |(null)                    |Close the connection
AddChangedEntity  |(entity)                  |Add a changed entity(System.Data.IDataEntity) which represent a data row
SaveChanges       |(null)                    |Save all the changed entities to the data base
Query             |(sql, ...)                |Send the sql and parameters to the data base and return the result as List
QueryView         |(viewcls, sql, ...)       |Send the sql and parameters to the data base and return the result wrapped in viewcls(System.Data.IDataView) as List
Execute           |(sql, ...)                |Send the sql and parameters to the data base and return the result


Normally, we set the connection object in the context class's constructor, and use the Transaction object like the examples.

The *Open*, *Close*, *AddChangedEntity* are used by the framework, there is no need to call them by yourselves.

The *Query* method is not like the example we used `ctx.employees:Query{id = id }`, there is no data table schema works here. This method is very useful for complex queries like table join, those are very difficult to be expressed with the entity query style.

I don't want bring a complex query style like `ctx.employees:Query():Join(ctx.salary):Select("base").......` instead of the simple and powerful sql.






[PLoop]: https://github.com/kurapica/PLoop/ "Prototype Lua Object-Oriented Program"
[NgxLua]: https://github.com/kurapica/NgxLua/ "The implementation for Openresty"