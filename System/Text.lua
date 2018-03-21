--===========================================================================--
--                                                                           --
--                                System.Text                                --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2014/10/05                                               --
-- Update Date  :   2018/03/16                                               --
-- Version      :   0.1.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
	namespace "System.Text"

	--- Represents a character encoding.
	__Abstract__() __Sealed__()
	class "Encoding" (function(_ENV)
	    --- The name of the encoding
	    __Static__()
	    property "EncodingName" { set = false, default = "Encoding" }

	    --- Decode to the unicode code points
	    function Decode() end

	    --- Encode the unicode code points
	    function Encode() end
	end)
end)
