--===========================================================================--
--                                                                           --
--                        System.Web.StaticFileLoader                        --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/04/02                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
	--- The static file loader
	__Sealed__() __PageRender__("StaticFile", IOutputLoader)
	class "System.Web.StaticFileLoader" { IOutputLoader }
end)