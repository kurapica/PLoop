PLoop - System.Web
====

**System.Web** is a web framework designed to be an abstract layer for web development, it'd provide interfaces and features that not depends on the web server.

The System only support UTF-8 for now.

This is an abstract framework so can't be used in any web server directly, You can find runnable examples in [NgxLua][], it's an implementation based on the [Openresty]().


Resource files
====

You will find files like `index.lsp`, `homecontroller.lua`, `masterpage.master` in the `Example/root`. Unlike the core files, those files are loaded when they are accessed.

As an example, `GET /index.lsp` will load the `index.lsp`, it'll be converted to a class whose object would be used to generate the response for the request. When a new `Get /index.lsp` coming, the file has already been loaded, so the generated class would be used directly, the resource system also can reload the file when it's modified, the reload behavior should be turn off when you publish the web site.

Those files are called **Resource File**s, the [PLoop][] provide a **System.IO.Resource** system to manage the loading and reloading of those files.

Several resource loaders (extend the **System.IO.IResourceLoader**) are registered to the resource system with suffixes.

The [PLoop][] provide the **System.IO.Resource.LuaLoader** for ".lua" files, used to get features defined in the lua file with the same name of the file.

The [PLoop.System.Web][] provide several resource loaders to generate classes to answer the http request like **System.Web.LuaServerPageLoader** for ".lsp" files.

In the web framework, the resource files are used to create classes to generate response. So, a new interface **System.Web.IOutputLoader** is defined to extend the **System.IO.IResourceLoader**, it combined a render engine system to easy the creation of custom resource loaders, so you can create your own file types and custom render rules.

Here are several resource types provided by the [PLoop.System.Web][] (The .lsp, .master, .helper, .embed all use **System.Web.PageRenderEngine** render engine, so they share the same render rules) :


Lua Server Page (.lsp)
====

The common files used to generate html content are lua server pages.

To create a simple html page like:

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>PLoop.System.Web Test Page</title>
			<script type="text/javascript" src="/js/jquery-2.1.4.min.js"></script>
		</head>
		<body>
			<p>
				This is the first PLoop.System.Web test page.
			</p>
		</body>
	</html>

Just copy the content to a .lsp file (like index.lsp). The lsp file contains the html and lua code and will be converted to a page class, then it would be used to handle the http request and generate the response.


Master Page (.master)
====

When you need to apply the same layout for several lsp files, it's best to create a master page that incldue the most common parts.

A master page file is ended with ".master". So if we create a "mymaster.master" with the content :

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>@{title My web site}</title>
			@{jspart <!-- javascript placeholder -->}
		</head>
		<body>
			@{body}
		</body>
	</html>

The **System.Web.PageRenderEngine** use *@* as the directive, it means an instruction here to be executed.

The `@{title My web site}` is used to declare a **web part** that would be replaced by child page classes, *title* is it's name, the rest are default text, if the web part is not defined in the child page, the default text would be used.

Then the *index.lsp* :

	@{ master = "mymaster.master" }

	@title{
		PLoop.System.Web Test Page
	}

	@body{
		<p>
			This is the first PLoop.System.Web test page.
		</p>
	}


The **System.Web.IOutputLoader** added a special rule for those resource files : if the first line of the file contains a lua table, it would be parsed as the page's configuration.

In here the *master* means the page class's super class, the *index.lsp* can also be used as another lsp file's master page, so the web part can be declared in both master page and the lua server page. Since the *index.lsp* inherited the *mymaster.master*, the *index.lsp* only need to define the web parts.

To implement a web part, the `@name{` and `}` must be on each line's head, and the content must have an indent(tab or space) for each line, so the render engine will know the begin and the end of it.

Beware, the **System.Web.IOutputLoader** will use the indents to generate more reable response output, and the **System.Web.PageRenderEngine** will use the indents to mark the start and end of blocks(like web part and lua code blocks), so you must keep using the same indent style for one files (only use tab or only use space, and keep the start and end part with same indents).

If the page don't provide a web part, it would be leave empty or use the web part's default value. So if don't give the *title* part, the output content should be `<title>My web site</title>`.

So the output result of *index.lsp* would be :

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>PLoop.System.Web Test Page</title>
			<!-- javascript placeholder -->
		</head>
		<body>
			<p>
				This is the first PLoop.System.Web test page.
			</p>
		</body>
	</html>:



Mix HTML with lua
====

To embed lua into html, there are four ways in **System.Web.PageRenderEngine** :

* Block - Used to define pure lua functions, also can be used to define the page class's method and other features :

		@{
			local function rollDice(num, max, add)
				local sum = add

				for i = 1, num do
					sum = sum + math.random(max)
				end

				return sum
			end
		}

	Define a block of lua code is like defining a web part without name, it would be pure lua code in the block, if the function is not defined as local, it would be a class-method of the page class. The function and any variables defined in it can be used by anywhere that below the block.

* Inline - Used to print an expression value, if the expression is not clear, the expression should be enclosed in parentheses, if use `@<`, the value would be encoded (or in the page configuration, use `encode=true` to force encoding all inline expressions) :

		@body{
			<p>Roll a dice(5d6+3) : @rollDice(5, 6, 3) </p>
			<p>encode test : @< "<test/>" </p>
		}

	The output should be like

		<p>Roll a dice(5d6+3) : 22</p>
		<p>encode test : &lt;test/&gt; </p>


	Things like `@a`, `@b`, `@(a+b)`, `@rollDice(5, 6, 3)` are inline codes, an inline code should be an expression that return a value, the value would be converted to a string to be displayed. For the `a + b` expression, `@a + b` would confuse the system, it will treate the `@a` is a inline code, and the `+ b` is normal text, you should use parentheses around it. The system can realize complex expression like `@King.Parent:Greet( Person{ Name = "Ann" } )`, also can realize string word like `@'test'`, `@"test"`, `@[=[test]=]`.


* Full-line - Normally used to generate the control structure to control how the content would be generated, use '@>' to mark the full line is lua code, if the first word of the line is a keyword like 'local', 'if', 'for', you can only use '@' at the start of the line, and `@--` would be used for full line comments :

		@body{
			@ local a, b = math.random(100), math.random(100)
			<p>@a + @b = @(a+b)</p>

			<p>Roll a dice(5d6+3) : @rollDice(5, 6, 3) </p>

			<p>
			@ local hour, msg = tonumber(os.date():match("(%d+):"))
			@ if hour < 11 then
				Good morning
			@ elseif hour > 20 then
				Good night
			@ end
			</p>
		}

	The *body* web part will be converted to one function, so you can declare any local variables and use any structures like `if-then-end`, `while-do-end`, `for-end`.  The control structures must be full-line.

	The result should be

		<p>81 + 87 = 168</p>

		<p>Roll a dice(5d6+3) : 24 </p>

		<p>
			Good night
		</p>


* Mixed Method - If we take the web part implement as function with zero-argument. We also can define function with arguments, it's called mixed method :

		@{
			local function appendVerSfx(path, version, suffix)
				return path .. suffix .. (version and "?v=" .. tostring(version) or "")
			end
		}

		@javascript(name, version) {
			<script type="text/javascript" src="/js/@appendVerSfx(name, version, '.js')"></script>
		}

	Here we defined a local method *appendVerSfx*, and then defined a mixed method to use it. The mixed method is used to generate javascript elements with name and version arguments.

	Here is how to use it :

		@{ master = "mymaster.master" }

		@{
			local function appendVerSfx(path, version, suffix)
				return path .. suffix .. (version and "?v=" .. tostring(version) or "")
			end
		}

		@javascript(name, version) {
			<script type="text/javascript" src="/js/@appendVerSfx(name, version, '.js')"></script>
		}

		@jspart{
			@{ javascript("jquery-2.1.4.min") }
			@{ javascript("index", 3) }
		}

	It's just like how to declare web parts, but there are a big different between them, when using mixed methods, the mixed method's definition are already know, when declare the web parts, their definition are unknow.

	The result would be :

		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
				<title>My web site</title>
				<script type="text/javascript" src="/js/jquery-2.1.4.min.js"></script>
				<script type="text/javascript" src="/js/index.js?v=3"></script>
			</head>
			<body>

			</body>
		</html>


