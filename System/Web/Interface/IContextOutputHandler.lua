--===========================================================================--
--                                                                           --
--                     System.Web.IContextOutputHandler                      --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/04/08                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Represents the interface of context output handler
    __Sealed__() interface "System.Web.IContextOutputHandler" (function (_ENV)
        extend "IHttpOutput" "IHttpContextHandler"

        export {
            HeadPhase               = IHttpContextHandler.ProcessPhase.Head,
        }

        -----------------------------------------------------------------------
        --                             property                              --
        -----------------------------------------------------------------------
        property "ContentType" { Type = String, Default = "text/html" }

        -- Override Method
        function Process(self, context, phase)
            if phase == HeadPhase then
                context.Response.ContentType = self.ContentType
                self.Context = context
                return self:OnLoad(context)
            else
                return self:SafeRender(context.Response.Write, "")
            end
        end
    end)
end)