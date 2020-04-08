--===========================================================================--
--                                                                           --
--                           System.Web.PageLoader                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2015/05/10                                               --
-- Update Date  :   2018/04/02                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    __Sealed__() __PageRender__("HtmlPage", IOutputLoader, { engine = PageRenderEngine, comment = "<!-- %s -->" })
    class "System.Web.PageLoader" { IOutputLoader }
end)