The lua blocks can also be used in a web part or mixed method like :


		@body{
			<p>
				@ {
					local hour, msg = tonumber(os.date():match("(%d+):"))
					if hour < 10 then
						msg = "Good morning"
					elseif hour > 20 then
						msg = "Good night"
					else
						msg = "Have a nice day"
					end
				}
				@msg
			</p>
		}

Beware of the indents, the **System.Web.PageRenderEngine** don't do a semantic analysis for the code, so it won't know where the block stoped if the indents don't match. The output should be :

		<p>
			Good night
		</p>



Helper Page (.helper)
====

The mixed methods are generaly used as help methods, so it's better to store them in one file, those files are helper pages. Unlike other type pages, the helper page would be converted to an interface, so it can be used by any other page classes.

We can set the helper to master page directly, so all the lua server pages that inherit it can use those mixed methods.

With the *globalhelper.helper* :

	@{
		local function appendVerSfx(path, version, suffix)
			return path .. suffix .. (version and "?v=" .. tostring(version) or "")
		end
	}

	@javascript(name, version) {
		<script type="text/javascript" src="/js/@appendVerSfx(name, version, '.js')"></script>
	}

Re-write the *mymaster.master* :

	@{ helper = "globalhelper.helper" }

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>@{title My web site}</title>
			@{jspart <!-- javascript placeholder -->}
		</head>
		<body>
			@{body}
		</body>
	</html>

So the *index.lsp* :

	@{ master = "mymaster.master" }

	@jspart{
		@{ javascript("jquery-2.1.4.min") }
		@{ javascript("index", 3) }
	}


Embed Page (.embed)
====

By using `@[path default]`, we can embed other page files into the page. Normally, require the file with ".embed" suffix, but master and serer page can also be used(not recomment).

So with the given *notice.embed* file :

	<h2>
		Here is a description for test page<br/>
		To show how to use embed web pages.
	</h2>


Re-write the *index.lsp* :

	@{ master = "mymaster.master" }

	@body{
		@[notice.embed <!-- Notice placeholder -->]
	}

And the result would be

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>My web site</title>
			<!-- javascript placeholder -->
		</head>
		<body>
			<h2>
				Here is a description for test page<br/>
				To show how to use embed web pages.
			</h2>
		</body>
	</html>

If delete the *notice.embed* file, the output would be :

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>My web site</title>
			<!-- javascript placeholder -->
		</head>
		<body>
			<!-- Notice placeholder -->
		</body>
	</html>

