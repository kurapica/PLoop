--===========================================================================--
--                                                                           --
--                         System.Web.IRenderEngine                          --
--                                                                           --
--===========================================================================--

--===========================================================================--
-- Author       :   kurapica125@outlook.com                                  --
-- URL          :   http://github.com/kurapica/PLoop                         --
-- Create Date  :   2016/04/10                                               --
-- Update Date  :   2018/03/15                                               --
-- Version      :   1.0.0                                                    --
--===========================================================================--

PLoop(function(_ENV)
    namespace "System.Web"

    --- Represents the content type of the render
    __Sealed__() __AutoIndex__()
    enum "RenderContentType" {
        "RecordLine",
        "StaticText",
        "NewLine",
        "LuaCode",
        "Expression",
        "EncodeExpression",
        "MixMethodStart",
        "MixMethodEnd",
        "CallMixMethod",
        "RenderOther",
        "InnerRequest",
    }

    --- Represents the interface of render engine
    __Sealed__() __AnonymousClass__()
    interface "IRenderEngine"(function (_ENV)
        extend "Iterable"

        export {
            yield               = coroutine.yield,
            RCT_RecordLine      = RenderContentType.RecordLine,
            RCT_StaticText      = RenderContentType.StaticText,
            RCT_NewLine         = RenderContentType.NewLine,
            RCT_MixMethodStart  = RenderContentType.MixMethodStart,
            RCT_MixMethodEnd    = RenderContentType.MixMethodEnd,
        }

        -----------------------------------------------------------------------
        --                              method                               --
        -----------------------------------------------------------------------
        __Iterator__()
        function GetIterator(self, reader) return self:ParseLines(reader) end

        --- Init the engine with page loader and the page config.
        __Abstract__() function Init(self, loader, config) end

        --- Parse the lines and yield all content with type
        __Abstract__() function ParseLines(self, reader)
            -- Use yield not return to send back content and other informations
            yield(RCT_MixMethodStart, "Render")
            for line in reader:ReadLines() do
                line = line:gsub("%s+$", "")
                yield(RCT_RecordLine, line)
                yield(RCT_StaticText, line)
                yield(RCT_NewLine)
            end
            yield(RCT_MixMethodEnd)
        end
    end)
end)