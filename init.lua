-- Core
require "PLoop.Core"

-- System
require "PLoop.System.System"
require "PLoop.System.Logger"
require "PLoop.System.Date"
require "PLoop.System.Collections"
require "PLoop.System.Text"
require "PLoop.System.IO"
require "PLoop.System.Recycle"
require "PLoop.System.Serialization"
require "PLoop.System.Threading"
-- require "PLoop.System.Xml"

-- System.Collections.ListStreamWorker
require "PLoop.System.Collections.List"
require "PLoop.System.Collections.Dictionary"
require "PLoop.System.Collections.IIndexedListSorter"
require "PLoop.System.Collections.ObjectArray"

-- System.Text
require "PLoop.System.Text.UTF8Encoding"
require "PLoop.System.Text.UTF16Encoding"

-- System.IO
if type(io) == "table" then
	require "PLoop.System.IO.Path"
	require "PLoop.System.IO.File"
	require "PLoop.System.IO.Resource"
	require "PLoop.System.IO.FileWriter"
	require "PLoop.System.IO.FileReader"

	-- System.IO.Resource
	require "PLoop.System.IO.Resource.LuaLoader"
end

-- System.Serialization
require "PLoop.System.Serialization.LuaFormatProvider"
require "PLoop.System.Serialization.StringFormatProvider"
