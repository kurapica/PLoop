--===========================================================================--
--                                                                           --
--                        System.Web.HelperPageLoader                        --
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
    IO.Resource.__ResourceLoader__"lsp" __SuperObject__(false)
    __Sealed__() __PageRender__("LuaServerPage", PageLoader)
    class "System.Web.LuaServerPageLoader" (function (_ENV)
        inherit "PageLoader"

        export { PageLoader, IOutputLoader, IContextOutputHandler }

        -- Method
        function Load(self, path)
            local target = IOutputLoader.Load(self, path)

            if target then class(target, { IContextOutputHandler }) end

            return target
        end
    end)
end)