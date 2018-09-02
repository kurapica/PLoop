--===========================================================================--
--                                                                           --
--                        System.Web.EmbedPageLoader                         --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/23                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    IO.Resource.__ResourceLoader__"embed"
    __Sealed__() __PageRender__("EmbedPage", PageLoader)
    class "System.Web.EmbedPageLoader" { PageLoader }
end)