-- The init file of PLoop Core
local root = require "PLoop.Prototype"

-- System
require "PLoop.System.Scalar"
require "PLoop.System.Collections"
require "PLoop.System.Threading"
require "PLoop.System.Text"
require "PLoop.System.Serialization"
require "PLoop.System.Date"
require "PLoop.System.Logger"
require "PLoop.System.Recycle"
require "PLoop.System.ValueWrapper"

-- System.Collections
require "PLoop.System.Collections.List"
require "PLoop.System.Collections.Dictionary"
require "PLoop.System.Collections.Proxy"
require "PLoop.System.Collections.IIndexedListSorter"
require "PLoop.System.Collections.Array"
require "PLoop.System.Collections.Queue"
require "PLoop.System.Collections.Range"

-- System.Threading
require "PLoop.System.Threading.TaskScheduler"

-- System Configuration
require "PLoop.System.Configuration"

-- System.Text.Encoding
require "PLoop.System.Text.UTF8Encoding"
require "PLoop.System.Text.UTF16Encoding"

-- System.Serialization
require "PLoop.System.Serialization.LuaFormatProvider"
require "PLoop.System.Serialization.StringFormatProvider"
require "PLoop.System.Serialization.JsonFormatProvider"

-- System.Text.Encoder
require "PLoop.System.Text.XmlEntity"
require "PLoop.System.Text.Base64"
require "PLoop.System.Text.Deflate"

-- Syste.Text
require "PLoop.System.Text.Crc"
require "PLoop.System.Text.TemplateString"

-- System.Reactive
require "PLoop.System.Observer"
require "PLoop.System.Reactive.Reactive"
require "PLoop.System.Reactive.Observer"
require "PLoop.System.Reactive.Subject"
require "PLoop.System.Reactive.ReactiveValue"
require "PLoop.System.Reactive.ReactiveField"
require "PLoop.System.Reactive.ReactiveList"
require "PLoop.System.Reactive.ReactiveDictionary"
require "PLoop.System.Reactive.Observable"
require "PLoop.System.Reactive.Operator"
require "PLoop.System.Reactive.Watch"

return root