It's also possible to use the inline code in the *path* and *default*, since it would required some parameters, it's better to define it in the helper file - *globalhelper.helper* :

	@{
		local function appendVerSfx(path, version, suffix)
			return path .. suffix .. (version and "?v=" .. tostring(version) or "")
		end
	}

	@javascript(name, version) {
		<script type="text/javascript" src="/js/@appendVerSfx(name, version, '.js')"></script>
	}

	@javascriptInc(name, version, id) {
		<script type="text/javascript">
			@[/js/@appendVerSfx(name, nil, '.js') // /js/@appendVerSfx(name, version, '.js')]
		</script>
	}

Now, for the *index.lsp* :

	@{ master = "mymaster.master" }

	@jspart{
		@{ javascript("jquery-2.1.4.min") }
		@{ javascriptInc("index", 3) }
	}

If the js file not existed :

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>My web site</title>
			<script type="text/javascript" src="/js/jquery-2.1.4.min.js"></script>
			<script type="text/javascript">
				// /js/index.js?v=3
			</script>
		</head>
		<body>

		</body>
	</html>

If it existed :

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>My web site</title>
			<script type="text/javascript" src="/js/jquery-2.1.4.min.js"></script>
			<script type="text/javascript">
				$(function(){
					var _Ver = 1.0;
				})
			</script>
		</head>
		<body>

		</body>
	</html>

The css files can also be emebed into page files. It's better to keep using file links in working versions, and change to emebed mode when published, you can do it by only changing some codes in the helper files.

The js and css files are all static files, if they existed as links, those files would be handled by a web server. If they are marked as embed, they'll be loaded into classes, this is done by **System.Web.JavaScriptLoader** and **System.Web.CssLoader**, the two loaders don't use the **System.Web.PageRenderEngine**, so the js and css file's content are written to the reponse directly.


Lua Code file (.lua)
====

For one http request, the Lua Server Page's execution will be divided into two steps :

* Call the page object's *OnLoad* method with the http context object, and generate the response header, so if you need validate request's parameters or redirect to other url, you should do it here.

* Call the page object's *Render* method to generate the response body. The *Render* method is generate by the render engine, so you shouldn't care about it.

To define the *OnLoad* method, we can do it within the *index.lsp* by using block code :

	@{ master = "mymaster.master" }

	@{
		function OnLoad(self, context)
			-- Generate a cookie
			context.Response.Cookies["TestCookie"].Value = "Test"
			context.Response.Cookies["TestCookie"].Expires = System.Date.Now:AddMinutes(10)
		end
	}

It'd be more clear to split the code and the html template, we can define the code part in a lua file, and then bind it to the *index.lsp*.

Here we define the *index.lua* :

	class "Index" {}

	function Index:OnLoad()
		self.PageTitle = "Test Page"

		self.Data = {
			{ Name = "Ann", Age = 12 },
			{ Name = "King", Age = 32 },
			{ Name = "July", Age = 22 },
			{ Name = "Sam", Age = 30 },
		}
	end

We define the class *Index* in the first line, the class's name should be the same with the file's name(case ignored), we don't give it the super class and other settings because that would be easy to set in the *.lsp* file.

Then give it an *OnLoad* method, in the method, we just init it with *PageTitle* and *Data* values.

Now, we can use *PageTitle* and *Data* in the *index.lsp* :

	@{ master="mymaster.master", code="index.lua" }

	@title{
		@self.PageTitle
	}

	@jspart{
		@{ javascript("jquery-2.1.4.min") }
		@{ javascript("index", 3) }
	}

	@body{
		<table border="1">
			<thead>
				<tr>
					<th>Person Name</th>
					<th>Person Age</th>
				</tr>
			</thead>
			<tbody>
			@> for _, data in ipairs(self.Data) do
				<tr>
					<td style="background-color:cyan">@data.Name</td>
					<td>@data.Age</td>
				</tr>
			@> end
			</tbody>
		</table>
	}


The *self* is the object created by the page class to handle the http request, you can use it in any web parts, html helpers, inline and full-line codes, it can't be used in local functions unless you pass the self to them.

The output is :

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>Test Page</title>
			<script type="text/javascript" src="/js/jquery-2.1.4.min.js"></script>
			<script type="text/javascript" src="/js/index.js?v=3"></script>
		</head>
		<body>
			<table border="1">
				<thead>
					<tr>
						<th>Person Name</th>
						<th>Person Age</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td style="background-color:cyan">Ann</td>
						<td>12</td>
					</tr>
					<tr>
						<td style="background-color:cyan">King</td>
						<td>32</td>
					</tr>
					<tr>
						<td style="background-color:cyan">July</td>
						<td>22</td>
					</tr>
					<tr>
						<td style="background-color:cyan">Sam</td>
						<td>30</td>
					</tr>
				</tbody>
			</table>
		</body>
	</html>


Configuration
====

The configuration of the sytem can be found in `Example/config.lua`, in the config file, we'll load lua modules, set log handlers, init the session management, create routers and some context handlers.

* `require "PLoop.System.Web"` - Load the web framework from the [PLoop][] and [PLoop.System.Web][] modules.

	In [NgxLua][]'s config file, the first line is `require "PLoop_NgxLua"`, it is used to load **PLoop_NgxLua** module which would load the [PLoop][] and [PLoop.System.Web][]. So, this is where to load lua modules.

* `namespace "MyWeb"` - Define a namespace for the _G, any features that loaded from the resource files like *index.lsp* would be defined under the namespace *MyWeb*.

	The are many type of resources for the web development, lua server page used to generate output for response, master page used to provide layout for lua sever pages(the super class of the lua server pages), helper page used to provide useful method to help create the server pages(helper is loaded as interface for the lua server page to extend).

	Without a namespace, when reload a file, a new class or interface should be generated from the file, if the file is a master page, the lua server pages that inherited it must all be reloaded. If there is a namespace, reload the file will only update the existed class or interface, so any other files related to it will receive the updating without reloading.

	The namespace also can be given in other places, we'll see in the details of the page's config.

* `System.Web.DebugMode = true` - If the debug mode is turn on, the resource files like *index.lsp* would be reloaded when modified, checking the last modified time of files would pay some cost, so you'd better turn off it when you publish the web site.

	There is a major issue in the reload system. In the pure lua, there is no api to get a file's last writed time, but by using `io.popen`, we can call shell command and read its output, so we can get a file's last writed time by using shell commands like dir, ls and etc.

	But there is one problem for it, the shell commands are different in each operation systems, for now, the PLoop only provide support for dos, macosx and some linux system.

	If you find the reload system won't work, or you can try writing an expression to the client :

			<p>OS: @System.IO.OSType(System.IO.GetOperationSystem()) </p>

	If the output is Unknown, it's means the PLoop don't know how to handle the commands in your OS.

	In this condition, you may contact me with information about your system so I can add support in the PLoop lib, or you can using some 3rd lua modules to provide a function to retrieve the file's last modified time, and assign it to the **System.IO.Resource** in the *config.lua* like :

			System.IO.Resource.GetLastWriteTime = func

* `System.Web.IOutputLoader.DefaultRenderConfig` - You may change the *index.lsp* file's content like :

		@{ noindent=true, nolinebreak=true }

		<html>
			<head>
			</head>
			<body>
			</body>
		</html>

	The reponse output would be :

		<html><head></head><body></body></html>

	The **System.Web.IOutputLoader** is the root resource loader interface(extend the **System.IO.IResourceLoader**) of the web system, it add a special rule for those resource files : if the first line of the file contains one lua table, it would be loaded as the page's config.

	The page's config may contains several settings :

	* namespace - The namespace of the page like 'MyWeb.Common'.

	* master - The master (super class page) of the page like '/share/mainmaster.master' .

	* helper - The helper (extend interface page) of the page, like '/share/globalhelper.helper', if there are several helpers, seperated them with ',' .

	* code - The lua code file, it'll combine the page to create the result type.

	* context - Whether the page extend IHttpContext, if true, the page can access context properties directly like `self.Request`, if false, the page can only access context properties like `self.Context.Request`.

	* session - Whether the page require Session, if true, the page can access the `self.Context.Session` to control the session, if false, `self.Context.Session` will just return nil, so the session would not be created in current context processing.

	* reload - Whether reload the file when modified in non-debug mode

	* encode - Whether auto encode the output with HtmlEncode(only for expressions)

	* noindent - Whether discard the indent of the output. The operation is done when loading the file to a result type, not its objects are used to generate output for response.

	* nolinebreak - Whether discard the line breaks of the output. The operation is done when loading the file to a result type, not its objects are used to generate output for response.

	* linebreak - The line break chars. Default '\n' .

	* engine - The render engine of the output page. A render engine is used to generate class or interface's definition based on the file's content. It also provide rules to help developers to create template files more easily. For now, the lua server page, master page, helper are all using *System.Web.PageRenderEngine*, so you can use things like `@data.Name`. And the static files like js, css are using a static render engine. Normally you don't need to set it.

	* asclass - The target resource's type, whether the content file should be a class. Default true. You also shouldn't touch it.

	When the page's config is loaded, it'd be converted to **System.Web.RenderConfig**'s object. A *RenderConfig* object could have a default *RenderConfig* object, so it will use the default object's settings if it don't have one.

	For a lua server page, its config's default should be **System.Web.LuaServerPageLoader**.*DefaultRenderConfig*, and the **LuaServerPageLoader**.*DefaultRenderConfig*'s default config should be **PageLoader**.*DefaultRenderConfig*, and its default config should be **IOutputLoader**.*DefaultRenderConfig*. So, it's a config chain to keep settings more organizable.

	Here is a tree map for the config chain :

	* **IOutputLoader**.*DefaultRenderConfig*
		* **PageLoader**.*DefaultRenderConfig*
			* **MasterPageLoader**.*DefaultRenderConfig*
				* master page's config
			* **EmbedPageLoader**.*DefaultRenderConfig*
				* embed page's config
			* **HelperPageLoader**.*DefaultRenderConfig*
				* helper page's config
			* **LuaServerPageLoader**.*DefaultRenderConfig*
				* lua server page's config
		* **StaticFileLoader**.*DefaultRenderConfig*
			* **JavaScriptLoader**.*DefaultRenderConfig*
				* javascript file's config, something like `//{noindent=true}`
			* **CssLoader**.*DefaultRenderConfig*
				* css file's config, something like `/*{noindent=true}*/`

	So, if we need the give all generated types a same namespace, we can set it like :

		System.Web.IOutputLoader.DefaultRenderConfig.namespace = "MyWebSite.Pages"

	And if we need all lua server pages use the same master page :

		System.Web.LuaServerPageLoader.DefaultRenderConfig.master = "/share/globalmaster.master"

	The page still can use page config to override these settings like :

		@{ master = "/share/anothermaster.master" }

	We'll see more details like how to create custom file type and render engine in a later topic.

* Logger settings - You may find more information about the log system in [System.Logger](https://github.com/kurapica/PLoop/wiki/logger). You only need to modify the log level in the *config.lua*.

		-- You may change the LogLevel to filter the messages
		System.Logger.DefaultLogger.LogLevel = System.LogLevel.Debug

* Session settings - We need two things to setup the session management :

	* ISessionIDManager - Used to retrieve session id from the request or create a session id and save it to the response(like cookie).

	* ISessionStorageProvider - A session will have an *Item* property used to contain serializable values. ISessionStorageProvider will be used to create, save, load those items for a session id.

	Those two are interfaces, so we need use classes that implement them.

		GuidSessionIDManager { CookieName = "MyWebSessionID", TimeOutMinutes = 10 }

	**GuidSessionIDManager** is used to create guid as session id and save them in the cookie with name *MyWebSessionID* and a time out.

		TableSessionStorageProvider()

	**TableSessionStorageProvider** is just use a in-memory table to manage the session items, it's very simple, and may only be used under web development.

	The details of the session will be discussed later.

* Routes - For now, you can ignore the first **Route** example in the *config.lua*, focus on two main routes :

		--- MVC route
		Route("/mvc/{Controller?}/{Action?}/{Id?}",
			function (request, controller, action, id)
				controller = controller ~= "" and controller or "home"
				action = action ~= "" and action or "index"
				return ('/controller/%scontroller.lua'):format(controller), {Action = action, Id = id}
			end
		)

		--- Direct map
		Route(".*.lsp", "r=>r.Url")

	Here we create two **Route** object to handle the request's url, the first parameter like `"/mvc/{Controller?}/{Action?}/{Id?}"` and `".*.lsp"` are used to match the request's url, the first defined route would be first used to match the url, when one match it, the other routes will be ignored.

	The url matching pattern is using lua regex string with some additional rules :

	* If the url ended with a suffix, the suffix would be converted to a tail match, as an example : ".*.lsp" -> "^.*%.[lL][sS][pP]$", so it will match a request that ask for a lua server page.

	* if the url contains items like `{name}`, the name in the braces is useless, just some tips. the item would be convert to `(%w+)`. If the item is `{name?}`, means the item is optinal, then it would be converted to `(%w*)`. If you want give a match for it, you can do it like `{id|%d*}`. If one item is optional, all items after it would optional, the seperate between them would also be optional, only one seperate can be used between those items. Normally it's used for mvc action maps :

		/{controller}/{action?}/{id?|%d*} -> ^/(%w+)/?(%w*)/?(%d*)$

	The second parameter of the Route creation is a **System.Callable** value, it means the value can be a function, a lambda expression or a callable object.

	When the url matched, the callable value would be called with the request object and matched strings(the whole url can be get by `request.Url`). The first return value would be an absolute path to the content file, and any other return values would be used when creating object of the type generated by the content file.

	So if the content file is a **System.Web.Controller**, it will use the `{Action = action, Id = id}` as an init-table to create object, so the object would know which action is called.

	For content file like lua server page, the request url is the file path, so we could use the `request.Url` directly.

	Be careful in some OS like CentOS, it's file system is case sensitive, it's better to keep your content file and directory's name in lower case, and use `string.lower` on the return value like :

		--- MVC route
		Route("/mvc/{Controller?}/{Action?}/{Id?}",
			function (request, controller, action, id)
				controller = controller ~= "" and controller or "home"
				action = action ~= "" and action or "index"
				return ('/controller/%scontroller.lua'):format(controller:lower()), {Action = action, Id = id}
			end
		)

		--- Direct map
		Route(".*.lsp", "r=>r.Url:lower()")

	More details about the **Route** would be discussed later.


MVC
====

For now, the [PLoop.System.Web][] provide the controller and view as :

* View - Use ".view" as suffix, it's use the **System.Web.PageRenderEngine**, so the render rules are the same like lua server pages.

* Controller - Controllers are classes inherited from **System.Web.Controller**, the file must be ".lua". The Controllers are also loaded by Routes. Here is the details :

	* Property :
		* Context - The current context object.
		* Action - The current action.

	* Method :
		* Render() - A placeholder for the body generated function, only used by the system itself. So just don't define another feature for the name.

		* Text(text) - Send the text to the response output.

		* View(path, ...) - Create a view page of the target path with rest arguments, then use the view page to generate response output.

		* Json(object, oType) - Serialize the object of oType to a json format string, and send the result to the response output.

		* Redirect(path) - Send a redirected path to the response output.

Look back to the Route part, when the MVC Route handle a request like `GET /mvc/home/index`, the file path should be '/controller/homecontroller.lua', and the controller's *Action* should be _index_. (case ignored)

To bind the *Action* to the controller's method, we must use `System.Web.__Action__` attribute, the usage of the attribute is like :

	-- Match all http method, the action is the method's name (case ignored)
	__Action__()

	-- Match the http get method, the action is the method's name (case ignored)
	__Action__ "GET"

	-- Match the http get method, and the action is index
	__Action__ "GET" "Index"

	-- Match all the http method, and the action is index
	__Action__ "Index"

Now, we can define the homecontroller.lua with *index* action :

	import "System"
	import "System.Web"

	class "HomeController" { Controller }

	__Action__ "Get"
	function HomeController:Index()
		local data = {
			{Name = "Ann", Age = 12},
			{Name = "King", Age = 32},
		}

		return self:View("homepage.view", { Data = data })
	end

The Index method would return a view page with an init-table, here is the definition of the homepage.view :

	@{ master = "mymaster.master" }

	@body{
		<table>
			<thead>
				<th>Name</th>
				<th>Age</th>
			</thead>
			<tbody>
			@for _, per in ipairs(self.Data) do
				<tr>
					<td>@per.Name</td>
					<td>@per.Age</td>
				</tr>
			@end
			</tbody>
		</table>
	}

The output should be :

	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<title>My web site</title>
			<!-- javascript placeholder -->
		</head>
		<body>
		<table>
			<thead>
				<th>Name</th>
				<th>Age</th>
			</thead>
			<tbody>
				<tr>
					<td>Ann</td>
					<td>12</td>
				</tr>
				<tr>
					<td>King</td>
					<td>32</td>
				</tr>
			</tbody>
		</table>
		</body>
	</html>

Here is another action to return a json string :

	__Action__ "Get" "Json"
	function HomeController:GetJson()
		local data = {
			Person("Ann", 12),
			Person("King", 32),
		}

		return self:Json(data)
	end

So `GET /mvc/home/json` would return :

	[{"Name":"Ann","Age":12},{"Name":"King","Age":32}]

The data module part is still under developing, coming soon.


Http Context
====

When the system process a request, a context must be created. A context contains all features that used to process the request:

A request object used to get request's information, a response object used to redirect url, send response output, also can have objects like session object used to track an unique client.

**System.Web.HttpContext** - the root class of http context :

* Static Property :
	* **Current** (**System.Web.HttpContext**, readonly) - Get the current http context. Normally, a http request should be processed in a lua coroutine, or the lua vm only run one request at a time.

* Property :
	* **Request** (**System.Web.HttpRequest**, readonly) - Get the http request object, the object contains the informations that the client send to the server
	* **Response** (**System.Web.HttpResponse**, readonly) - Get the http response object, output would be send to the client through the *HttpResponse*.
	* **Session** (**System.Web.HttpSession**, readonly) - Get the session object, the session is used to track the unique client across multiple requests. The session value would be nil until a context handler extend the **System.Web.ISessionRequired**, in a lua server page, you can set it in the page config like :

			@{ session = true }

	For a controller, you should define it like :

			class "HomeController" { System.Web.Controller, System.Web.ISessionRequired }

* Method :
	* **ProcessRequest**() - Process the request, normally this is be called by the server to start the process. As an example, in [NgxLua][]'s `nginx.conf`, the directive is `content_by_lua ' NgxLua.HttpContext():ProcessRequest() ';`, the **NgxLua.HttpContext** is a child context class of the **System.Web.HttpContext**, so the code create a new http context, and call it's *ProcessRequest* method to create response.


**System.Web.HttpRequest** - The root class of http request :

* Property :
	* **ContentLength** (**System.Number**, readonly) - Specifies the length, in bytes, of content sent by the client.

	* **ContentType** (**System.String**, readonly) - Gets the MIME content type of the incoming request.

	* **Cookies** (**System.Web.HttpCookies**, readonly) - Gets a collection of cookies sent by the client.

			@{
				-- The page's OnLoad will receive the context object
				-- Also you can use self.Context to access it
				function OnLoad(self, context)
					-- cookie is an object of System.Web.HttpCookie
					local cookie = context.Request.Cookies["username"]
					if cookie then
						-- Generate a log message
						Info("Process for user %s", cookie.Value)
					end
				end
			}

	* **Form** (**System.Table**, readonly) - Gets a collection of form variables, normally sended by a POST request.

			@{
				function OnLoad(self, context)
					local user = context.Request.Form["user"]

					if user then
						-- xxxxx
					end
				end
			}

	* **HttpMethod** (**System.Web.HttpMethod**, readonly) - Gets the HTTP data transfer method (such as GET, POST, or HEAD) used by the client.

	* **IsSecureConnection** (**System.Boolean**, readonly) - Gets a value indicating whether the HTTP connection uses secure sockets (that is, HTTPS).

	* **QueryString** (**System.Table**, readonly) - Gets the collection of HTTP query string variables like `GET /index.lsp?user=ann.

			@{
				function OnLoad(self, context)
					local user = context.Request.QueryString["user"]

					if user then
						-- xxxxx
					end
				end
			}

	* **RawUrl** (**System.String**, readonly) - Gets the raw URL of the current request.

	* **Root** (**System.String**, readonly) - Get the root path of the query document.

	* **Url** (**System.String**, readonly) - Gets information about the URL of the current request(with no uri args)

	* **Handled** (**System.Boolean**) - Whether the request is handled.

Those properies must be implemented by the class's child classes for specific web servers(For [NgxLua][], a **NgxLua.HttpRequest** is created based on [Openresty][]'s api).

**System.Web.HttpResponse** - The root class of http response :

* Property :
	* **ContentType** (**System.String**) - Gets or sets the HTTP MIME type of the output stream.

	* **RedirectLocation** (**System.String**) - Gets or sets the value of the Http Location header(Normally be set by **Redirect** method).

	* **RequestRedirected**  (**System.Boolean**) - Gets whether the request is been redirected.

	* **Write** (**System.Callable**) - Gets the response write function or callable object(normally a text writer or a function). You can use it to send out text directly.

			@ body {
				<p>
					@{
						self.Context.Response.Write("Here is a test message.\n")
					}
				</p>
			}

		Beware, since the code is handled as lua code, the system can't control the indents of those texts. Normally, there is no need to call it, leave it to the system.

	* **StatusCode** ([System.Web.HTTP_STATUS][]) - Gets or sets the HTTP status code of the output returned to the client. If we change the status code to a none **System.Web.HTTP_STATUS.OK (200)** value before the response head is send out, the page rendering would be ignored to save time. Also, redirect to a new url will change the status code, it also would avoid the page's rendering.

			@{
				function OnLoad(self, context)
					local user = context.Request.QueryString["user"]

					if not user then
						return context.Response:Redirect("/login.lsp")
					end
				end
			}

	* **Cookies** (**System.Web.HttpCookies**, readonly) - Gets a collection of cookies sent to the client, you can use it to add cookies in a simple way like :

			@{
				function OnLoad(self, context)
					-- When access a non-existed cookie, it's created automatically
					local cookie = context.Response.Cookies["ID"]

					cookie.Value = "TestUser1234"

					-- Set the expire time
					cookie.Expires = System.Date.Now:AddDays(30)

					-- Add more values to one cookie
					cookie.Values["Age"] = 33
					cookie.Values["Gender"] = "male"
				end
			}

* Method :
	* **Redirect**(url[, statuscode=**System.Web.HTTP_STATUS.MOVED**]) - Redirects the client to a new URL.

The **ContentType**, **RedirectLocation**, **Write** and **StatusCode** properties must be implemented by child classes. The Write would be a function or a **System.IO.TextWriter** object(with __call setting), in the example, we used the **System.IO.FileWriter** and a **DirectWriter**. In [NgxLua][], it's a function based on the `ngx.print`.


Relative Path & Absolute Path
====

In the above examples, we use paths for master, helper, code, view and etc. Here are some details about the path :

* The root path can be get by HttpRequest.Root.

* Path started with "/" is an absolute path, combine the root path and the absolute path is the target file's path.

* Path not started with "/" is a relative path, combine current file's directory and the relative path is the target file's path.


Encode & Decode
====

There are four method defined in *System.Web* to help encode & decode for web development :

* System.Web.UrlEncode(text) - Used to encode the url for safely, take an example : `UrlEncode("_&^") -> _%26%5E`
* System.Web.UrlDecode(text) - Decode the encoded url.
* System.Web.HtmlEncode(text[, encoding]) - Encode the text like : `HtmlEncode("<tes&t>") -> &lt;tes&amp;t&gt;`, the default encoding is UTF8, and for now, only UTF-8 is supported, so there is no need to set it just for now.
* System.Web.HtmlDecode(text[, encoding]) - Decode the encoded text, also for now, only UTF-8 supported.


System.Web.IHttpContextHandler And The Request's Process
====

When use the context's **ProcessRequest** to start the process of the request, it is split to five phases which defined in **System.Web.ContextProcessPhase** :

1. **InitProcess**    - Init the request process
2. **GenerateHead**   - Generate the reponse head
3. **HeadGenerated**  - Response head generated
4. **GenerateBody**   - Generate the response body
5. **BodyGenerated**  - Response body generated

The **System.Web.ContextProcessPhase** is a flag enum, so you can use values like `System.Web.ContextProcessPhase.InitProcess + System.Web.ContextProcessPhase.HeadGenerated`.

The handlers for those phases must extend the **System.Web.IHttpContextHandler** interfaces :

* Property :
	* **CheckRequestHandled** (**System.Boolean**) - The handler would check whether the request is handled, only for init process phase, if the request is handled and the CheckRequestHandled is true, the handler won't be use. Default false.

	* **ProcessPhase** (**System.Web.ContextProcessPhase**) - The handler's process phase. Default `System.Web.ContextProcessPhase.GenerateHead + System.Web.ContextProcessPhase.GenerateBody`.

	* **AsGlobalHandler** (**System.Boolean**) - Whether the context handler is used as global handler. Default false.

* Method :
	* **RegisterPhases**() - Register self to current context process phases. Normally this is called by route objects. You don't need to use it.

* Required-Method :
	* **Process**(context, phase) - Process the context in a phase.
		* context (**System.Web.HttpContext**) - The current http context.
		* phase (**System.Web.ContextProcessPhase**) - The current process phase.

The required method must be implemented, it's easy to create an handler from the interface's anonymous class like :

	import "System.Web"

	Route ("/testhandler",

		IHttpContextHandler(function(self, context, phase)
			if phase == ContextProcessPhase.GenerateHead then
				context.Response.ContentType = "text/plain"
			else
				context.Response.Write("This is only a test for binding handler to an url")
			end
		end)
	)

Here a handler is created for `GET /testhandler` request.


There are two type of the context handlers : global and non-global.

* Global handlers: can only register the **InitProcess**, **HeadGenerated** and **BodyGenerated** phases. The global handlers would handle all requests processed by any workers in one server, so you should be careful with the side effect of the process method.

* Non-Global handlers: can register all phases and will be un-registered when the context process is finished. Those handlers are normally be managed by the routes, the router would register the handler when it match the request's url.

When a request `Get /index.lsp` is send to the sever, the sever create a http context object and then call its **ProcessRequest** method to start the whole process. Objects like routes are all global context handlers.

1. InitProcess : Start the initialize, like read query arguments, create cookies, and etc. The main purpose in the phase is to find handlers for the *GenerateHead* and *GenerateBody* phase, normally this is be done by the **Route**s.

	For the request, the route `Route(".*.lsp", "r=>r.Url")` would be used, and it will load the *index.lsp*, it'd be loaded as a class that extend the **System.Web.IHttpContextHandler**, and the route will create an object of the class, the object is also context handler with `ProcessPhase = ContextProcessPhase.GenerateHead + ContextProcessPhase.GenerateBody`, the route will register the object for the next phases.

2. GenerateHead : The handler of this phase would be supposed to generated contents for response heads, like response's content type, status code, cookies and etc. For the lua server page's object, it's **OnLoad** method would be called with the current context object, so it can check the querystring in the request and generate datas like :

		class "index" {}

		function index:OnLoad(context)
			-- Get data from querystring
			local id = context.Request.QueryString["id"]

			if not id then
				-- Redirect to other pages
				return context.Response:Redirect("/error.lsp?err=noid")
			end

			-- Set cookies
			context.Response.Cookies["ID"].Value = id
			context.Response.Cookies["ID"].Expires = System.Date.Now:AddMinutes(10)

			-- Load data from some where
			self.Data = DB.LoadFromID( id )
		end

3. HeadGenerated : In the phase, we could convert the cookie datas to response head, check the changes after **GenerateHead** phase and etc. In the [NgxLua][], the save cookie handler could be :

		-- Write cookie to response
		-- Using Auto anonymous class of interface to create the handler
		IHttpContextHandler {
			ProcessPhase = ContextProcessPhase.HeadGenerated,

			Process = function(self, context, phase)
				local cookies = context.Response.Cookies
				if next(cookies) then
					local cache = {}
					for name, cookie in pairs(cookies) do
						table.insert(cache, tostring(cookie))
					end
					ngx.header['Set-Cookie'] = cache
				end
			end,
		}

4. GenerateBody : If the response's StatusCode is still 200(OK), the handlers of the phase would be called. So it's time to call the lua server page object's **Render** method to generated output for response's body.

5. BodyGenerated : The final part of the process, the response is closed, you can do things like save session datas, clear resources and etc.

When the process is done, the non-global handlers will be released, so the lua VM can collect it then.


System.Web.Route
====

A Route is a map from the request url to the disk file path, it's registered to the **InitProcess** phases, so it can register handlers for other phases at the **InitProcess**.

Here is the constructors to create route objects :

	Route(url, routeHandler)
	Route(url, httpMethod, routeHandler)
	Route(url, caseIgnored, routeHandler)
	Route(url, httpMethod, caseIgnored, routeHandler)

	Route(url, contextHandler)
	Route(url, httpMethod, contextHandler)
	Route(url, caseIgnored, contextHandler)
	Route(url, httpMethod, caseIgnored, contextHandler)

* url (**System.String**) - The lua regex string, used to match the whole request url, beside the normal lua match mechanism, there are some special rules for it :

	* If the url ended with a suffix, the suffix would be converted to a tail match, as an example : ".*.lsp" -> "^.*%.[lL][sS][pP]$", so it will match a request that ask for a lua server page.

	* if the url contains items like `{name}`, the _name_ in the braces is useless, just like some tips. the item would be convert to `(%w+)`. If the item is `{name?}`, means the item is optinal, then it would be converted to `(%w*)`. If you want give a match for it, you can do it like `{id|%d*}`. If one item is optional, all items after it would optional, the seperate between them would also be optional, only one seperate can be used between those items. Normally it's used for mvc action maps :

			/{controller}/{action?}/{id?|%d*} -> ^/(%w+)/?(%w*)/?(%d*)$

* httpMethod (**System.Web.HttpMethod**, default **HttpMethod.All**) - Used to match the request's http method. Here is the list of the HttpMethod :
	* ALL
	* OPTIONS
	* GET
	* HEAD
	* POST
	* PUT
	* DELETE
	* TRACE
	* CONNECT

* caseIgnored (**System.Boolean**, default true) - Whether ignored the request url's case.

* routeHandler (**System.Callable**) -  Used to convert the request url to the disk file's path. The value could be a function, a lambda expression, or a callable object. The routeHandler would receive the request object and the captures, and is required to return the path of the target file with arguments for object creation. The result of the file must be a class extend the **System.Web.IHttpContextHandler** or a context hanlder, otherwise 404 would be send out.

* contextHandler (**System.Web.IHttpContextHandler**) - The handler would always existed in the memory. When a request came, and the route match the url, the handler would be registered to the phases, and will be un-registered at the final phase.

The the routeHandler is used to load handler classes from the file, and the contextHandler is just the handler would be registered by the route, only one can be used in a route.


Take the example in `Example/config.lua` :

	--- Bind a context handler to an url
	Route("/testhandler",

		IHttpContextHandler(function(self, context, phase)
			if phase == ContextProcessPhase.GenerateHead then
				context.Response.ContentType = "text/plain"
			else
				context.Response.Write("This is only a test for binding handler to an url")
			end
		end)
	)

	--- MVC route
	Route("/mvc/{Controller?}/{Action?}/{Id?}",

		function (request, controller, action, id)
			controller = controller ~= "" and controller or "home"
			action = action ~= "" and action or "index"

			return ('/controller/%sController.lua'):format(controller), {Action = action, Id = id}
		end
	)

	--- Direct map
	Route(".*.lsp", "r=>r.Url")

Here is some details about it :

* The first defined **Route** would be the first registered to the **InitProcess** phase, so it would be first used to match the request url, it the route match the request url, it'll modified the `request.Handled = true`, so others routes will be skipped.

* The routehandler would receive the request object and captures, it's required to return the taget context handler's file path, and also can return some values as the parameters to construct the context handler, for the MVC route, the second return value is a table, so it would used as the init-table if the context handler class support it. The created context handler would know the action and the id from it's _Action_ and _ID_ properties.

* For the context handler, the *IHttpContextHandler* is an one-required method interface, and it's default **ProcessPhase** is `GenerateHead + GenerateBody`, so you only need to use a function to create the handler of the interface. You must check the phase in the function, since the **GenerateHead** and **GenerateBody** are phases seperated by **HeadGenerated**.


Cookie
====

The request's *Cookies* is a name-value collections (just a table) that contains the cookie pairs send by the client's browser. So it can be used like :

		class "index" {}

		function class:OnLoad(context)
			local id = context.Request.Cookies["ID"]
		end

Save a cookie is a little different, The **HttpResponse.Cookies** is a **System.Web.HttpCookies** which is a collection of **System.Web.HttpCookie**. Using a cookie name in it would create or get the created cookie, so you can use it like :

		context.Response.Cookies["ID"].Value = "TestUser1234"

**System.Web.HttpCookie** :

* Property :

	* **Domain** (**System.String**) - Gets or sets the domain to associate the cookie with.

	* **Expires** (**System.Date**) - Gets or sets the expiration date and time for the cookie.

	* **MaxAge** (**System.NumberNil**) - Gets or sets the max age for the cookie.

	* **HasKeys** (**System.Boolean**) - Gets a value indicating whether a cookie has subkeys.

	* **HttpOnly** (**System.Boolean**) - Gets or sets a value that specifies whether a cookie is accessible by client-side script.

	* **Name** (**System.String**) - Gets or sets the name of a cookie.

	* **Path** (**System.String**) - Gets or sets the virtual path to transmit with the current cookie.

	* **Secure** (**System.Boolean**) - Gets or sets a value indicating whether to transmit the cookie using Secure Sockets Layer (SSL)--that is, over HTTPS only.

	* **Value** (**System.String**) - Gets or sets an individual cookie value.

	* **Values**  (**System.Table**) - Gets a collection of key/value pairs that are contained within a single cookie object.

You can set the expires date like :

		context.Response.Cookies["ID"].Expires = System.Date.Now:AddDays(30)

Also sub-items can be added like :

		context.Response.Cookies["ID"].Values["Age"] = 33
		context.Response.Cookies["ID"].Values["Gender"] = "male"


Session
====

The http session is used to track a unique client, for now, only works when the client browser has turn on the Cookie.

When a http request send to the server, and a context handler has extened the **System.Web.ISessionRequired** interface (for pages like lsp, set `session=true` in the page config would do it), the system would create the session object for the conversation.

The session's type is **System.Web.HttpSession** :

* Property :
	* **SessionID** (**System.String**, readonly) - Gets the unique identifier for the session.

	* **IsNewSession** (**System.Boolean**) - Gets a value indicating whether the session was created with the current request.

	* **Item** (**System.Table**, readonly) - Gets a value storage table. With this, you can share values between several request for one client like :

			@{ session = true }

			@{
				function OnLoad(self, context)
					local sitem = context.Session.Item

					if sitem["uservisit"] then
						sitem["uservisit"] = sitem["uservisit"] + 1
					else
						sitem["uservisit"] = 1
					end
				end
			}

	* **Timeout** (**System.Date**) - Gets and sets the date time, allowed the next request access the session.

	* **Canceled** (**System.Boolean**) - Whether the current session is canceled. (Boolean)


The are two important interface should be implemented to support the session system.

* **ISessionIDManager** - Used to provide features to get session id from the request, create new session id, save session id to the response and etc. For now, only one session id manager would existed.
	* Property :
		* **TimeOutMinutes** (**System.Number**, default 30) - The minute count before session time out.

	* Required Method :
		* **GetSessionID**(context) - Gets the session identifier from the context of the current HTTP request.

		* **CreateSessionID**(context) - Creates a unique session identifier.

		* **RemoveSessionID**(context) - Deletes the session identifier in the current HTTP response.

		* **SaveSessionID**(context, session) - Saves the session to the HTTP response.

		* **ValidateSessionID**(id) - Validate the session id.

* **ISessionStorageProvider** - Used to provide features to save/get/remove session items from a storage(memeory, cache server, db server and etc). For now, only one session storage provider would existed.
	* Required Method :
		* **Contains**(id) - Whether the session ID existed in the storage.

		* **GetItems**(id) - Get session item.

		* **RemoveItems**(id) - Remove session item.

		* **CreateItems**(id, timeout) - Create new seesion item with timeout.

		* **SetItems**(id, item, timeout) - Update the item with current session data.

		* **ResetItems**(id, timeout) - Update the item's timeout.


In the current version, a **system.Web.GuidSessionIDManager** is provide to manage the session id, it'll generat a guid for each session, and save the session id to the cookie with a specific name. You can create one in your config file like :

	-- Set the cookie name and the time out of the session
	GuidSessionIDManager { CookieName = "MyWebSessionID", TimeOutMinutes = 10 }

In this beta version, a TableSessionStorageProvider is provide to manage the items of the sessions. It's use some lua tables to manage those session items, so, when you restart the server, all would be loose. There are also no real time out clear for it. So this is only a simulator used when building the web sites. You can defined in the config file like :

	local storage = {}
	local timeouts = {}

	TableSessionStorageProvider(storage, timeouts)


The Rendering System
====

In the previous topics, besides the global context handlers, we can see there are two main context handlers - controller and lua server page.

Let's focus on output for html page, the controller will use view page to generate output, the lua server page would use itself. The rendering system are focused on how to generate output like html pages.

The rendering system is designed with three parts :

* **System.Web.IHttpOutput** - The interface for page classes that used to generate output.
	* Property :
		* **Context** (**System.Web.HttpContext**) - The current http context.

	* Method :
		* **OnLoad**(context) - The method should be called during **GenerateHead** phase, need be applied by the users(defined in itself or its class).

		* **Render**(write, indent) - The method should be called during **GenerateBody** phase, normally created by render engines.

			* _write_ (**Syste.Callable**) - the value is used to send out the generated contents, this is the value of `context.Response.Write`.

			* _indent_ (**System.String**) - the indent for the file, used to generated more readable outputs.

		* **RenderAnother**(url, indent, default, ...) - Generate the output of other url, load the url should get a class extend the **System.Web.IHttpOutput**(so the embed pages), if it not existed, the default would be used if existed. This is normally used to get output of embed pages or embed js, css files.

* **System.Web.IOutputLoader** - The interface for resource loaders to generate classes of **System.Web.IHttpOutput**, it also added the render engine system to easy the creation of page rules.

	* Static Property
		* **DefaultRenderConfig** (**System.Web.RenderConfig**) - The default config for the page's loading, this is introduced in the configuration part.

	* Property
		* **Path** (**System.String**) - The target file's path.

		* **Target** (**System.String**) - The resource file's result.

	* Method
		* **LoadRelatedResource**(path) - Load a related resouce, normally the resource should be a super class or an interface. And if the page is set `reload=true`, when access the page, its related paths would be checked for an update.

		* **Load**(path) - Override the **System.IO.Resource**'s **OnLoad** method, in the method, the page's config would be first loaded, the engine in it (remember the config chain, the engine normally is set in its resource loader's **DefaultRenderConfig**) would be used to help the creation.

* **System.Web.IRenderEngine** - The interface for render engines. It extend the **System.Collections.Iterable** with two override required method :
	* Method :
		* **Init**(loader, config) - Init the engine with page loader and the page config.
			* loader (**System.Web.IOutputLoader**) - the resource loader, the engine can get the target and file's path in it.
			* config (**System.Web.RenderConfig**) - the page's config

		* **ParseLines**(lines) - Parse the lines and yield all content with type.
			* lines (iterator of the file content) - Since those files are used to generate html output, scan the file line by line is a good way for analysis. The interface provide a default implement of the method like :

					function ParseLines(self, lines)
						yield(RenderContentType.MixMethodStart, "Render")

						for line in lines do
							line = line:gsub("%s+$", "")

							yield(RenderContentType.StaticText, line)
							yield(RenderContentType.NewLine)
						end

						yield(RenderContentType.MixMethodEnd)
					end

				This's likely to give a definition like

					function Render(self, write, indent)
						write(indent)
						write("some line text")
						write("\n")
						write(indent)
						write("next line text")
						write("\n")
						write(indent)
						write("last line text")
					end

				The method is used to directly output the file's content, so files like js, css are using the **System.Web.IRenderEngine** as their render engine directly([PLoop][] support the anonymous class of the interface), when a resource loader is calling it, using yield will make sure it would generate many results, each result is a tag with contents, and the resource loader would choose how to handle it based on the tags.

The idea here is make sure things like indent, linebreak and other settings in the page's config can be handled by the resource loader, and the render engine should focus on how to generate the output contents.


Custom render engine and resouce loader
====

If you don't wanna learn how to create your own render engine or resource loader, you can skip this topic.

Before the start we should learn the **Sytem.Web.RenderConfig** and **System.Web.RenderContentType** .

* **Sytem.Web.RenderConfig** - the config of the page files. We have learn the config chain in the previous topics. The config objects's class is the **Sytem.Web.RenderConfig**.

	* Property

		* **Default** (**System.Web.RenderConfig**) - The default config object, the object would use its default config's value if it don't have one.

		* **namespace** (**System.String + System.NameSpace**) - The namespace of the page

		* **master** (**System.String**) - The master (super class page) of the page

		* **helper** (**System.String**) - The helper (extend interface page) of the page

		* **code** (**System.String**) - The code file, the property don't use its default config's value

		* **context** (**System.Boolean**) - Whether the page extend **System.Web.IHttpContext**

		* **session** (**System.Boolean**) - Whether the page extend **System.Web.ISessionRequired**

		* **reload** (**System.Boolean**) - Whether reload the file when modified in non-debug mode

		* **encode** (**System.Boolean**) - Whether auto encode the output with HtmlEncode(only for expressions)

		* **noindent** (**System.Boolean**) - Whether discard the indent of the output. This is be done when the feature is defined.

		* **nolinebreak** (**System.Boolean**) - Whether discard the line breaks of the output. Ths is be done when the feature is defined.

		* **linebreak** (**System.String**, default `"\n"`) - The line break chars.

		* **engine** (**-System.Web.IRenderEngine**) - The render engine class of the output page.

		* **asclass** (**System.Boolean**, default true) - Whether the target resource's type is class.

	* Constructor

		* **RenderConfig([default]) - Generate a new render config and set it's default config if existed.
			* default (**Sytem.Web.RenderConfig**) - The default render config

	The class has an attribute `System.__InitTable__`, so it's object can be called with a init-table to change it's properties. So, let's see the definition of **System.Web.PageLoader** which is the super class of **System.Web.LuaServerPageLoader** :

		class "PageLoader" (function (_ENV)
			extend "IOutputLoader"

			__Static__()
			property "DefaultRenderConfig" { Set = false,
				Default = RenderConfig(IOutputLoader.DefaultRenderConfig) {
					engine = PageRenderEngine
				}
			}
		end)

	So the **PageLoader.DefaultRenderConfig**'s default config is **IOutputLoader.DefaultRenderConfig**, and it set the *engine* to **System.Web.PageRenderEngine**, things like web parts, mixed method are all rules defined in the engine.

* **System.Web.RenderContentType** - This is an enum type, it defined the tags that used to generate definitions. When the engine process the file's lines, it will yield many tags with other values, the tags will be used to decide how to handle the other values.

	* **StaticText**, content - the content is static text, and will be send out directly.

	* **NewLine** - here is a newline, if not set `nolinebreak=true`, the newline would be send out. Also there are several operations would be done with it, like after a newline, the indent should be send out before new contents.

	* **LuaCode**, content - the content is a lua code line.

	* **Expression**, content - the content is a lua expression.

	* **EncodeExpression**, content - the content is a lua expression and must be encoded.

	* **MixMethodStart**, name, params - start the definition of a mixed method of the *name* with *params*, some other parameters like *write* and *indent* would be added to it by **System.Web.IOutputLoader**, so it's not a common lua function, if the engine want to define a new lua function, it can use the **LuaCode**.

	* **MixMethodEnd** - End the definition of the preivous mixed method. This only add an `end` to the definition.

	* **CallMixMethod**, name, params, default - Call a mixed method of the *name* with *params*, if the mixed method don't existed, the *default* would be send out.

	* **RenderOther**, url, params, default - Call the **RenderAnother** method with *url*, *params* and *default*, other arguments of the **RenderAnother** will be given by the **System.Web.IOutputLoader**.


Now, we want to create a render engine to analysis page files with content like :

	html
		head
			title
				> my web site
		body
			div #mainDiv .center
				p #random style='width:100px'
					> random is {{ math.random(10000) }} pts

The output supposed to be

	<html>
		<head>
			<title>my web site</title>
		</head>
		<body>
			<div id="mainDiv" name="mainDiv" class="center">
				<p id="random" name="random" style='width:100px'>random is 1233 pts</p>
			</div>
		</body>
	</html>

First we create a class used to generate the result as static text :

	class "Index" { System.Web.IContextOutputHandler }

	class "Index" [[
		function Render(self, _write, _indent)
			_write(_indent) _write[=[<html>]=]
			_write("\n")
			_write(_indent) _write[=[	<head>]=]
			_write("\n")
			_write(_indent) _write[=[		<title>my web site</title>]=]
			_write("\n")
			_write(_indent) _write[=[	</head>]=]
			_write("\n")
			_write(_indent) _write[=[	<body>]=]
			_write("\n")
			_write(_indent) _write[=[		<div id="mainDiv" name="mainDiv" class="center">]=]
			_write("\n")
			_write(_indent) _write[=[			<p id="random" name="random" style='width:100px'>random is 1233 pts</p>]=]
			_write("\n")
			_write(_indent) _write[=[		</div>]=]
			_write("\n")
			_write(_indent) _write[=[	</body>]=]
			_write("\n")
			_write(_indent) _write[=[</html>]=]
		end
	]]

We don't use **System.Web.IHttpOutput** here, because only class that extend **System.Web.IHttpContextHandler** can be used to generate response, the **System.Web.IHttpOutput** is only used to generate text output.

So a page class need to extend the two interfaces, and the system provide the **System.Web.IContextOutputHandler** for it.

Beware, using the **System.Web.IOutputLoader** load the page file would only create features extend the **System.Web.IHttpOutput**, so the Lua server page's loader's definition is :

	namespace "System.Web"

	__ResourceLoader__"lsp"
	class "LuaServerPageLoader" (function (_ENV)
		inherit "PageLoader"

		__Static__()
		property "DefaultRenderConfig" { Set = false, Default = RenderConfig(PageLoader.DefaultRenderConfig) }

		function Load(self, path)
			local target = Super.Load(self, path)

			-- Add the IContextOutputHandler interface to it
			if target then class(target, { IContextOutputHandler }) end

			return target
		end
	end)

The [PLoop][] support many definition styles, so when we generate a definition from the page file, we'd better use string as the definition. For the example, we only need to create a **Render** method in it. In the **Render** method, we write out the indent, the content and the linebreak to generate the response.

Things like indents and linebreaks are very common, and handle them in engine would cause a lot troubles. So the common part have been done in the **System.Web.IOutputLoader**, in an engine, we should only care the content and the content's type. So, we can define the engine for it (don't mind the file's content) :

	import "System.Web"

	class "WaterFallEngine"(function (_ENV)
		extend "IRenderEngine"

		local yield = coroutine.yield

		function ParseLines(self, lines)
			local line = lines()

			-- function Render(self, ...)
			yield(RenderContentType.MixMethodStart, "Render")

			-- write(content)
			yield(RenderContentType.StaticText, [[<html>]])
			yield(RenderContentType.StaticText, [[	<head>]])
			yield(RenderContentType.StaticText, [[		<title>my web site</title>]])
			yield(RenderContentType.StaticText, [[	</head>]])
			yield(RenderContentType.StaticText, [[	<body>]])
			yield(RenderContentType.StaticText, [[		<div id="mainDiv" name="mainDiv" class="center">]])
			yield(RenderContentType.StaticText, [[			<p id="random" name="random" style='width:100px'>random is 1233 pts</p>]])
			yield(RenderContentType.StaticText, [[		</div>]])
			yield(RenderContentType.StaticText, [[	</body>]])
			yield(RenderContentType.StaticText, [[</html>]])

			-- end
			yield(RenderContentType.MixMethodEnd)
		end
	end)

As you can see, using yield to return tags and content, it's just like to define a function, the details like indents and linebreaks are ignored.

With the engine, we can define a new resouce loader :

	import "System"
	import "System.IO"
	import "System.Web"

	__ResourceLoader__"wf"
	class "WaterFallLoader" (function (_ENV)
		inherit "LuaServerPageLoader"

		__Static__()
		property "DefaultRenderConfig" { Set = false, Default = RenderConfig(LuaServerPageLoader.DefaultRenderConfig) {
				engine = WaterFallEngine
			}
		}
	end)

Here we define a resource loader for ".wf" suffix files. When the two classes is loaded(you can add them in the `config.lua` or use `require` to load them, we can access "*.wf" files and get the responses, although the engine only generate the same result.

Now, let's recode the engine to meet the requirement.

	import "System.Web"

	class "WaterFallEngine"(function (_ENV)
		extend "IRenderEngine"

		local yield = coroutine.yield

		local NOT_CHILD = 0
		local NODE_ELE = 1
		local TEXT_ELE = 2

		local function parseLine(self, lines, chkSpace, isFirstChild)
			line = self.CurrentLine or lines()

			self.CurrentLine = nil

			if not line then return NOT_CHILD end
			line = line:gsub("%s+$", "")

			local space, tag, ct = line:match("^(%s*)(%S+)%s*(.*)$")

			if tag == ">" then
				-- It's a text element
				-- for "random is {{ math.random(10000) }} pts"

				local startp = 1
				local expSt, expEd = ct:find("{{.-}}", startp)

				while expSt do
					-- "random is " is static text
					yield(RenderContentType.StaticText, ct:sub(startp, expSt - 1))

					-- math.random(10000) is an expression
					yield(RenderContentType.Expression, ct:sub(expSt + 2, expEd - 2))

					startp = expEd + 1
					expSt, expEd = ct:find("{{.-}}", startp)
				end

				-- The remain " pts" is also static text
				yield(RenderContentType.StaticText, ct:sub(startp))

				return TEXT_ELE
			end

			-- Check if it's a child node
			if not chkSpace or #space > #chkSpace then
				-- This is a node
				-- for "		div #mainDiv .center"

				-- If the node is a child node, we need add a new line
				if chkSpace then
					if isFirstChild then
						yield(RenderContentType.NewLine)
					end

					-- "		" space is static text, don't forget it
					yield(RenderContentType.StaticText, space)
				end

				-- Get id, class and other settings
				local id, cls = "", ""
				local cache = { tag }

				-- Get and remove id from ct
				ct = ct:gsub("#(%w+)", function(w) id = w return "" end)
				if #id > 0 then
					table.insert(cache, ([[id="%s" name="%s"]]):format(id, id) )
				end

				-- Get and remove class from ct
				ct = ct:gsub("%.(%w+)", function(w) cls = cls .. w .. "," return "" end)
				if #cls > 0 then
					table.insert(cache, ([[class="%s"]]):format(cls:sub(1, -2)) )
				end

				-- Get the remain
				ct = ct:gsub("^%s*(.-)%s*$", "%1")
				if ct and #ct > 0 then
					table.insert(cache, ct)
				end

				-- "div #mainDiv .center" -> StaticText: <div id="mainDiv" name="mainDiv" class="center">
				yield(RenderContentType.StaticText, "<" .. table.concat(cache, " ") .. ">")

				-- check the next line
				local firstNode = true

				while true do
					local ret = parseLine(self, lines, space, firstNode)

					firstNode = false

					if ret == TEXT_ELE then
						-- Close the tag
						yield(RenderContentType.StaticText, "</" .. tag .. ">")

						-- Generate a new line
						yield(RenderContentType.NewLine)

						return NODE_ELE
					elseif ret == NODE_ELE then
						-- We have a child node, just keep parsing
					else
						-- we meet the end of the node
						if #space > 0 then
							yield(RenderContentType.StaticText, space)
						end

						-- Close the tag
						yield(RenderContentType.StaticText, "</" .. tag .. ">")

						-- Generate a new line
						yield(RenderContentType.NewLine)

						return NODE_ELE
					end
				end
			else
				-- This is not a child node, so return to close the previous node
				self.CurrentLine = line

				return NOT_CHILD
			end
		end

		function ParseLines(self, lines)
			-- function Render(self, ...)
			yield(RenderContentType.MixMethodStart, "Render")

			parseLine(self, lines)

			-- end
			yield(RenderContentType.MixMethodEnd)
		end
	end)

Don't forget to add a `Route(".*.wf", "r=>r.Url")` in the config.lua, otherwise the system can't map the requests to the ".wf" files.



[nginx]: https://www.nginx.com/ "Nginx"
[Openresty]: https://github.com/openresty/lua-nginx-module/ "Openresty"
[PLoop]: https://github.com/kurapica/PLoop/ "Prototype Lua Object-Oriented Program"
[NgxLua]: https://github.com/kurapica/NgxLua/ "An implementation for the Openresty"