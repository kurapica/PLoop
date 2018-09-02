--===========================================================================--
--                                                                           --
--                          System.Web.IHttpOutput                           --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/02/19                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    --- Will be defined later
    interface "System.Web.IOutputLoader" {}

    __Sealed__()
    __NoNilValue__{ false, Inheritable = true }
    __NoRawSet__{ false, Inheritable = true }
    interface "System.Web.IHttpOutput" (function (_ENV)
        extend (System.Web.IHttpContext)

        export {
            pcall               = pcall,
            getmetatable        = getmetatable,
            isclass             = Class.Validate,
            issubtype           = Class.IsSubType,
            GetRelativeResource = GetRelativeResource,

            IHttpOutput, IOutputLoader
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        --- Init the for context's request, generate the head for response
        -- @param   context         the http context
        function OnLoad(self, context) end

        --- Safe render the body and convert the error to the real line
        -- @param   write           the response write
        -- @param   indent          the text indent
        function SafeRender(self, ...)
            local ok, err = pcall(self.Render, self, ...)
            if not ok then IOutputLoader.RaiseError(err) end
        end

        --- Render body to response, auto-generated from the file
        -- @param   write           the response write
        -- @param   indent          the text indent
        __Abstract__() function Render(self, write, indent) end

        --- Using other output object to generate contents to the response
        -- @param   url             the target resource's path
        -- @param   write           the response write
        -- @param   indent          the text indent
        -- @param   default         the default text if the target resource not existed
        -- @pram    ...             the arguments to generate the target object
        function RenderAnother(self, url, write, indent, default, ...)
            local cls = GetRelativeResource(self, url, self.Context)
            if cls then
                if isclass(cls) and issubtype(cls, IHttpOutput) then
                    local page      = cls(...)

                    local context   = self.Context
                    page.Context    = context
                    page:OnLoad(context)
                    return page:SafeRender(write, indent or "")
                end
            end

            -- Default
            write(indent)
            write(default)
        end
    end)
end)