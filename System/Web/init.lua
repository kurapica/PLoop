-- The init file of PLoop.System.Web

require "PLoop"
require "PLoop.System.IO"
require "PLoop.System.Data"

-- Core
require "PLoop.System.Web.Core"

-- Context
require "PLoop.System.Web.Context.HttpCookie"
require "PLoop.System.Web.Context.HttpRequest"
require "PLoop.System.Web.Context.HttpResponse"

-- Interface
require "PLoop.System.Web.Interface.IHttpContextHandler"
require "PLoop.System.Web.Interface.IHttpOutput"
require "PLoop.System.Web.Interface.IContextOutputHandler"
require "PLoop.System.Web.Interface.IRenderEngine"
require "PLoop.System.Web.Interface.IOutputLoader"

-- Http Context
require "PLoop.System.Web.Context.HttpSession"
require "PLoop.System.Web.Context.HttpContext"

-- Resource
require "PLoop.System.Web.Resource.StaticFileLoader"
require "PLoop.System.Web.Resource.JavaScriptLoader"
require "PLoop.System.Web.Resource.CssLoader"

require "PLoop.System.Web.Resource.PageRenderEngine"
require "PLoop.System.Web.Resource.PageLoader"
require "PLoop.System.Web.Resource.MasterPageLoader"
require "PLoop.System.Web.Resource.EmbedPageLoader"
require "PLoop.System.Web.Resource.HelperPageLoader"
require "PLoop.System.Web.Resource.LuaServerPageLoader"

-- Context Worker
require "PLoop.System.Web.ContextHandler.Route"

-- SessionIDManager
require "PLoop.System.Web.ContextHandler.GuidSessionIDManager"

-- MVC
require "PLoop.System.Web.MVC.Controller"
require "PLoop.System.Web.MVC.ViewPageLoader"

-- Web Attribute
require "PLoop.System.Web.Attribute.ContextHandler"
require "PLoop.System.Web.Attribute.Validator"