-- The init file of PLoop Core
local root = require "PLoop.Prototype"

-- System
require "PLoop.System.Collections"
require "PLoop.System.Text"
require "PLoop.System.IO.TextAccessor"
require "PLoop.System.Threading"
require "PLoop.System.Serialization"
require "PLoop.System.Date"
require "PLoop.System.Logger"
require "PLoop.System.Recycle"
require "PLoop.System.Observer"

-- System.Collections
require "PLoop.System.Collections.List"
require "PLoop.System.Collections.Dictionary"
require "PLoop.System.Collections.Proxy"
require "PLoop.System.Collections.IIndexedListSorter"
require "PLoop.System.Collections.Array"
require "PLoop.System.Collections.Queue"

-- System Configuration
require "PLoop.System.Configuration"

-- System.Serialization
require "PLoop.System.Serialization.LuaFormatProvider"
require "PLoop.System.Serialization.StringFormatProvider"

-- System.Text
require "PLoop.System.Text.UTF8Encoding"
require "PLoop.System.Text.UTF16Encoding"

-- System.Reactive
require "PLoop.System.Reactive.Observer"
require "PLoop.System.Reactive.Observable"
require "PLoop.System.Reactive.Subject"
require "PLoop.System.Reactive.Operator"

return root