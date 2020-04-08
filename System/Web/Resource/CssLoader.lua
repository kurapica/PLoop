--===========================================================================--
--                                                                           --
--                          System.Web.CssLoader                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/04/08                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
	--- The css file loader
	IO.Resource.__ResourceLoader__"css"
	__Sealed__() __PageRender__("CssFile", StaticFileLoader, { comment = "/* %s */" })
	class "System.Web.CssLoader" { StaticFileLoader }
end)