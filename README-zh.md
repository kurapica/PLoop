# 基于原型的Lua面向对象系统

**PLoop**是纯Lua的面向对象系统，它提供的语法规则类似于C#，支持Lua 5.1及以上版本，也支持luajit。也可以用于类似[OpenResty](https://github.com/openresty/lua-nginx-module)这样的多线程平台。

**PLoop**本身也提供了类似协程池，集合，序列化等通用功能。除了提供类型定义和通用类型外，**PLoop**也针对项目开发提供了诸如代码管理，类型验证等常用功能。

**更详细的文档请阅读[Docs](https://github.com/kurapica/PLoop/tree/master/Docs)**

## 目录

* [安装](#安装)
* [从使用集合开始](#从使用集合开始)
	* [List的创建](#list的创建)
	* [List的方法](#list的方法)
	* [动态列表](#动态列表)
	* [List的遍历](#list的遍历)
	* [List的排序](#list的排序)
	* [Dictionary的创建](#dictionary的创建)
	* [Dictionary的方法](#dictionary的方法)
	* [Dictionary的遍历](#dictionary的遍历)
	* [动态字典](#动态字典)
* [特性(Attribute)和协程池(Thread Pool)](#特性attribute和协程池thread-pool)
* [拼写错误检查](#拼写错误检查)
	* [读取不存在的全局变量](#读取不存在的全局变量)
	* [写非法全局变量](#写非法全局变量)
	* [访问不存在的对象字段](#访问不存在的对象字段)
* [类型验证](#类型验证)
* [enum 枚举类型](#enum-枚举类型)
	* [System.Enum](#systemenum)
* [struct 结构体](#struct-结构体)
	* [Custom 自定义结构体](#custom-自定义结构体)
	* [Member 成员结构体类型](#member-成员结构体类型)
	* [Array 数组结构体](#array-数组结构体)
	* [Hash 键值对结构体](#hash-键值对结构体)
	* [使用table来定义结构体](#使用table来定义结构体)
	* [减少验证消耗](#减少验证消耗)
	* [联合类型](#联合类型)
	* [子类型](#子类型)
	* [System.Struct](#systemstruct)
	* [System.Member](#systemmember)
* [Class 类](#class-类)
	* [类方法和对象方法](#类方法和对象方法)
	* [元数据和对象构造](#元数据和对象构造)
	* [超类和继承](#超类和继承)
	* [System.Class](#systemclass)
	* [类的多重版本](#类的多重版本)
	* [扩展方法](#扩展方法)
* [Interface 接口](#interface-接口)
	* [System.Interface](#systeminterface)
	* [Interface的匿名类](#interface的匿名类)
	* [接口的所需类](#接口的所需类)
* [Event 事件](#event-事件)
	* [事件处理方法变更的处理](#事件处理方法变更的处理)
	* [静态事件](#静态事件)
	* [超类事件](#超类事件)
	* [System.Event](#systemevent)
* [Property 属性](#property-属性)
	* [get/set](#getset)
	* [getmethod/setmethod](#getmethodsetmethod)
	* [property-throw](#property-throw)
	* [field & default](#field--default)
	* [default factory](#default-factory)
	* [property-event](#property-event)
	* [property-handler](#property-handler)
	* [static property](#static-property)
	* [自动绑定](#自动绑定)
	* [超类属性](#超类属性)
	* [索引属性](#索引属性)
	* [Get/Set行为修饰](#getset行为修饰)
	* [System.Property](#systemproperty)
* [继承和优先级](#继承和优先级)
* [使用其他定义形式](#使用其他定义形式)
	* [使用字符串作为定义体](#使用字符串作为定义体)
	* [使用table作为定义体](#使用table作为定义体)
* [命名空间和匿名类型](#命名空间和匿名类型)
	* [System.Namespace](#systemnamespace)
* [环境](#环境)
	* [隔离代码](#隔离代码)
	* [分享类型](#分享类型)
	* [特性和全局函数](#特性和全局函数)
	* [使用命名空间作为调用者](#使用命名空间作为调用者)
	* [全局变量的读取](#全局变量的读取)
	* [自动缓存机制](#自动缓存机制)
* [重载](#重载)
	* [this和构造体方法](#this和构造体方法)
	* [使用超类方法处理未处理的参数样式](#使用超类方法处理未处理的参数样式)
	* [System.Variable](#systemvariable)
	* [申明变量的简易版本](#申明变量的简易版本)
* [Throw Exception 异常处理](#throw-exception-异常处理)
* [模板类](#模板类)
* [System.Module](#systemmodule)
	* [child-modules 子模组](#child-modules-子模组)
* [Attribute 特性系统](#attribute-特性系统)
	* [System.IAttribute](#systemiattribute)
	* [System.IInitAttribute 初始化特性](#systemiinitattribute-初始化特性)
	* [System.IApplyAttribute 应用特性](#systemiapplyattribute-应用特性)
	* [System.IAttachAttribute 附着特性](#systemiattachattribute-附着特性)
	* [System特性](#system-attributes)
		* [`__Abstract__`](#__abstract__)
		* [`__AutoCache__`](#__autocache__)
		* [`__AnonymousClass__`](#__anonymousclass__)
		* [`__AutoIndex__`](#__autoindex__)
		* [`__Arguments__`](#__arguments__)
		* [`__Async__`](#__async__)
		* [`__Base__`](#__base__)
		* [`__Default__`](#__default__)
		* [`__Delegate__`](#__delegate__)
		* [`__EventChangeHandler__`](#__eventchangehandler__)
		* [`__Final__`](#__final__)
		* [`__Flags__`](#__flags__)
		* [`__Get__`](#__get__)
		* [`__Indexer__`](#__indexer__)
		* [`__Iterator__`](#__iterator__)
		* [`__Namespace__`](#__namespace__)
		* [`__NoNilValue__`](#__nonilvalue__)
		* [`__NoRawSet__`](#__norawset__)
		* [`__ObjectAttr__`](#__objectattr__)
		* [`__ObjFuncAttr__`](#__objfuncattr__)
		* [`__ObjectSource__`](#__objectsource__)
		* [`__Require__`](#__require__)
		* [`__Return__`](#__return__)
		* [`__Sealed__`](#__sealed__)
		* [`__Set__`](#__set__)
		* [`__SingleVer__`](#__singlever__)
		* [`__Static__`](#__static__)
		* [`__Super__`](#__super__)
		* [`__SuperObject__`](#__superobject__)
		* [`__Throwable__`](#__throwable__)
* [keyword 关键字](#keyword-关键字)
	* [全局关键字](#全局关键字)
		* [export 关键字](#export-关键字)
		* [with 关键字](#with-关键字)
	* [上下文相关的关键字](#上下文相关的关键字)
	* [`_G`中可用的资源](#_g中可用的资源)
* [Serialization 序列化](#serialization序列化)
	* [从JSON开始](#从json开始)
	* [可序列化类型](#可序列化类型)
	* [自定义序列化和反序列化](#自定义序列化和反序列化)
* [System.Collections 集合](#systemcollections-集合)
	* [System.Collections.Iterable](#systemcollectionsiterable)
	* [System.Collections.IList](#systemcollectionsilist)
		* [System.Collections.ICountable](#systemcollectionsicountable)
		* [System.Collections.IIndexedList](#systemcollectionsiindexedlist)
		* [System.Collections.List](#systemcollectionslist)
	* [System.Collections.IDictionary](#systemcollectionsidictionary)
		* [System.Collections.Dictionary](#systemcollectionsdictionary)
	* [List, Dictionary和序列化](#list-dictionary和序列化)


## 安装

安装Lua后，下载**PLoop**或者使用git clone复制本项目到**LUA_PATH**所在目录，如果不清楚位置，可以使用 `print(package.path)`打印出来，一般以`\?\init.lua`结尾的路径都可以。之后就可以使用`require "PLoop"`加载本系统。

也可以将**PLoop**保存到项目目录下，使用如下方式加载

```lua
package.path = package.path .. ";项目所在路径/?/init.lua;项目所在路径/?.lua"

require "PLoop"
````

如果你需要按需加载，或者有独立的Lua文件加载系统，可以查看**PLoop/init.lua**了解文件的加载顺序。


## 从使用集合开始

在开始介绍面向对象系统之前，我们先介绍基于**PLoop**的部分应用, 首先以常用的集合处理开始。

在Lua中，通常使用table保存数据有两种形式：

* 数组，这里面我们通常只需要有序值
* 哈希表，键和值都是我们需要的数据

在**PLoop**中，我们通常使用**System.Collections.List**操作数组，**System.Collections.Dictionary**操作哈希表。

### List的创建

List对象有多种构造方式:

构造体                           |结果
:--------------------------------|:--------------------------------
List(table)                      |将传入的table直接封装为List对象，无需构建新对象，也没有赋值处理
List(listobject)                 |复制其他List对象的元素
List(iterator, object, index)    |使用类似List(ipairs{1, 2, 3})，使用迭代器返回的元素构建列表
List(count, func)                |循环count次，调用func(i)将返回值作为元素来构建列表
List(count[, init])              |构建一个有count个元素，值全是init或者索引值(init不存在)的列表
List(...)                        |使用输入的元素构建一个列表，不过上面的构造体优先级高，如果冲突或者无法确保的话（参数数目和类型），可以使用List{...}来构建，效果一样

下面是一些创建用例:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- List(table)
	o = {1, 2, 3}
	print(o == List(o))  -- true

	-- List(count)
	v = List(10)         -- {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	-- List(count, func)
	v = List(10, function(i) return math.random(100) end) -- {46, 41, 85, 80, 62, 37, 29, 91, 62, 37}

	-- List(...)
	v = List(1, 5, 4)    -- {1, 5, 4}
end)

print(v) -- nil
print(List) -- nil

import "System.Collections"

print(List) -- System.Collections.List
```

这是我们的第一个PLoop用例，**PLoop**有很多和通常Lua开发不同的设计，首先这里使用了 `PLoop(function(_ENV) end)`来封装和调用处理代码，这种设计是为了解决Lua开发的常见难点(以下关于环境的讨论，如果无法理解可以先行跳过，不影响阅读）:

* Lua的每个文件都可以视为一个函数被执行，而Lua的每个函数都有一个环境与之关联，环境就是Lua的普通table，这个函数中访问的全局变量就是这个环境中的字段。而默认情况下，这个环境就是`_G`。

	协作开发时，所有程序创建和读取的全局变量都会保存在`_G`中，这很容易引起冲突，为了避免重名冲突，一般需要强制使用local变量，这种开发方式并不自由，也过多的创建了闭包。

* 如**System.Collections.List**所示，通常为了避免同名类型冲突，一般使用命名空间来管理各种类型，为了在`_G`中使用**List**，我们需要使用`import "System.Collections"`来将这个命名空间的类型导入`_G`中，这点在上面的例子中最后几行可以看到。

	如果，我们有一个界面库提供**System.Form.List**类型，这是一个界面类，如果也同样被导入到`_G`中，这两个类型就会因为重名导致程序出错。

究其根源就在于，所有代码的默认执行环境都是`_G`，那么只要每个处理代码运行在各自的私有环境中，就可以完全避免重名问题，也无需特意使用local来申明函数和共用数据（函数内该用local的自然该用local，效率不同）。

在之前的例子中，封装代码的函数被传给**PLoop**后，将被绑定一个私有且特殊的**PLoop**环境，然后被执行。至于为什么采用这种形式，原因在于Lua的环境控制在5.1到5.2两个版本间有重大的变化，为了通用性，**PLoop**使用`PLoop(function(_ENV) end)`的形式来封装和调用代码，之后也会看到其他类似的处理，比如定义类`class "A" (function(_ENV) end)`。（如果你不了解`_ENV`，可以参考Lua5.2的更新说明）

这么处理的好处我们将在以后的例子中逐步了解，这个例子中使用到的点是:

* 申明的全局变量属于该私有环境，在`_G`中无法访问到被创建的变量v等。

* 可以随意使用例如math.random这样的保存在`_G`中的公共库或者变量，这样不会造成性能问题，私有环境会在第一次访问后自动缓存这些变量。

* 可以直接访问**List**类，**PLoop**中有公共命名空间这个概念，公共命名空间不需要被**import**即可被所有的**PLoop**环境访问，默认的公共命名空间是**System**, **System.Collections**和**System.Threading**，后面都会接触到。

	公共命名空间的访问优先级低于被import的命名空间，所以，如果使用了`import "System.Form"`，那么访问List访问到的是**System.Form.List**。

* 我们可以使用关键字**import**为私有环境或者`_G`引入命名空间，之后可以使用里面保存的类型。不同点在于，向`_G`中导入，是全部拷贝到`_G`中，而私有环境仅记录下自己导入的命名空间，当需要时，才取出要用的类型（同样会被自动缓存）。

回到List对象的创建，我们可以使用List这个类作为对象构建器，它会根据输入的参数来生成对象。

通常来说，这些对象就是带有指定元表的普通table，我们可以直接使用**ipairs**对它进行遍历，也可以使用`obj[1]`这样的方式访问其中的元素。不过更进一步，我们可以使用**List**类提供的强大的对象方法来进行处理。


### List的方法

**List**类提供了基础的方法来完成对list对象的操作:

方法                                     |描述
:----------------------------------------|:--------------------------------
Clear(self)                              |清空list对象的元素
Contains(self, item)                     |检查list中是否存在item元素
GetIterator(self)                        |返回用于元素遍历的迭代器
IndexOf(self, item)                      |返回指定元素的索引
Insert(self[, index], item)              |插入元素，即table.insert
Remove(self, item)                       |移除元素
RemoveByIndex(self[, index])             |按索引移除元素，即table.remove
Extend(self, table)                      |将table的元素添加到list对象的末尾
Extend(self, listobject)                 |将其他IList对象的元素添加到list对象的末尾
Extend(self, iterator[, object[, index]])|将迭代器的返回元素添加到list对象的末尾

```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	print(obj:RemoveByIndex()) -- 10
end)
```

```lua
require "PLoop"

PLoop (function(_ENV)
	-- 1,2,3,4,5,6,7,8,9
	print(table.concat(List{1, 2, 3, 4}:Extend(XList(5, 9)), ","))
end)
```

### 动态列表

在上面例子中，使用了XList这一个动态列表来避免构造完整的元素列表，XList仅保留开始，结束和步长，利用迭代器来返回对应的索引值：

```lua
require "PLoop"

PLoop (function(_ENV)
	-- 开始, 结束[, 步长]
	XList(5, 10, 2):Each(print)

	-- 步长可以是负数
	XList(4, 1, -1):Each(print)

	-- 结束
	-- 开始和步长默认1
	XList(10):Map("x=>x^2"):Each(print)

	-- 迭代函数[，列表[，索引]]
	XList(ipairs{1, 2, 3, 4}):Each(print)

	-- 列表
	XList{1, 2, 3, 4}:Each(print)
	XList(List(10):Range(5, 8)):Each(print)
end)
```

这种方式可以极大的节省内存占用和赋值操作，XList也扩展了**System.Collections.IList**, 我们可以使用Map方法来得到实际值，以及使用其他的链式处理。


### List的遍历

**List**和**Dictionary**都扩展了**System.Collections.Iterable**接口，这个接口要求集合类都需要提供**GetIterator**方法来提供遍历用的迭代器:
```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	for _, v in obj:GetIterator() do print(v) end
end)
```

**List**对象是数组，所以，实际来说，它的**GetIterator**方法就是**ipairs**，从这个意义上看，**List**还没有实际使用价值，下面我们看的是它的进阶遍历:

```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	-- 按顺序打印list中的每个元素
	obj:Each(print)

	-- 按顺序打印所有的偶数
	obj:Filter(function(x) return x%2 == 0 end):Each(print)

	-- 按顺序打印最后三个数字
	obj:Range(-3, -1):Each(print)

	-- 打印所有的奇数
	obj:Range(1, -1, 2):Each(print)

	-- 按顺序打印所有数字的2^x
	obj:Map(function(x) return 2^x end):Each(print)

	-- 计算合计
	print(obj:Reduce(function(x,y) return x+y end))
	print(obj:Sum())

	-- 打印合并的字符串
    -- 1,4,9,16
    print(XList(1, 4):Map("x=>x^2"):Join(","))
end)
```

这里有两种类型的方法：队列方法类似**Range**, **Filter**和**Map**，终止方法类似**Each**, **Reduce**等。

队列方法会记录操作和操作的参数，但并不执行，直到某个终止方法被调用，队列的操作会最终转换为一个新的迭代器供终止方法使用。实际处理来说，List对象调用某个队列方法后，一个流处理工作对象会被返回，所有的队列操作信息都保存在它里面，它本身也是一个特殊的列表对象（它的类不是List)，我们可以继续添加队列操作，直到最后调用终止方法，如果将上面的操作分开看，就是:

```lua
require "PLoop"

PLoop(function(_ENV)
	obj = List(10)

	-- 我们将解析下面的操作
	-- obj:Range(1, -1, 2):Map(function(x) return 2^x end):Each(print)

	-- 队列操作会返回一个流处理工作对象
	local worker = obj:Range(1, -1, 2)

	-- 虽然使用了赋值，但实际继续队列操作，依然是同一个
	worker = worker:Map(function(x) return 2^x end)

	-- 调用Each终止方法的实际处理
	for _, v in worker:GetIterator() do
		print(v)
	end
end)

```

* 流处理工作对象是系统内部用的对象，它完全被系统控制，在处理完成后，它会被系统回收以备下一个集合操作使用，所以，不会因为你多次使用这类集合操作导致对象不断被创建，造成过多的GC回收，同样，作为使用者不应自己获取流处理工作对象，进行操作，避免和系统处理冲突（比如记录下，终止操作后，继续使用）。

* 和其他的Lua集合库不同，在上面的各种操作中，并不会有缓存table或者匿名函数被创建，所以，即便进行上万次的操作，也不会因为内存增长导致过多的gc开销。它的实现细节我们会在**协程**相关部分再了解。

下面是队列方法的清单:

方法                                     |描述
:----------------------------------------|:--------------------------------
Filter(self, func)                       |将元素传入这个函数，如果返回非false值，那么元素将继续用于之后的操作
Filter(self, name, value)                |如果`element[name] == value`，那么元素将被继续用于之后的操作
Map(self, func)                          |将元素传入函数，返回值将作为替代元素用于之后的操作
Map(self, name)                          |使用 `element[name]`作为替代元素用于之后的操作
Range(self[, start[, stop[, step]]])     |只使用返回内的符合步数的元素用于之后的操作，start默认1，stop默认-1，step默认1

下面是终止方法的清单:

方法                                     |描述
:----------------------------------------|:--------------------------------
All(self, func, ...)                     |将元素和...参数传入函数，如果所有元素的处理结果都是非false，那么返回true，否则false
Any(self, func, ...)                     |将元素和...参数传入函数，如果有一个元素的处理结果非false，返回true，否则false
Each(self, func, ...)                    |将所有元素附带...参数传入函数执行
Each(self, name, ...)                    |如果`element[name]`是方法（函数）, 它将被调用，...参数也会被传入，否则`element[name] = ...` 将被使用
First(self, func, ...)                   |返回第一个使`func(element, ...)`返回非false值的元素
First(self)                              |返回列表的第一个元素
Last(self, func, ...) 					 |返回最后一个使`func(element, ...)`返回非false值的元素
Last(self)            					 |返回列表的最后一个元素
Reduce(self, func[, init])               |用于合并元素，参考上面计算总值的例子
ToList(self[, listtype])                 |使用迭代返回的元素创建一个新的列表对象，默认列表类型是**List**
Sum(self)                                |返回列表所有元素的和值
Join(self[, sep])                        |使用分隔符合并列表中的所有字符串


### List的排序

**List**的对象都是顺序列表，我们可以根据对比规则来对它的元素进行排序，系统为顺序列表提供了很多排序算法:

排序方法                                        |描述
:-----------------------------------------------|:--------------------------------
Reverse(self[, start[, stop]])                  |反转列表，因为它会修改列表对象本身，也算作排序之一，start默认1，stop默认-1
BubbleSort(self, [compare[, start[, stop]]])    |使用冒泡排序，compare默认值是`function(x, y) return x < y end`
CombSort(self, [compare[, start[, stop]]])      |使用梳排序
HeapSort(self, [compare[, start[, stop]]])      |使用堆排序
InsertionSort(self, [compare[, start[, stop]]]) |使用插入排序
MergeSort(self, [compare[, start[, stop]]])     |使用归并排序
QuickSort(self, [compare[, start[, stop]]])     |使用快速排序
SelectionSort(self, [compare[, start[, stop]]]) |使用选择排序
Sort(self, [compare[, start[, stop]]])          |Lua的自带排序，也就是table.sort
TimSort(self, [compare[, start[, stop]]])       |使用timsort排序

下面是一段测试代码:

```lua
require "PLoop"

PLoop(function(_ENV)
	local random = math.random
	local function val() return random(500000) end

	function test(cnt, sortMethod)
		collectgarbage()

		local st = os.clock()

		for i = 1, cnt do
			local lst = List(1000, val)
			lst[sortMethod](lst)
		end

		print(sortMethod, "Cost", os.clock() - st)
	end

	test(100, "BubbleSort")
	test(100, "CombSort")
	test(100, "HeapSort")
	test(100, "InsertionSort")
	test(100, "MergeSort")
	test(100, "QuickSort")
	test(100, "SelectionSort")
	test(100, "Sort")
	test(100, "TimSort")
end)
```

Lua5.1下的结果是

```
BubbleSort      Cost    13.916
CombSort        Cost    0.422
HeapSort        Cost    0.484
InsertionSort   Cost    4.772
MergeSort       Cost    0.535
QuickSort       Cost    0.281
SelectionSort   Cost    6.417
Sort            Cost    0.109
TimSort         Cost    0.547
```

通常，Lua自带的排序是最佳选择（虽然它不稳定），不过如果在luajit下面:

```
BubbleSort      Cost    0.269
CombSort        Cost    0.033
HeapSort        Cost    0.038
InsertionSort   Cost    0.125
MergeSort       Cost    0.046
QuickSort       Cost    0.018
SelectionSort   Cost    0.075
Sort            Cost    0.084
TimSort         Cost    0.036
```

Luajit的确很擅长这类重复性工作。


### Dictionary的创建

类似**List**，我们同样有多种创建Dictionary对象的方式:

构造方法                               |结果
:-------------------------------------|:--------------------------------
Dictionary()                          |创建一个空dictionary对象
Dictionary(table)                     |将输入的table转换成一个dictionary对象
Dictionary(table:IList, table:IList)  |接受两个数组或列表对象，第一个数组的元素作为键，第二个数组的元素作为值，构建一个新的dictionary对象
Dictionary(dictionary)                |复制dictionary对象的键值对，创建新的对象
Dictionary(iter, obj, index)          |使用迭代器产生的键值对创建新的dictionary对象

下面是一些例子:

```lua
require "PLoop"

PLoop(function(_ENV)
	Dictionary(_G) -- Convert the _G to a dictionary

	-- key map to key^2
	lst = List(10)
	Dictionary(lst, lst:Map(function(x)return x^2 end))
end)
```


### Dictionary的方法

这些dictionary对象实际就是普通的哈希表，所以我们可以使用**pairs**来遍历它们，也可以直接使用`obj[key] = value`去修改它们，这些操作和普通table是一样的，所以**Dictionary**的**GetIterator**方法实际就是**pairs**.

字典类仅定义一个方法用于更新自己

方法                                     |描述
:----------------------------------------|:--------------------------------
Update(self, table)                      |使用table的键值对更新自己
Update(self, IDictionary)                |使用自他IDictionary对象的键值对更新自己
Update(self, iter[, obj[, idx])          |使用迭代器返回的键值对更新自己

```lua
require "PLoop"

PLoop(function(_ENV)
	v = Dictionary(List(5), List(5))
	v:Update{ [3] = 9, [4] = 16 }

	-- 1   1
	-- 2   2
	-- 3   9
	-- 4   16
	-- 5   5
	v:Each(print)
end)
```


### Dictionary的遍历

类似于**List**，**Dictionary**同样可以使用队列方法和终止方法。

队列方法清单:

方法                                     |描述
:----------------------------------------|:--------------------------------
Filter(self, func)                       |将键值对传入函数，如果返回非false值，键值对将用于之后的操作
Map(self, func)                          |将键值对传入函数，返回的值将作为替代值和键一起用于之后的操作

终止方法:

方法                                     |描述
:----------------------------------------|:--------------------------------
Each(self, func, ...)                    |将所有的键值对传入函数
GetKeys(self)                            |返回一个迭代器，使用类似`for index, key in dict:GetKeys() do print(key) end`
GetValues(self)                          |返回一个迭代器，使用类似`for index, value in deict:GetValues() do print(value) end
Reduce(self, func, init)                 |合并所有键值对，详见后面的例子

另外**Dictionary**也可以使用一种终止属性:

属性                                     |描述
:----------------------------------------|:--------------------------------
Keys                                     |返回一个列表的流处理工作对象，代表所有键
Values                                   |返回一个列表的流处理工作对象，代表所有值

通过这两个终止属性，我们可以将dictionary操作转换成list操作。

下面是一些例子:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- 获取_G的所有键，转换为List后，排序，再打印
	Dictionary(_G).Keys:ToList():Sort():Each(print)

	-- 计算所有值的总和
	print(Dictionary{ A = 1, B = 2, C = 3}:Reduce(function(k, v, init) return init + v end, 0))
end)

```

**List**和**Dictionary**的队列和终止，以及排序方法并非定义在它们内部，而是由接口提供，等了解类和接口后，我们可以创建新的集合类型扩展这些接口，然后直接享受这些方法带来的便利。


### 动态字典

类似动态列表的处理，我们也可以基于字典对象，哈希表，键值对列表来构建动态字典，动态字典不会实际生成字典键值对，在很多场合可以优化处理:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- 键值对列表
	XDictionary(List(4), {"1st", "2nd", "3rd", "4th"}):Each(print)

	-- 字典对象或哈希表
	XDictionary(_G):Each(print)

	-- 迭代器
	XDictionary(pairs(_G)):Each(print)
end)
```


## 特性(Attribute)和协程池(Thread Pool)

**List**和**Dictionary**展示了对象的构建和使用，接下来，我们可以来看关于**PLoop**私有环境的一些特殊用法。首先是特性和协程的合用：

```lua
require "PLoop"

PLoop(function(_ENV)
	__Iterator__()
	function iter(i, j)
		for k = i, j do
			coroutine.yield(k)
		end
	end

	-- print 1-10 for each line
	for i in iter(1, 10) do
		print(i)
	end
end)
```

和`_G`不同，**PLoop**的私有环境，会监视新全局变量的定义(通过__newindex），当函数iter被定义时，系统会检测是否有注册的特性需要被使用在这个函数上，而之前我们使用了`__Iterator__()`。

`__Iterator__`是定义在**System.Threading**命名空间的一个特性类，当我们使用它创建对象时，这个对象就会被注册到系统中，等待下一个被定义的特性目标（比如函数，类等）。特性被用来对特性目标进行修改或者附着数据。

`__Iterator__`这个特性是用于封装目标函数，使调用它时，它会作为一个迭代器并被运行在一个协程中，然后我们可以使用**coroutine.yield**来依次返回值:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- 计算斐波那契数列
	__Iterator__()
	function Fibonacci(maxn)
		local n0, n1 = 1, 1

		coroutine.yield(0, n0)
		coroutine.yield(1, n1)

		local n = 2

		while n <= maxn  do
			n0, n1 = n1, n0 + n1
			coroutine.yield(n, n1)
			n = n + 1
		end
	end

	-- 1, 1, 2, 3, 5, 8
	for i, v in Fibonacci(5) do print(v) end

	-- 我们也可以依照迭代器的习惯，将参数在之后传入
	-- 这个迭代器会自动合并所有参数
	-- 1, 1, 2, 3, 5, 8
	for i, v in Fibonacci(), 5 do print(v) end
end)
```

之前列表的流处理工作对象的**GetIterator**方法就是使用这个机制实现的，所以，它不需要生成任何缓存表或者构建匿名函数来完成它的工作。

你同样可以直接使用**coroutine.wrap**来达成同样效果，但区别在于，**PLoop**内置了协程池(因为Lua的协程打印出来名字是thread，也可以当作线程池理解，这也是为什么命名空间的名字是Threading而不是Coroutine)。

使用`__Iterator__`封装的函数，被调用时将从协程池中获取一个协程来执行操作，当这个函数的操作执行完成后，这个协程会被协程池回收备用，这样可以有效的避免协程的生成和GC处理。

`__Iterator__`仅用于创建迭代器，我们看一个协程更普遍的用法:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- 以协程运行函数
	__Async__()
	function printco(i, j)
		print(coroutine.running())
	end

	-- 运行结果相同，系统会一直复用这些协程
	for i = 1, 10 do
		printco()
	end
end)
```

**PLoop**很推荐使用这种方式来进行异步处理，通过协程池和这两个特性，可以使开发者更集中在异步逻辑处理上。


## 拼写错误检查

Lua调试上有很多麻烦，如果出错的情况还比较好处理，但会有隐藏的问题点，比如`if a == ture` 这样的处理，ture是不存在的变量，Lua默认作为nil处理了，这样if判定依然可以继续进行，但结果不可能正确。

我们来看如何在**PLoop**中解决它。

### 读取不存在的全局变量

在使用require加载**PLoop**之前，我们可以定义一个名为**PLOOP_PLATFORM_SETTINGS**的table，用来调整**PLoop**的内部设定:

```lua
PLOOP_PLATFORM_SETTINGS = { ENV_ALLOW_GLOBAL_VAR_BE_NIL = false }

require "PLoop"

PLoop(function(_ENV)
	local a = ture  -- Error: The global variable "ture" can't be nil.

	if a then
		print("ok")
	end
end)
```

关闭**ENV_ALLOW_GLOBAL_VAR_BE_NIL**后，**PLoop**的所有私有环境会使用强制模式，禁止访问任何不存在的变量(未定义也无法从命名空间和基础环境中获取到的)，这样就可以快速的定位这类错误。

### 写非法全局变量

如果我们漏写了`local`，会导致原本的局部变量被保存成全局，不过系统本身无法区分期望的全局变量和不期望的全局变量，所以，系统需要在平台设置里面指定一个过滤函数：


```lua
PLOOP_PLATFORM_SETTINGS = {
	GLOBAL_VARIABLE_FILTER = function(key, value)
		-- 不允许首字母是小写并且值是非函数的全局变量
		if type(key) == "string" and key:match("^%l") and type(value) ~= "function" then
			return true
		end
	end,
}

require "PLoop"

PLoop(function(_ENV)
	Test = 1

	class "A" (function(_ENV)
		function Test(self)
			ch = 2 -- error: There is an illegal assignment for "ch"
		end
	end)

	A():Test()
end)
```

当过滤函数返回true时，这个赋值会引发error，代码将停止运行，如果期望只得到警告，但不终止代码的话，可以添加一个设置：


```lua
PLOOP_PLATFORM_SETTINGS = {
	GLOBAL_VARIABLE_FILTER = function(key, value)
		-- Don't allow the lowercase key with non-function value
		if type(key) == "string" and key:match("^%l") and type(value) ~= "function" then
			return true
		end
	end,
	GLOBAL_VARIABLE_FILTER_USE_WARN = true,
}

require "PLoop"

PLoop(function(_ENV)
	Test = 1

	class "A" (function(_ENV)
		function Test(self)
			ch = 2 -- [PLoop: Warn]There is an illegal assignment for "ch"@path_to_file\file.lua:18
		end
	end)

	A():Test()
end)
```

可以看到，如果可能，系统会提供出赋值的调用位置。如果需要，也可以将这个过滤函数作为记录器使用，只需要增加一个设置，调用位置就会作为第三个参数传入：

```lua
PLOOP_PLATFORM_SETTINGS = {
	GLOBAL_VARIABLE_FILTER = function(key, value, path)
		print("Assign '" .. key .. "'" .. path )
	end,
	GLOBAL_VARIABLE_FILTER_GET_CALLLINE = true,
}

require "PLoop"

PLoop(function(_ENV)
	Test = 1  -- Assign 'Test'@path_to_file\file.lua:11

	class "A" (function(_ENV)
		function Test(self)
			ch = 2 -- Assign 'ch'@path_to_file\file.lua:15
		end
	end)

	A():Test()
end)
```

如果要获取调用位置，`debug.getinfo`函数必须存在。

### 访问不存在的对象字段

我们也可以禁止访问不存在的对象字段：

```lua
PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST = true, OBJECT_NO_NIL_ACCESS = true }

require "PLoop"

PLoop(function(_ENV)
	-- 定义一个具有Name和Age属性的类
	class "Person" (function(_ENV)
		property "Name" { type = String }
		property "Age"  { type = Number }
	end)

	o = Person()

	o.Name = "King" -- Ok

	o.name = "Ann"  -- Error: The object can't accept field that named "name"

	print(o.name)   -- Error: The object don't have any field that named "name"
end)
```

开启**OBJECT_NO_RAWSEST**和**OBJECT_NO_NIL_ACCESS**会禁止向对象中写入或者读取不存在的属性或者字段，配合上面的设置，可以有效的避免开发过程中的拼写错误。当运行在工作环境时，最好不要使用这些配置，去掉可以轻微优化访问速度。


## 类型验证

**PLoop**使Lua成为一门强类型语言，它提供了多种类型验证方式来避免错误传递的过远导致很难回溯。

为了确保函数调用正确并避免错误发生的堆栈位置过深，通常我们需要在函数逻辑开始前写上大量的判定处理（也包括对应不同的参数处理），然而工作环境中，因为测试完毕，我们往往并不需要这些检查。

在**PLoop**中，这将不成为问题:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String, Number }
	function SetInfo(name, age)
	end

	-- Error: Usage: SetInfo(System.String, System.Number) - the 2nd argument must be number, got boolean
	SetInfo("Ann", true)
end)
```

`__Arguments__`是定义在**System**中的特性类，它用于将函数参数的名字，类型，默认值等信息和参数绑定，并且封装这个函数，补上参数验证。

**String**和**Number**是结构体类型，用于值验证，我们会在结构体部分具体了解。

当我们需要发布项目时，我们无需再进行类型验证，这时可以在平台配置表关闭类型验证(并非所有类型验证都会关闭，不过细节留给系统即可):

```lua
PLOOP_PLATFORM_SETTINGS = { TYPE_VALIDATION_DISABLED = true }

require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String, Number }
	function SetInfo(name, age)
	end

	-- No error now
	SetInfo("Ann", true)
end)
```

为了提供一整套类型验证系统，我们需要更多的类型来描述数据。在**PLoop**中，默认提供四种类型: enum, struct, interface 和 class


## enum 枚举类型

枚举是一种数据类型，由一组由键值组成的元素组成，枚举值的名称通常用来作为常量使用。

定义枚举类型的格式是


```lua
enum "name" { -- key-value pairs }
```

在定义表中，对于每个键值对，如果键是字符串，则键将用作元素的名称，值是元素的值。 如果该键是一个数字并且该值是字符串，则该值将用作该元素的名称和值，否则该键值对将被忽略。

定义完成后，我们可以使用`enumeration[elementname]`来通过元素名获取值，或者使用`enumeration(value)`来通过值获取元素名。

在定义了这个枚举类型的环境中，或者import了它的环境中，我们也可以直接使用枚举值名称来直接访问它们。

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "TestNS"

	enum "Direction" { North = 1, East = 2, South = 3, West = 4 }

	print(Direction.South) -- 3
	print(Direction.NoDir) -- nil
	print(Direction(3))    -- South

	print(East)            -- 2
end)

PLoop(function(_ENV)
	import "TestNS.Direction"

	print(South)           -- 3
end)
```

除了自行指定键值对外，系统也提供了其他特性来自动生成元素：

```lua
require "PLoop"

PLoop(function(_ENV)
	__AutoIndex__{ North = 1, South = 5 }
	enum "Direction" {
		"North",
		"East",
		"South",
		"West",
	}

	print(East) -- 2
	print(West) -- 6
end)
```

`__AutoIndex__`特性用于转换一个字符串数组表，将内部的元素转换为键，按顺序赋予自增值，同时也可以在构造`__AutoIndex__`对象时，传入一个特定的表，用于指定某些元素的值。效果见上面的例子。

另一种个特殊特性类是`__Flags__`，它用于标记枚举类型为位标志枚举类型，它的元素值为2^N（也可以用0值)，之后我们可以将这些枚举值进行叠加，也可以很方便的解析:


```lua
require "PLoop"

PLoop(function(_ENV)
	__Flags__()
	enum "Days" {
		"SUNDAY",
		"MONDAY",
		"TUESDAY",
		"WEDNESDAY",
		"THURSDAY",
		"FRIDAY",
		"SATURDAY",
	}

	v = SUNDAY + MONDAY + FRIDAY

	-- 和普通枚举类型不同，使用值返回枚举名得到的是一个迭代器
	-- SUNDAY  1
	-- MONDAY  2
	-- FRIDAY  32
	for name, val in Days(v) do
		print(name, val)
	end

	-- 或者也可以传入一个table来缓存结果
	local result = Days(v, {})
	for name, val in pairs(result) do print(name, val) end

	print(Enum.ValidateFlags(MONDAY, v)) -- true
	print(Enum.ValidateFlags(SATURDAY, v)) -- false
end)
```

### System.Enum

**System.Enum**是一个反射类型，我们可以使用它来获取枚举类型的内部信息，下面是一个可用的方法清单（并非全部，其他都是仅能被系统使用的）:

静态方法                        |描述
:-------------------------------|:-----------------------------
GetDefault(enum)                |获得枚举类型的默认值
GetEnumValues(enum[, cache])    |如果cache存在，将枚举元素作为键值对保存在cache中并返回cache，如果不存在，返回一个迭代器供for循环使用
IsFlagsEnum(enum)               |是否是位标志枚举类型
IsImmutable(enum)               |永远返回true，表明所有枚举类型是不可变值，意思是，值通过枚举类型的校验时，不会发生改变
IsSealed(enum)                  |枚举类型是否封闭，不可被重写
Parse(enum, value)              |和enum(value)功能一致
ValidateFlags(check, target)    |目标值是否含有检查值，用于位标志计算
ValidateValue(enum, value)      |如果value时枚举类型的值，那么返回value，否则返回nil
Validate(target)                |如果目标是枚举类型，返回true，否则返回false

在列表中，有两个未知的方法: **GetDefault**和**IsSealed**，需要使用两个相关的特性类：

```lua
require "PLoop"

PLoop(function(_ENV)
	__Default__("North") __AutoIndex__()
	enum "Direction" {
		"North",
		"East",
		"South",
		"West",
	}

	print(Enum.GetDefault(Direction)) -- 1

	--如果没有封闭，新定义会覆盖原本的定义
	__Sealed__()
	enum "Direction" { North = "N", East = "E", South = "S", West = "W" }

	print(Enum.GetDefault(Direction)) -- nil

	-- 封闭后，我们可以添加键值对
	enum "Direction" { Center = "C" }

	-- 但我们不能覆盖存在的键或者值
	-- Error: Usage: enum.AddElement(enumeration, key, value[, stack]) - The key already existed
	enum "Direction" { North = 1 }

	-- Error: Usage: enum.AddElement(enumeration, key, value[, stack]) - The value already existed
	enum "Direction" { C = "N" }
end)
```

`System.__Default__`特性被用来设置枚举类型的默认值，这个默认值对枚举类型而言并没有什么用途，我们会在后面看到它的实际使用。

`System.__Sealed__`特性用于封闭类型，避免它的定义被其他人覆盖，不过对于枚举类型来说，其他人依然可以扩展它。


## struct 结构体

结构体类型是**PLoop**中的主要数据类型，也用来作为数据契约提供类型验证等功能。基于它们的结构，**PLoop**提供四种结构体类型。


### Custom 自定义结构体

自定义结构体大多用来代表基本数据类型，例如number，string，更进一步的是例如自然数等特殊基本数据类型。

从代表number的**System.Number**的定义开始：

```lua
require "PLoop"

PLoop(function(_ENV)
	-- 环境 A
	struct "Number" (function(_ENV)
		-- 环境 B
		function Number(value)
			return type(value) ~= "number" and "the %s must be number, got " .. type(value)
		end
	end)

	v = Number(true)  -- Error : the value must be number, got boolean
end)
```

类似于使用**PLoop**启用私有环境运行代码，在**PLoop**定义结构体同样使用这种调用方式，里面被调用函数体就是Number这个结构体的定义。

这里的环境B是为了定义类型特殊设计的：

* 环境B嵌套在环境A中，所以，环境A就是环境B的基础环境，环境B可以访问任何定义在或者被import在环境A中的变量。

* 环境B是为了结构体定义特殊设计的，它会将一些特定赋值转换为类型的定义，比如这里的和类型同名的Number函数，会作为Number类型的**验证器**，也可以定义名为`__valid`的函数作为验证器（对应匿名结构体，类似`struct(function(_ENV) function __valid(val) end end)` )

验证器被用来对输入的值进行校验，如果返回值是非false，那么意味着值并没有通过验证，通常来说，未通过验证需要返回一个错误信息，这个错误信息中的`%s`会被系统按照使用场所进行替换，如果仅返回true，那么系统会自动产生一个错误消息。

在一些情况下，我们需要自动转换输入的值，这时就需要使用结构体的**初期化方法**:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "AnyBool" (function(_ENV)
		function __init(value)
			return value and true or fale
		end
	end)
	print(AnyBool(1))  -- true
end)
```

名字为`__init`的函数会作为结构体的**初期化方法**，如果它的返回值不为nil，那么会作为新值替代掉原值。

我们来看一个具体的使用例子:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ Callable, Number, Number }
	function Calc(func, a, b)
		print(func(a, b))
	end

	Calc("x,y=>x+y", 1, 11) -- 12
	Calc("x,y=>x*y", 2, 11) -- 22
end)
```

**System.Callable**是一个联合类型，它允许function，带有`__call`元表方法的对象，以及**System.Lambda**类型的数据。 **PLoop**中的lambda就是类似`"x,y=>x+y"`这样的简单字符串，**System.Lambda**的**初期化方法**会将这个字符串转换为函数使用。所以，上面的例子中，Calc可以确认它拿到的func始终是可调用的值。

**List**和**Dictionary**的方法（队列，终止，排序等）都使用**System.Callable**描述它的参数，所以，我们也可以使用类似的处理代码:

```lua
require "PLoop"

PLoop(function(_ENV)
	List(10):Map("x=>x^2"):Each(print)
end)
```

这就是**初期化方法**的工作方式。

为了简化定义，结构体类型支持简单的继承机制，可以使用`__base`来指定一个基础结构体，基础结构体的验证器和初期化方法都会被继承，并在类型本身的验证器和初期化方法之前被调用，这个继承链可以一直添加下去，比如Number->Integer->NatureNumber->...

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Integer" (function(_ENV)
		-- 指定Number为基础结构体
		__base = Number

		local floor = math.floor

		function Integer(value)
			return floor(value) ~= value and "the %s must be integer"
		end
	end)

	v = Integer(true)  -- Error : the value must be number, got boolean
	v = Integer(1.23)  -- Error : the value must be integer
end)
```

类似枚举类型，因为这些自定义结构体通常代表基础数据，我们可以为它指定默认值:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Default__(0)
	struct "Integer" (function(_ENV)
		__base = Number
		__default = 0 -- 也可以向__default赋值替代__Default__特性

		local floor = math.floor

		function Integer(value)
			return floor(value) ~= value and "the %s must be integer"
		end
	end)

	print(Struct.GetDefault(Integer)) -- 0
end)
```

同样，我们可以使用`__Sealed__`特性来封闭这个结构体类型，确保它不会被重定义:

```lua
require "PLoop"

PLoop(function(_ENV)
	__Sealed__(0)
	struct "AnyBool" (function(_ENV)
		function __init(value)
			return value and true or fale
		end
	end)

	-- Error: Usage: struct.BeginDefinition(structure[, stack]) - The AnyBool is sealed, can't be re-defined
	struct "AnyBool" (function(_ENV)
		function __init(value)
			return value and true or fale
		end
	end)
end)
```

**PLoop**系统提供了很多基本的自定义结构体:


自定义结构体                  |描述
:-----------------------------|:-----------------------------
**System.Any**                |代表任意值
**System.Boolean**            |代表布尔值
**System.String**             |代表字符串
**System.Number**             |代表数字
**System.Function**           |代表函数
**System.Table**              |代表table
**System.Userdata**           |代表userdata
**System.Thread**             |代表thread
**System.AnyBool**            |转换任意值为布尔值
**System.NEString**           |代表非空字符串
**System.RawTable**           |代表没有元表的table
**System.Integer**            |代表整型数字
**System.NaturalNumber**      |代表自然数
**System.NegativeInteger**    |代表负整数
**System.NamespaceType**      |代表任意命名空间
**System.EnumType**           |代表枚举类型，需要和System.Enum区分，System.Enum并非任何类型
**System.StructType**         |代表任意结构体类型
**System.InterfaceType**      |代表任意接口类型
**System.ClassType**          |代表任意类类型
**System.AnyType**            |代表任意可验证类型，默认包含枚举类型，结构体类型，接口类型或者类类型
**System.Lambda**             |代表lambda值
**System.Callable**           |代表callable值, 比如function, callable objecct, lambda
**System.Guid**               |代表Guid


### Member 成员结构体类型

成员结构体代表具有特定字段的表结构，首先来看一个例子

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	loc = Location{ x = "x" }    -- Error: Usage: Location(x, y) - x must be number
	loc = Location(100, 20)
	print(loc.x, loc.y)          -- 100  20
end)
```

在前面我们已经知道这个定义环境是特别为结构体设计的，所以，当它检查赋值的双方，键为字符串，值为**System.AnyType**时，它就可以将这次赋值转变为添加一个成员变量，这个成员的类型之后会被用来进行值的字段校验。

从上面的例子也可以看到，成员结构体可以用来构造值，他会将参数按照成员的定义顺序依次保存在新值中。只有成员结构体可以作为这种用途。

使用`x = Number`是最简单的成员申明方式，不过实际上还有更多的信息需要填充，下面是正规的定义方式:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		member "x" { type = Number, require = true }
		member "y" { type = Number, default = 0    }
	end)

	loc = Location{}            -- Error: Usage: Location(x, y) - x can't be nil
	loc = Location(100)
	print(loc.x, loc.y)         -- 100  0
end)
```

**member**是只能在结构体定义中使用的关键字，它需要一个名字和定义表来定义新的成员。定义表的字段是(字段大小写无视，均非必需):

字段              |描述
:-----------------|:--------------
type              |成员的类型，符合**System.AnyType**的值
require           |布尔值, 成员是否不能为nil
default           |成员的默认值

同样，成员结构体也支持验证器和初始化方法:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "MinMax" (function(_ENV)
		member "min" { Type = Number, Require = true }
		member "max" { Type = Number, Require = true }

		function MinMax(val)
			return val.min > val.max and "%s.min can't be greater than %s.max"
		end
	end)

	v = MinMax(100, 20) -- Error: Usage: MinMax(min, max) - min can't be greater than max
end)
```

因为成员结构体的值都是table，所以，我们也可以定义些结构体方法，这些方法会被保存到验证或者创建的值里面以备使用:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		member "x" { Type = Number, Require = true }
		member "y" { Type = Number, Default = 0    }

		function GetRange(val)
			return math.sqrt(val.x^2 + val.y^2)
		end
	end)

	print(Location(3, 4):GetRange()) -- 5
end
```

非结构体类型名，也不是`__valid`等特殊名字的函数会作为结构体方法保存。我们也可以定义静态方法，仅供结构体自身使用（也可以给自定义结构体定义静态方法)。

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		member "x" { Type = Number, Require = true }
		member "y" { Type = Number, Default = 0    }

		__Static__()
		function GetRange(val)
			return math.sqrt(val.x^2 + val.y^2)
		end
	end)

	print(Location.GetRange{x = 3, y = 4}) -- 5
end)
```

`System.__Static__`用于指明下一个定义的方法是静态方法。

之前自定义结构体我们可以指定默认值，那么现在可以看看默认值的用法:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Number" (function(_ENV)
		__default = 0

		function Number(value)
			return type(value) ~= "number" and "the %s must be number"
		end
	end)

	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	loc = Location()
	print(loc.x, loc.y)         -- 0    0
end)
```

所以，成员会使用成员类型的默认值作为它的默认值来使用。

成员结构体同样可以指定基础结构体，它会继承基础结构体的成员定义，非静态的方法，验证器和初始化方法，不过通常不推荐这么做。

系统默认仅提供一个成员结构体:

成员结构体                    |描述
:-----------------------------|:-----------------------------
**System.Variable**           |代表变量，在重载部分我们会具体看到它的用途


### Array 数组结构体

数组结构体代表含有一组同类型数据的数组table，这是一个比较简单的类型：

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	struct "Locations" (function(_ENV)
		__array = Location
	end)

	v = Locations{ {x = true} } -- Usage: Locations(...) - the [1].x must be number
end)
```

同样，数组结构体也支持结构体方法，静态方法，基础结构体，验证器和初始化方法，不过通常没有这类需求。

题外话，使用**PLoop**的序列化机制序列化一个数组结构体数据时，因为系统明确知道它是数组类型，所以，不需要进行验证就可以按照数组的方式序列化它，这对一些数据量比较大的场合非常有效。

系统默认只提供一个数组结构体:

数组结构体                    |描述
:-----------------------------|:-----------------------------
**System.Variables**          |代表一组变量，我们会在重载系统中具体看它的用途


### Hash 键值对结构体

同样，我们可以定义对应确定键值类型的哈希table：

```lua
require "PLoop" (function(_ENV)
    struct "SNMap" (function(_ENV)
        __key = String
        __value = Number
    end)

    v = SNMap{ key = true } -- the [value in value] must be number, got boolean
    v = SNMap{ [1] = 23 } -- the [key in value] must be string, got number
end)
```


### 使用table来定义结构体

为了简化结构体的定义方式，我们也可以使用table来替代函数作为定义体:


```lua
require "PLoop"

PLoop(function(_ENV)
	-- 自定义结构体
	__Sealed__()
	struct "Number" {
		__default = 0,  -- 指定默认值

		-- 数字索引的函数就是验证器
		function (val) return type(val) ~= "number" end,

		-- 也可以用特殊的键指定
		__valid = function (val) return type(val) ~= "number" end,
	}

	struct "AnyBool" {
		-- 定义初始化方法
		__init = function(val) return val and true or false end,
	}

	-- 成员结构体
	struct "Location" {
		-- 最好不用x = { type = Number }这类形式，因为无法确认成员定义的顺序
		{ name = "x", type = Number, require = true },
		{ name = "y", type = Number, require = true },

		-- 定义方法，不过无法定义静态方法
		GetRange = function(val) return math.sqrt(val.x^2 + val.y^2) end,
	}

	-- 数组结构体
	-- 数字索引的任意类型，会作为数组元素类型使用，也可以使用__array指定
	struct "Locations" { Location }

	-- 哈希结构体
	-- 用类型作为键值即可
	struct "SNMap" { [String] = Number }
end)
```

### 减少验证消耗

回到最开始的Number定义，因为错误消息是运行期动态创建的，但在**PLoop**的很多场合，都仅仅需要知道是否能验证通过，并不需要验证信息。

验证器实际会接收到两个参数，第二个参数为true时，就表明系统不在意错误信息，仅在意是否验证失败，所以我们可以修改Number的定义为:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Number" (function(_ENV)
		function Number(value, onlyvalid)
			if type(value) ~= "number" then return onlyvalid or "the %s must be number, got " .. type(value) end
		end
	end)

	-- The API to validate value with types (type, value, onlyvald)
	print(Struct.ValidateValue(Number, "test", true))   -- nil, true
	print(Struct.ValidateValue(Number, "test", false))  -- nil, the %s must be number, got string
end)
```

当然，也可以直接返回true，让系统自己处理后面的部分。


### 联合类型

如果你的值可能是多种类型，你可以使用`+`号来创建联合验证类型，值只需要满足其中一个就可以通过验证:

```lua
require "PLoop"

PLoop(function(_ENV)
	-- nil, the %s must be value of System.Number | System.String
	print(Struct.ValidateValue(Number + String, {}, false))
end)
```

可以联合任意的**System.AnyType**值，比如枚举类型，接口，结构体等。


### 子类型

如果我们需要的值一种类型，并且我们希望限定它必须是某个结构体的扩展结构体（用前者作为基础结构体），或者某个类的子类等，我们可以使用`-`来创建子类型验证结构体:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Integer" { __base = Number, function(val) return math.floor(val) ~= val end }
	print(Struct.ValidateValue( - Number, Integer, false))  -- Integer
end)
```

### System.Struct

类似**System.Enum**, **System.Struct**也是一个反射类型，我们可以用它获取结构体类型的内部信息:

静态方法                                |描述
:---------------------------------------|:-----------------------------
GetArrayElement(target)                 |获得目标结构体的数组元素类型
GetBaseStruct(target)                   |获得目标结构体的基础结构体
GetDefault(target)                      |获得目标结构体的默认值，仅适用于自定义结构体
GetMember(target, name)                 |获得目标结构体指定的成员
GetMembers(target[, cache])             |如果cache存在，将成员按顺序保存并返回cache，否则返回一个用于for循环的迭代器
GetMethod(target, name)                 |返回方法及一个表明是否静态方法的布尔值
GetMethods(target[, cache])             |如果cache存在，将方法和名字保存在cache中，并返回cache，否则返回一个用于for循环的迭代器
GetStructCategory(target)               |返回结构体的类型: CUSTOM, MEMBER, ARRAY, DICTIONARY
IsImmutable(target)                     |目标结构体是否是不可变类型，即指通过校验不会被改变
IsSubType(target, base)                 |目标结构体是否是base的扩展类型
IsSealed(target)                        |目标结构体是否已经封闭，无法被重定义
IsStaticMethod(taret, name)             |目标结构体的特定方法是否是静态方法
ValidateValue(target, value, onlyvalid) |使用目标结构体验证value，如果成功返回验证后的值，失败返回nil及一个错误消息
Validate(target)                        |目标是否是一个结构体类型


### System.Member

在上面的**Struct.GetMemeber**和**Struct.GetMembers**两个API，我们会获得member对象，同样有一个**System.Member**作为反射类型可以帮助我们获得内部的信息:

静态方法                                |描述
:---------------------------------------|:-----------------------------
GetType(member)                         |获得成员的类型
IsRequire(member)                       |成员是否不可为nil
GetName(member)                         |获得成员的名字
GetDefault(member)                      |获得成员的默认值

下面是一个例子:

```lua
require "PLoop"

PLoop(function(_ENV)
	struct "Location" (function(_ENV)
		x = Number
		y = Number
	end)

	for index, member in Struct.GetMembers(Location) do
		print(Member.GetName(member), Member.GetType(member))
	end
end)
```


枚举类型和结构体类型都是值类型，通常用于类型验证。而接口和类系统将为我们提供完整的面向对象系统。


## Class 类

类是从一组行为，特征类似的对象中抽象出来的，类为对象提供了具体的实现，通过接口和继承等机制也确保了代码的高复用性和扩展性。

Lua中的对象就是带有特定元表的table。

**PLoop**中，类定义主要由几部分组成:

### 类方法和对象方法

方法是供类或者其对象使用的函数，首先来看对象方法，对象方法是被对象使用的，它的第一个参数固定是self，代表对象本身:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		function SetName(self, name)
			self.name = name
		end

		function GetName(self, name)
			return self.name
		end
	end)

	Ann = Person()
	Ann:SetName("Ann")
	print("Hello " .. Ann:GetName()) -- Hello Ann
end)
```

和结构体的定义方式一样，我们使用函数作为类的定义体，在里面作为全局定义的函数会被注册为类的对象方法。之后，我们就可以构造对象，并调用这些方法。

类似*Person*这样的类，它的对象的元表将被实现成

```lua
{
	__index = { SetName = function, GetName = function },
	__metatable = Person,
}
```

**PLoop**的类会根据定义情况自行优化元表。

*Person*类可以直接访问它的对象方法`Person.SetName(Ann, "Ann")` 和 `Ann:SetName("Ann")`是一致的。

类也可以有只能自己访问的静态方法，和结构体的静态方法一样，需要使用`System.__Static__`特性:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Color" (function(_ENV)
		__Static__()
		function FromRGB(r, g, b)
			-- 对象的构建会在之后探讨
			return Color {r = r, g = g, b = b}
		end
	end)

	c = Color.FromRGB(1, 0, 1)
	print(c.r, c.g, c.b)
end)
```

静态方法通常是辅助方法，所以，不需要第一个参数是self，因为它不一定是处理类对象的方法。


### 元数据和对象构造

**元数据**算是Lua元表方法的一个超集，除了通常的对象使用的元表方法外，还有些供类本身使用的元数据：


Key            |Description
:--------------|:--------------
`__add`        |类对象的相加运算: a + b  -- a是类对象，下同
`__sub`        |类对象的相减运算: a - b
`__mul`        |类对象的相乘运算: a * b
`__div`        |类对象的除法运算: a / b
`__mod`        |类对象的取模运算: a % b
`__pow`        |类对象的幂运算:   a ^ b
`__unm`        |类对象的取负运算: - a
`__idiv`       |类对象的整除运算: a // b
`__band`       |类对象的与运算:   a & b
`__bor`        |类对象的或运算:   a | b
`__bxor`       |类对象的异或运算: a ~ b
`__bnot`       |类对象的非运算:   ~a
`__shl`        |类对象的左移运算: a << b
`__shr`        |类对象的右移运算: a >> b
`__concat`     |类对象的连接运算: a .. b
`__len`        |类对象的长度计算: #a
`__eq`         |类对象的相等判定: a == b
`__lt`         |类对象的小于判定: a < b
`__le`         |类对象不大于判定: a <= b
`__index`      |类对象的域查询:   return a[k]
`__newindex`   |类对象的新值处理: a[k] = v
`__call`       |类对象的调用:     a(...)
`__gc`         |类对象的GC处理，暂时没什么用途
`__tostring`   |类对象字符串转换: tostring(a)
`__ipairs`     |占位，非可用，请用集合处理替代
`__pairs`      |占位，非可用，请用集合处理替代
`__exist`      |类构建对象时根据参数检查是否复用存在的对象
`__field`      |对象的初始化字段和值
`__new`        |类构建对象时，生成将被封装成对象的table的方法
`__ctor`       |类对象构造体方法
`__dtor`       |类对象析构方法

Lua自带的元表方法都很常用，下面具体看**PLoop**特殊的元数据处理:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__ExistPerson = {}

		-- 对象存在检查，如果存在就无需创建新的了
		-- 它会接收到所有用于构建对象的参数
		-- 它的第一个参数是类本身，这样设计是为了处理子类的情况
		function __exist(cls, name)
			if __ExistPerson[name] then
				print("对象已经存在:" .. name)
				return __ExistPerson[name]
			end
		end

		-- 构造体函数，使用传入的参数初始化对象
		-- 第一个参数就是新创建的对象
		function __ctor(self, name)
			print("调用类的构造方法初始化:" .. name)
			__ExistPerson[name] = self
			self.name = name
		end

		-- 析构方法，通常用于解除引用，之后交给GC即可
		-- 第一个参数是将被销毁的对象
		function __dtor(self)
			print("销毁对象" .. self.name)
			__ExistPerson[self.name] = nil
		end
	end)

	o = Person("Ann")           -- 调用类的构造方法初始化:Ann

	-- true
	print(o == Person("Ann"))   -- 对象已经存在:Ann

	o:Dispose()                 -- 销毁对象Ann

	-- false
	print(o == Person("Ann"))   -- 调用类的构造方法初始化:Ann
end)
```

在上面例子中，我们用到了构造体方法，析构方法和存在检查方法。我们也会发现一个没有没定义的方法**Dispose**，这是一个**PLoop**保留的方法名，所有有析构方法的对象，都需要使用**Dispose**来销毁自身。

我们也可以直接使用**Dispose**替代`__dtor`来定义析构方法，使用类名替代`__ctor`来定义构造体方法。

`__new`元方法用于创建将被封装为对象的table，它可以用于返回其他系统创建的table，也可以用于更快速的创建对象，例如List的一个实现:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "List" (function(_ENV)
		function __new(cls, ...)
			return { ... }, true
		end
	end)

	v = List(1, 2, 3, 4, 5, 6)
end)
```

`__new`的调用方式和`__exist`一致，它会接收到class和所有的参数，系统会从它的结果读取两个值，第一个值如果是table，那么就将作为对象被封装，否则系统会自行创建一个新table作为对象。如果第二个值是true，那么，所有的参数将被抛弃，构造体方法只会接收到这个新对象。对于上面的List来说，因为一次性将数据都保存在对象中，就无需再依靠循环保存数据了。

`__field`元数据的值需要是table，它内部保存的键值对将在对象被创建时复制到对象中，如果配合**OBJECT_NO_RAWSEST**，**OBJECT_NO_NIL_ACCESS**两个平台选项，对象将只能使用这些被初始化的字段，同时因为操作这些字段不会触发`__index`和`__newindex`元表方法，访问速度也是最快的。

```lua
PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST = true, OBJECT_NO_NIL_ACCESS = true, }

require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__field     = {
			name    = "noname",
		}

		-- 也可以使用*field*关键字，因为`__field`可能拼写错误
		field {
			age     = 0,
		}
	end)

	o = Person()
	o.name = "Ann"
	o.age  = 12

	o.nme = "King"  -- Error : The object can't accept field that named "nme"
	print(o.gae)    -- Error : The object don't have any field that named "gae"
end)
```

作为总结，下面是一段模拟对象构建的处理:

```lua
-- 检查对象是否存在，存在就返回该对象
local object = __exist(cls, ...)
if object then return object end

-- 获得一个将被封装为对象的table
object = __new(cls, ...) or {}

-- 复制字段
field:Copyto(object)

-- 封装table为对象
setmetatable(object, objMeta)

-- 调用构造体方法
__ctor(object, ...)

-- 返回对象
return object
```

### 超类和继承

一个类可以也仅可以有一个超类，它将从超类中继承对象方法（静态方法不会被继承），元数据和其他资源（之后的属性和事件部分会详谈）。

类可以覆写超类的对象方法，元方法等，如果需要，可以使用**super**关键字来访问超类的对应方法:


```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		-- 对象方法
		function Test(self)
			print("Call A's method")
		end

		-- 构造体
		function A(self)
			print("Call A's ctor")
		end

		-- 析构方法
		function Dispose(self)
			print("Dispose A")
		end

		-- 元方法
		function __call(self)
			print("Call A Object")
		end
	end)

	class "B" (function(_ENV)
		inherit "A"  -- 也可以使用inherit(A)

		function Test(self)
			print("Call super's method ==>")
			super[self]:Test()
			super.Test(self)
			print("Call super's method ==<")
		end

		function B(self)
			super(self)
			print("Call B's ctor")
		end

		function Dispose(self)
			print("Dispose B")
		end

		function __call(self)
			print("Call B Object")
			super[self]:__call()
			super.__call(self)
		end
	end)

	-- Call A's ctor
	-- Call B's ctor
	o = B()

	-- Call super's method ==>
	-- Call A's method
	-- Call A's method
	-- Call super's method ==<
	o:Test()

	-- Call B Object
	-- Call A Object
	-- Call A Object
	o()

	-- Dispose B
	-- Dispose A
	o:Dispose()
end)
```

下面是一些细节解释:

* `inherit "A"`是`inherit(A)`的语法糖。

* 析构方法是由系统管理的，所以，类不需要自己调用超类的析构方法。

* 构造体方法需要主动调用`super(self, ...)`来调用超类的构造体方法，因为只有子类知道需要使用哪些参数去调用超类构造体。

* 对于对象方法和元表方法（包含`__new`和`__exist`），存在两种调用超类对应方法的方式:

	* `super.Test(self, ...)` 是一种简单方式，仅用于调用对象方法或者元方法

	* `super[self]:Test(...)`这是正规方式，因为super在访问Test之前先拿到self对象，它就可以获取到对象的类的版本，从而正确的调用超类方法。这一般用于多版本类（默认情况下，重定义类会形成两个版本，甚至多个），也用于访问对象资源，比如属性，事件等（后面会有详细的说明）。


### System.Class

**System.Class**是一个反射类型，用于提供关于class的内部信息:

Static Method                               |Description
:-------------------------------------------|:-----------------------------
GetExtends(target[, cache])                 |如果cache存在，将扩展的接口保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetFeature(target, name[, isobject])        |从目标中获取一个指定名字的类型特征（属性或事件等）。如果*isobject*不存在或为false，只获取在目标中定义的类型特征（包括静态）否则只获取对象特征（含继承获得。下同
GetFeatures(target, [cache[, isobject]])    |如果cache存在，将类型特征保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetMethod(target, name[, isobject])         |从目标中获取一个指定名字的方法
GetMethods(target[, cache[, isobject]])     |如果cache存在，将类型方法保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetMetaMethod(target, name[, isobject])     |从目标中获取一个指定名字的元方法
GetMetaMethods(target[, cache[, isobject]]) |如果cache存在，将元方法保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetObjectClass(object)                      |获取对象的类型
GetSuperClass(target)                       |获取目标的超类
GetSuperMethod(target, name)                |获取目标的超类方法
GetSuperMetaMethod(target, name)            |获取目标的超类元方法
GetSuperFeature(target, name)               |获取目标的超类特征
IsAbstract(target[, name])                  |检查目标是否是虚类，或者目标的指定名字的方法，元方法或特征是虚方法，虚元方法或虚特征
IsFinal(target[, name])                     |检查目标是否最终类，最终类无法被继承，或者目标的指定名字的方法，元方法或特征是最终定义，无法被子类覆盖
IsImmutable(target)                         |永远返回true，用类去验证对象，不会改变对象
IsObjectType(object, type)                  |对象是否是对应类型的实体
IsSealed(target)                            |检查目标是否封闭，无法被重定义
IsStaticMethod(target, name)                |检查目标指定名字的方法是静态方法
IsSubType(target, super)                    |检查目标是否是指定类或接口的子类型
ValidateValue(target, object)               |检查对象的类型是指定类型，或者是指定类型的子类型
Validate(target)                            |检查目标是否是一个类


### 类的多重版本

如果我们不使用`__Sealed__`封装这些类，我们可以再次定义它们，和结构体不同，重定义类不会清空以前的定义，而是覆盖上去。

首先看一个例子：

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	class "A" (function(_ENV)
		function test(self)
			print("hello")
		end
	end)

	o:test()   -- hi
	A():test() -- hello
end)
```

这里旧对象不会使用新定义的方法，所以同时我们有这个类的多个版本存在，这样的设计是为了避免新定义破坏了旧对象的执行（使用字段不同等，特别对于web请求来说，后台文件修改时，不应该影响正在返回数据的处理对象）。

如果我们需要某个类的对象保持更新，我们可以使用`System.__SingleVer__`特性来标记：

```lua
require "PLoop"

PLoop(function(_ENV)
	__SingleVer__()
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	class "A" (function(_ENV)
		function test(self)
			print("hello")
		end
	end)

	o:test()   -- hello
	A():test() -- hello
end)
```

这样旧对象也会使用新方法，我们只会有一个版本类实现。如果希望这个是类的默认行为的话，可以修改平台设定：

```lua
PLOOP_PLATFORM_SETTINGS = { CLASS_NO_MULTI_VERSION_CLASS = true }

require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	class "A" (function(_ENV)
		function test(self)
			print("hello")
		end
	end)

	o:test()   -- hello
	A():test() -- hello
end)
```

注意，这个设定对于多os-thread平台无效。

### 扩展方法

如果只是想追加处理的话，我们不需要进行完全的重定义：

```lua
require "PLoop"

PLoop(function(_ENV)
	__Sealed__()
	class "A" (function(_ENV)
		function test(self)
			print("hi")
		end
	end)

	o = A()

	function A:test2()
		print("hello")
	end

	o:test2()   -- hello
end)
```

我们只需要将函数赋给类就可以为它扩展新的对象方法或者静态方法。旧的对象也会获得新定义的方法。

这也可以用于扩展已经封闭了的类。也可以用于之后的接口。

我们不能对结构体类型使用这方式，因为结构体方式是被拷贝到数据table中的，如果我们给一个不含方法的结构体添加新方法，那么这个结构体会由不可变类型变成可变类型，这对系统影响太大，是不允许的。


## Interface 接口

接口是对功能的抽象，对于class来说，它也是多继承的补充机制。和class一样，也可以在它里面定义对象方法，静态方法和元数据。

类和接口都可以扩展任意数量的接口，使用**super**关键字时，它会根据继承的情况和优先级自行选择对应的方法（不限于超类的，也可以是接口提供的）。

接口使用`__init`替代`__ctor`（接口名也是同样），对应函数将作为接口的初始化方法，接口的初始化方法只接收self也就是对象这一个参数，并且接口的初始化是在类对象构建完成后，由系统自动调用，无法使用**super**或者其他机制来主动调用。

接口可以定义含有处理的方法，但也可以定义需要被扩展它的接口或者类实现的对象方法或元方法，或者其他资源（属性，事件等），只需要使用`System.__Abstract__`特性标记即可。特别的，被标记为`__Abstract__`的对象方法和元方法无法被**super**访问，因为它们应该是空处理方法，没有调用的价值。

来看一个具体的例子：

```lua
require "PLoop"

PLoop(function(_ENV)
	interface "IName" (function(self)
		__Abstract__()
		function SetName(self) end

		__Abstract__()
		function GetName(self) end

		-- 初始化方法
		function IName(self) print("IName Init") end

		-- 析构方法
		function Dispose(self) print("IName Dispose") end
	end)

	interface "IAge" (function(self)
		__Abstract__()
		function SetAge(self) end

		__Abstract__()
		function GetAge(self) end

		-- 初始化方法
		function IAge(self) print("IAge Init") end

		-- 析构方法
		function Dispose(self) print("IAge Dispose") end
	end)

	class "Person" (function(_ENV)
		extend "IName" "IAge"   -- 也可以使用`extend(IName)(IAge)`

		-- Error: attempt to index global 'super' (a nil value)
		-- 因为IName.SetName是abstract的，所以Person并没有超类方法可以调用
		-- 系统也不会创建super供Person类使用
		function SetName(self, name) super[self]:SetName(name) end

		function Person(self) print("Person Init") end

		function Dispose(self) print("Person Dispose") end
	end)

	-- Person Init
	-- IName Init
	-- IAge Init
	o = Person()

	-- IAge Dispose
	-- IName Dispose
	-- Person Dispose
	o:Dispose()
end)
```

如前所述，接口的初始化方法是在对象被创建后再被调用的，一般可以用于注册，进行预处理等。销毁对象的调用步骤和构造时的初始化步骤是正好相反的。这些由系统管理，所以定义时不需要在意。

### System.Interface

**System.Interface** 是一个反射类型，用于获取接口的内部信息，它和Class的API基本一致:

Static Method                               |Description
:-------------------------------------------|:-----------------------------
GetExtends(target[, cache])                 |如果cache存在，将扩展的接口保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetFeature(target, name[, isobject])        |从目标中获取一个指定名字的类型特征（属性或事件等）。如果*isobject*不存在或为false，只获取在目标中定义的类型特征（包括静态）否则只获取对象特征（含继承获得。下同
GetFeatures(target, [cache[, isobject]])    |如果cache存在，将类型特征保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetMethod(target, name[, isobject])         |从目标中获取一个指定名字的方法
GetMethods(target[, cache[, isobject]])     |如果cache存在，将类型方法保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetMetaMethod(target, name[, isobject])     |从目标中获取一个指定名字的元方法
GetMetaMethods(target[, cache[, isobject]]) |如果cache存在，将元方法保存在cache中并返回，否则返回一个迭代器供for循环遍历
GetSuperMethod(target, name)                |获取目标的超类方法
GetSuperMetaMethod(target, name)            |获取目标的超类元方法
GetSuperFeature(target, name)               |获取目标的超类特征
IsAbstract(target[, name])                  |检查目标的指定名字的方法，元方法或特征是虚方法，虚元方法或虚特征
IsFinal(target[, name])                     |检查目标是否最终接口，最终接口无法被继承，通常用作函数库，或者目标的指定名字的方法，元方法或特征是最终定义，无法被子类型覆盖
IsImmutable(target)                         |永远返回true
IsSealed(target)                            |检查目标是否封闭，无法被重定义
IsStaticMethod(target, name)                |检查目标指定名字的方法是静态方法
IsSubType(target, super)                    |检查目标是否是指定接口的子类型
ValidateValue(target, object)               |检查对象的类型是否是指定类型的子类型
Validate(target)                            |检查目标是否是一个接口


### Interface的匿名类

如果我们使用`System.__AnonymousClass__`特性在某个接口上，这个接口会自动创建一个扩展自己的匿名类，这个匿名类无法直接被访问，但我们可以使用接口来构建对象：

```lua
require "PLoop"

PLoop(function(_ENV)
	__AnonymousClass__()
	interface "ITask" (function(_ENV)
		__Abstract__() function Process()
		end
	end)

	o = ITask{ Process = function() print("Hello") end }

	o:Process()
end)
```

接口只能接受一个table做为初始化表来创建这个对象，通常要提供虚方法的实现。

但对于只有一个虚方法（含继承）的接口，我们可以使用更简单的形式：

```lua
require "PLoop"

PLoop(function(_ENV)
	__AnonymousClass__()
	interface "ITask" (function(_ENV)
		__Abstract__() function Process()
		end
	end)

	o = ITask(function() print("Hello") end)
	o:Process()
end)
```

我们可以直接提供虚方法的实现来构建对象。如果你希望所有接口都提供这样的行为，那么也可以修改平台设定（不推荐）：

```lua
PLOOP_PLATFORM_SETTINGS = { INTERFACE_ALL_ANONYMOUS_CLASS = true }

require "PLoop"

PLoop(function(_ENV)
	interface "ITask" (function(_ENV)
		__Abstract__() function Process()
		end
	end)

	o = ITask(function() print("Hello") end)
	o:Process()
end)
```

### 接口的所需类

我们可以使用**require**关键字指定扩展接口的类必须是某个类的子类:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" {}

	interface "IA" (function(_ENV)
		require "A"
	end)

	class "B" (function(_ENV)
		extend "IA" -- Error: interface.AddExtend(target, extendinterface[, stack]) - the class must be A's sub-class
	end)
end)
```


## Event 事件

**event**是类型特征的一种，用于通知外界对象的某些状态改变了：

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		-- 为Person类申明一个事件
		event "OnNameChanged"

		field { name = "anonymous" }

		function SetName(self, name)
			if name ~= self.name then
				-- 发起事件通知外界
				OnNameChanged(self, name, self.name)
				self.name = name
			end
		end
	end)

	o = Person()

	-- 绑定一个事件处理方法给对象
	function o:OnNameChanged(new, old)
		print(("%q -> %q"):format(old, new))
	end

	-- "anonymous" -> "Ann"
	o:SetName("Ann")
end)
```

事件处理方法有两种类型:

* 最终处理方法 - 之前例子中的用法就是最终处理方法，最终处理方法同时只能设定一个。
* 叠加处理方法 - 叠加处理方法通常使用在类的构造体方法或者接口的初始化方法中，用于绑定内部事件处理方法:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		-- 为Person类申明一个事件
		event "OnNameChanged"

		field { name = "anonymous" }

		function SetName(self, name)
			if name ~= self.name then
				-- 发起事件通知外界
				OnNameChanged(self, name, self.name)
				self.name = name
			end
		end
	end)

	-- 定义子类
	class "Student" (function(_ENV)
		inherit "Person"

		local function onNameChanged(self, name, old)
			print(("Student %s renamed to %s"):format(old, name))
		end

		function Student(self, name)
			self:SetName(name)
			self.OnNameChanged = self.OnNameChanged + onNameChanged
		end
	end)

	o = Student("Ann")

	function o:OnNameChanged(name)
		print("My new name is " .. name)
	end

	-- Student Ann renamed to Ammy
	-- My new name is Ammy
	o:SetName("Ammy")
end)
```

使用对象访问事件名例如`self.OnNameChanged`，会得到一个创建自**System.Delegate**的对象，实际最终处理方法和叠加处理方法这两个机能就源于这个Delegate对象。

我们可以使用下面的方法叠加处理方法

```lua
self.OnNameChanged = self.OnNameChanged + onNameChanged
```

也可以用下面的方式移除叠加的处理方法

```lua
self.OnNameChanged = self.OnNameChanged - onNameChanged
```

当事件发生时，如果这个对象有相应的Delegate对象（这个对象仅当被访问时被创建），那么这个Delegate对象会被调用来处理事件。

叠加的处理方法是按顺序添加的，所以，最先被加入的处理方法会最先被使用，然后依次调用下去，直到最后调用最终处理方法。这个过程中，如果某个处理方法返回true，整个调用链终止。

在某些场景中，我们需要禁止对象的事件处理，这可以利用Delegate的初始处理方法:

```lua
self.OnNameChanged:SetInitFunction(function() return true end)
```

初始方法如果存在，会最先被调用，只要它返回true就可以终止对象的事件处理了。


### 事件处理方法变更的处理

通常如果使用**PLoop**封装来自其他系统的对象，我们需要双向处理事件绑定:

* 如果对象的Delegate中绑定的处理方法变更，比如清空了，增加了等情况，我们需要通知其他系统，比如增加事件监听，或者移除事件监听等。

* 当其他系统的事件发生时，我们要触发对象的事件处理。

使用魔兽世界中的*Frame*控件来做介绍，无视掉其他细节，我们来看看如何做双向事件绑定处理:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Frame" (function(_ENV)
		__EventChangeHandler__(function(delegate, owner, eventname)
			-- delegate是绑定的处理方法发生改变的delegate对象
			-- owner是对象，也就是delegate对象的主人
			-- eventname是事件名字，这里就是OnEnter
			if delegate:IsEmpty() then
				-- 没有处理方法，无需监视，这里解除了注册
				owner:SetScript(eventname, nil)
			else
				-- 存在处理方法，需要注册到游戏引擎中
				if owner:GetScript(eventname) == nil then
					owner:SetScript(eventname, function(self, ...)
						-- 我们可以直接调用delegate对象，无需走event系统
						delegate(owner, ...)
					end)
				end
			end
		end)
		event "OnEnter"
	end)
end)
```

`System.__EventChangeHandler__`特性专为事件绑定变更处理方法，这样所有这个类的对象相应事件的delegate变更时，这个变更处理函数就会被调用，我们可以统一的进行处理。更进一步，我们可以用一个函数处理所有的事件:

```lua
require "PLoop"

PLoop(function(_ENV)
	local function changehandler (delegate, owner, eventname)
		if delegate:IsEmpty() then
			owner:SetScript(eventname, nil)
		else
			if owner:GetScript(eventname) == nil then
				owner:SetScript(eventname, function(self, ...)
					-- Call the delegate directly
					delegate(owner, ...)
				end)
			end
		end
	end

	function __WidgetEvent__(self)
		__EventChangeHandler__(changehandler)
	end

	class "Frame" (function(_ENV)
		__WidgetEvent__()
		event "OnEnter"

		__WidgetEvent__()
		event "OnLeave"
	end)
end)
```

### 静态事件

我们可以使用`__Static__`特性来标记某些事件为静态，这样它仅能被类或者接口使用:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__Static__()
		event "OnPersonCreated"

		function Person(self, name)
			OnPersonCreated(name)
		end
	end)

	function Person.OnPersonCreated(name)
		print("Person created " .. name)
	end

	-- Person created Ann
	o = Person("Ann")
end)
```

### 超类事件

如果超类或者接口的事件被覆写了，但我们有需要监听超类事件，我们可以使用**super[object].event**的方式来使用超类事件:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		-- declare an event for the class
		event "OnNameChanged"

		field { name = "anonymous" }

		function SetName(self, name)
			if name ~= self.name then
				-- Notify the outside
				OnNameChanged(self, name, self.name)
				self.name = name
			end
		end
	end)


	class "Student" (function(_ENV)
		inherit "Person"

		event "OnNameChanged"

		local function raiseEvent(self, ...)
			OnNameChanged(self, ...)
		end

		function Student(self)
			super(self)

			-- Use the super object access style
			super[self].OnNameChanged = raiseEvent
		end
	end)

	o = Student()

	function o:OnNameChanged(name)
		print("New name is " .. name)
	end

	-- New name is Test
	o:SetName("Test")
end)
```

如例子所示，子类可以监听超类的事件，并使用自己的事件传递下去。

### System.Event

**System.Event**是一个反射类型，可以用来获取事件的内部信息:

静态方法                                    |描述
:-------------------------------------------|:-----------------------------
Get(target, object[, nocreation])           |从对象中获取事件的处理delegate对象，如果nocreation不为true，那么会创建这个delegate对象如果不存在
GetEventChangeHandler(target)               |获取使用`__EventChangeHandler__`注册的函数
IsStatic(target)                            |事件是否是静态
Validate(target)                            |目标是否是一个事件

一个简单的例子:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__Static__()
		event "OnPersonCreated"
	end)

	for name, feature in Class.GetFeatures(Person) do
		if Event.Validate(feature) then
			print("event", name)
		end
	end
end)
```

## Property 属性

属性是对象的状态特征，我们也可以使用**field**指定的字段作为对象状态特征，但字段缺乏类型验证，我们也无法知道何时这些字段值被修改了。

属性系统提供了很多机制，诸如get/set，值的类型验证，值修改的处理方法，值修改的处理事件，默认值，默认值工厂等。

从一个简单的例子开始:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String }
		property "Age"  { type = Number }
	end)

	-- 如果类没有定义__ctor，我们可以使用这种初始化表机制
	-- 表中的所有键值会被赋给对象
	o = Person{ Name = "Ann", Age = 10 }

	print(o.Name)-- Ann
	o.Name = 123 -- Error : the Name must be string, got number
end)
```

类似于结构体的**member**关键字，**property**接收一个字符串作为属性名，一个table作为属性定义。table定义中的键是大小写无视的，下面是完整的设定清单:

字段            |用途
:---------------|:-------------
auto            |是否使用自动绑定机制，详见下面的例子
get             |用于获取对象属性值的方法，调用方式类似`return get(obj)`，也可以设置为**false**，表示该属性不可读
set             |用于设置对象属性值的方法，调用方式类似`set(obj, value)`，也可以设置为**false**，表示该属性不可写
getmethod       |获取属性值的对象方法名，调用方式类似`return obj[getmethod](obj)`
setmethod       |设置属性值的对象方法名，调用方式类似`obj[setmethod](obj, value)`
field           |实际保存属性值的字段，如果get/set或者getmethod/setmethod设置就无效。如果定义中没有设置field，set/get, getmethod/setmethod，那么系统会自动指定一个field，比如上面例子中的用法，这也是推荐做法。
type            |属性值的类型，如果这个类型是immutable的，当平台设定里面关闭类型验证时，属性值也会停止验证
default         |属性的默认值
event           |属性值变更时自动发起的事件，如果是字符串，会尝试用该字符串创建事件，仅用于使用field的属性
handler         |属性值变更时触发的处理方法，这是类或者接口内部自行处理对象属性变更的方法，仅用于使用field的属性
static          |true，如果希望定义为静态属性
indexer         |true，如果属性是索引属性
throwable       |true，如果属性的set方法会抛出错误
require         |true, 如果希望属性值不能为nil

我们依次来看一些使用例子:

### get/set

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		field { __name = "anonymous" }

		property "Name" {
			get = function(self) return self.__name end,
			set = function(self, name)  self.__name = name end,
		}
	end)

	print(Person().Name)
end)
```

### getmethod/setmethod

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		field { __name = "anonymous" }

		function SetName(self, name)
			self.__name = name
		end

		function GetName(self)
			return self.__name
		end

		property "Name" {
			get = "GetName", -- or getmethod = "GetName"
			set = "SetName", -- or setmethod = "SetName"
		}
	end)

	print(Person().Name)
end)
```


### property-throw

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		field { __name = "anonymous" }

		function SetName(self, name)
			if type(name) ~= "string" then
				throw("The name must be string")
			end
			self.__name = name
		end

		function GetName(self)
			return self.__name
		end

		property "Name" {
			get = "GetName", -- or getmethod = "GetName"
			set = "SetName", -- or setmethod = "SetName"
			throwable = true,
		}
	end)

	Person().Name = 123 -- Error: The name must be string
end)
```


### field & default

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { field = "__name", default = "anonymous" }
	end)

	obj = Person()
	print(obj.Name, obj.__name) -- anonymous   nil

	obj.Name = "Ann"
	print(obj.Name, obj.__name) -- Ann         Ann
end)
```

### default factory

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Age" { field = "__age", default = function(self) return math.random(100) end }
	end)

	obj = Person()
	print(obj.Age, obj.__age) -- 81   81
	obj.Age = nil   -- 下次访问时，值会被重新产生
	print(obj.Age, obj.__age) -- 88   88
end)
```

### property-event

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String, event = "OnNameChanged" }
	end)

	o = Person { Name = "Ann" }

	function o:OnNameChanged(new, old, prop)
		print(("[%s] %s -> %s"):format(prop, old, new))
	end

	-- [Name] Ann -> Ammy
	o.Name = "Ammy"
end)
```

### property-handler

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" {
			type = String, default = "anonymous",

			handler = function(self, new, old, prop)
				print(("[%s] %s -> %s"):format(prop, old, new))
			end
		}
	end)

	--[Name] anonymous -> Ann
	o = Person { Name = "Ann" }

	--[Name] Ann -> Ammy
	o.Name = "Ammy"
end)
```

### static property

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		__Static__()
		property "DefaultName" { type = String }

		property "Name" {
			type = String, default = function() return Person.DefaultName end,
		}
	end)

	Person.DefaultName = "noname"

	print(Person().Name) -- noname
end)
```

### 自动绑定

如果设置了*auto*启用自动绑定模式，并且属性本身没有定义get/set,getmethod/setmethod和field这些字段，那么系统会检查属性所属类型或者接口的方法（如果是静态属性查静态方法，非静态属性查对象方法（含继承）），以一个而名为"name"的属性为例:

* *setname*, *Setname*, *SetName*, *setName*将会被扫描，如果存在，这个方法会被保存到set字段中，被属性使用

* *getname*, *Getname*, *Isname*, *isname*, *getName*, *GetName*, *IsName*, *isname*将会被扫描，如果存在，这个方法会被保存到get字段中，被属性使用

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		function SetName(self, name)
			print("SetName", name)
		end

		property "Name" { type = String, auto = true }
	end)

	-- SetName  Ann
	o = Person { Name = "Ann"}

	-- SetName  Ammy
	o.Name = "Ammy"
end)
```

### 超类属性

如果类或者接口覆盖了继承的属性，类似event我们可以使用**super**关键字来访问超类属性处理:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String }
	end)

	class "Student" (function(_ENV)
		inherit "Person"

		property "Name" {
			Set = function(self, name)
				-- 保存到超类属性中
				super[self].Name = name
			end,
			Get = function(self)
				-- 读取超类属性值
				return super[self].Name
			end,
		}
	end)

	o = Student()
	o.Name = "Test"
	print(o.Name)   -- Test
end)
```

### 索引属性

我们还可以定义一种特殊的索引属性:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function( _ENV )
		__Indexer__()
		property "Items" {
			set = function(self, idx, value)
				self[idx] = value
			end,
			get = function(self, idx)
				return self[idx]
			end,
			type = String,
		}
	end)

	o = A()

	o.Items[1] = "Hello"

	print(o.Items[1])   -- Hello
end)
```

索引属性的定义table仅接受set, get, getmethod, setmethod, type and static这些设定。

也可以为索引属性的键指定类型:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function( _ENV )
		__Indexer__(String)
		property "Items" {
			set = function(self, idx, value)
				self[idx] = value
			end,
			get = function(self, idx)
				return self[idx]
			end,
			type = String,
		}
	end)

	o = A()

	-- Error: the Items's key must be string, got number
	o.Items[1] = "Hello"
end)
```


### Get/Set行为修饰

除了上述定义外，我们还可以对属性的访问行为进行调整。

对于属性的值设置，我们使用**System.PropertySet**来描述保存值时的处理:

```lua
__Flags__() __Default__(0)
enum "System.PropertySet" {
	Assign      = 0,  -- 直接保存
	Clone       = 1,  -- 保存值的拷贝
	DeepClone   = 2,  -- 保存值的深层拷贝
	Retain      = 4,  -- 旧值需要被Dispose处理
	Weak        = 8,  -- 值使用弱引用保存，可被回收
}
```

对于属性的值读取，我们使用**System.PropertyGet**来描述读取值时的处理:

```lua
__Flags__() __Default__(0)
enum "System.PropertyGet" {
	Origin      = 0,  -- 直接返回值
	Clone       = 1,  -- 返回值的拷贝
	DeepClone   = 2,  -- 返回值的深层拷贝
}
```

为了给属性指定这些行为，我们需要使用`System.__Set__`和`System.__Get__`这两个特性:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Data" (function(_ENV)
		extend "ICloneable"  -- 可复制类必须扩展这个接口

		local _Cnt = 0

		-- 实现Clone方法
		function Clone(self)
			return Data() -- for test, just return a new one
		end

		function Dispose(self)
			print("Dispose Data " .. self.Index)
		end

		function __ctor(self)
			_Cnt = _Cnt + 1
			self.Index = _Cnt
		end
	end)

	class "A" (function(_ENV)
		__Set__(PropertySet.Clone + PropertySet.Retain)
		__Get__(PropertySet.Clone)
		property "Data" { type = Data }
	end)

	o = A()

	dt = Data()

	o.Data = dt
	print(dt.Index, o.Data.Index)  -- 1  3
	o.Data = nil   -- Dispose Data 2
end)
```

### System.Property

**System.Property**是一个反射类型，用于提供property的信息：

Static Method                |Description
:----------------------------|:-----------------------------
IsGetClone(target)           |该属性返回值的拷贝
IsGetDeepClone(target)       |该属性返回值的深层拷贝
IsIndexer(target)            |该属性是否是索引属性
IsReadable(target)   		 |该属性是否可读
IsSetClone(target)           |该属性是否保存输入值的拷贝
IsSetDeepClone(target)       |该属性是否保存输入值的深层拷贝
IsRetainObject(target)       |该属性是否会Dispose旧的值（对象）
IsStatic(target)             |该属性是否是静态属性
IsWeak(target)               |该属性是否将值作为弱引用保存
IsWritable(target)           |该属性是否可写
GetDefault(target)           |获取属性的默认值
GetField(target)             |获取属性的保存字段
GetType(target)              |获取属性的类型
Validate(target)             |目标是否是一个属性

下面是一个简单例子:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" (function(_ENV)
		property "Name" { type = String }
		property "Age"  { type = Number }
	end)

	for name, feature in Class.GetFeatures(Person) do
		if Property.Validate(feature) then
			print(name, Property.GetType(feature))
		end
	end
end)
```

上面已经完整介绍了**PLoop**提供的所有类型，不过我们还有很多细节需要补充。


## 继承和优先级

一个类可以扩展多个接口，可以继承一个超类，超类也会继承其他超类和扩展其他的接口。

如果这些超类和接口中有同名的类型资源（方法，元方法，属性或者事件），那么系统在继承时，会选择最接近的：

* 检查超类，如果没有，检查超类的超类，依次继续下去。

* 检查接口，最后被扩展的接口会被优先检查。

这些调用都是系统完成，我们并不需要管理它，但我们也可以通过使用`System.__Abstract__`和`System.__Final__`两个特性来影响这个过程：

* 如果一个类型资源（方法，元方法，属性或者事件）被标记为`__Abstract__`，那么它的继承优先级最低。

* 如果一个类型资源被标记为`__Final__`，那么它的继承优先级最高。

下面是一个简单的例子：

```lua
require "PLoop"

PLoop(function(_ENV)
	interface "IA" (function(_ENV)
		__Final__()
		function Test(self)
			print("Hello IA")
		end

		__Abstract__()
		function Test2(self)
			print("Hello2 IA")
		end
	end)

	class "A" (function(_ENV)
		extend "IA"

		function Test(self)
			print("Hello A")
		end

		function Test2(self)
			print("Hello2 A")
		end
	end)

	o = A()
	o:Test()  -- Hello IA
	o:Test2() -- Hello2 A
end)
```

关于`__Final__` 特性还有一种特殊用法，我们可以在接口或者抽象类中定义`__Final__`的方法，然后在它的定义中使用对象的类来访问实际的方法：

```lua
require "PLoop"

PLoop(function(_ENV)
	interface "IA" (function(_ENV)
		local getObjectClass = Class.GetObjectClass

		__Final__() function Test(self)
			print("Call Test of IA")

			-- 获取对象的类，调用该类中定义的Test方法完成操作
			getObjectClass(self).Test(self)
		end
	end)

	class "A" { IA, Test = function(self) print("Call Test of A") end }

	o = A()

	-- Call Test of IA
	-- Call Test of A
	o:Test()
end)
```

对象会使用申明为最终的方法，但类会保留它自身定义的版本。


## 使用其他定义形式

### 使用字符串作为定义体

对于结构体，接口和类，我们可以使用字符串作为定义体，以便于某些情况下自动生成定义：

```lua
PLoop(function(_ENV)
	class "A" [[
		property "Name" { default = "anonymous" }
	]]

	print(A().Name)
end)
```

仅需要将`function(_ENV)`和`end)`替换成字符串的起始和结束即可。

### 使用table作为定义体

在[使用table来定义结构体](#使用table来定义结构体)中，我们已经看到如何用table定义结构体，同样，我们也可以使用table来定义接口和类：

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Person" {
		-- 定义静态事件
		-- 不过使用table定义并不能很好的使用事件
		OnPersonCreated = true,

		-- 定义对象事件
		OnNameChanged   = false,

		-- 定义属性，可以指定类型或者定义table
		Name = String,
		Age  = { type = Number, default = 0 },

		-- 定义对象方法
		SetName = function(self, name)
			self:OnNameChanged(name, self.Name)
			self.Name = name
		end,

		-- 定义构造体方法，也可以使用`__ctor`作为键
		function (self, name)
			Person.OnPersonCreated(name)
			self.Name = name
		end,
	}

	interface "IScore" {
		Person,      -- 如果是类，那么require它
		ICloneable,  -- 如果是接口，那么extend它
	}

	class "Student" {
		Person, -- 如果是类，那么inherit它
		IScore, -- 如果是接口，那么extend它
	}

	-- 我们可以在之后，再定义对象或者静态方法
	function Student:SetScore(score)
	end
end)
```


## 命名空间和匿名类型

**PLoop**使用命名空间来管理类型，我们可以将类型保存在树状的命名空间中，这样每种类型都有唯一的访问路径，比如**System.Collections.List**。我们也可以使用**import**关键字在私有环境中引入这些命名空间，这样这些类型可以在任何地方被使用。

通常类型在它们被定义时保存到命名空间中，下面的例子将为我们展示命名空间保存相关的所有场景：

```lua
require "PLoop"

PLoop(function(_ENV)
	-- 我们可以使用**namespace**关键字来为当前环境
	-- 申明一个命名空间，之后这个环境中创建的类型
	-- 都会保存在这个命名空间
	namespace "Test"

	class "A" (function(_ENV)
		-- 类型的定义体的的环境的所属命名空间就是这个
		-- 类型本身，这里就是class A，任何定义在这个
		-- 环境的类型，都将成为A的子命名空间。
		enum "Type" { Data = 1, Object = 2 }
	end)

	-- 如果我们定义类型时，名字使用了全路径，那么
	-- 这个类型会按照路径保存，和当前环境所属的
	-- 命名空间无关
	class "Another.B" (function(_ENV)
		enum "Type" { Data = 1, Object = 2 }
	end)

	print(A)      -- Test.A
	print(A.Type) -- Test.A.Type

	print(B)      -- Another.B
	print(B.Type) -- Another.B.Type
end)
```

我们也可以将不希望分享给它人的类型定义为匿名类型，只需要在定义时不指定名字即可：

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "Test"

	class "A" (function(_ENV)
		Type = enum { Data = 1, Object = 2 }

		print(Data)      -- 1
		print(Type.Data) -- 1
	end)

	-- 没有任何方式访问到A.Type
	print(A.Type)        -- nil
end)
```

### System.Namespace

**PLoop**同样提供一个反射类型**System.Namespace**用于获取namespace相关的信息:

静态方法                             |描述
:------------------------------------|:-----------------------------
ExportNamespace(env, ns[, override]) |将指定ns及其子命名空间保存到env环境中
GetNamespace([root,] path)           |使用路径获取对应的命名空间实体
GetNamespaces(root[, cache])         |获取所有子命名空间
GetNamespaceName(ns, onlyname)       |获取命名空间实体的路径或者名字
IsAnonymousNamespace(target)         |目标是否是一个匿名类型
Validate(target)                     |目标是否是一个命名空间实体


## 环境

私有环境是**PLoop**的基础元素。

### 隔离代码

**PLoop**中代码都需要在各个私有环境下被执行，这样我们不会因为使用全局变量等情况造成冲突。

```lua
require "PLoop"

PLoop(function(_ENV)
	function Test()
	end
end)

print(Test) -- nil

PLoop(function(_ENV)
	print(Test)  -- nil
end)
```

如果需要共享资源的话，我们应当将它们保存在类型中进行分享。

### 分享类型

我们可以为私有环境使用**import**关键字来导入其他命名空间，这样我们就可以在各个私有环境之间分享类型。

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "Test"

	class "A" (function(_ENV)
		enum "Type" { Data = 1, Object = 2 }
	end)
end)

PLoop(function(_ENV)
	print(A)      -- nil

	-- 我们可以直接访问根命名空间实体
	print(Test.A) -- Test.A

	-- 使用import来导入命名空间
	import "Test"

	-- 现在我们可以直接访问A
	print(A)      -- Test.A

	print(Data)   -- nil

	import "Test.A.Type"

	-- 对于被导入的命名空间，环境将之间使用ns[name]的方法
	-- 获取结果，而不关心它具体是什么
	print(Data)   -- 1
end)
```

### 特性和全局函数

在私有环境中定义全局函数时，我们可以使用各种特性来封装这些函数或者将这些函数注册到其他系统以备他用。

使用来自[PLoop_Web](https://github.com/kurapica/PLoop_Web)的一个例子：

```lua
require "PLoop_Web"

Application "WebApplication"(function(_ENV)
	-- 这个例子是将函数绑定到类似下面的http请求地址
	-- /nginx?var=request_uri
	-- __Route__特性用于将请求处理方法绑定到url地址
	-- __text__特性用于标记这个函数的返回结果将作为
	-- "text/plain"类型发送给浏览器
	__Route__ "/nginx"
	__Text__()
	function GetVars(context)
		return ngx.var[context.Request.QueryString["var"] or "nginx_version"]
	end
end)
```

### 使用命名空间作为调用者

我们在上面的例子中大量使用了**PLoop**，那么它对于系统来说，具体是什么呢？

它实际也是一个命名空间实体，所有的根命名空间都保存在它里面，不过它本身是匿名的，所以，无法通过路径访问它。

```lua
require "PLoop"

print(PLoop.System.Collections.List) -- System.Collections.List
```

类似于**PLoop**，我们可以将其他命名空间实体作为调用者来调用函数。

```lua
require "PLoop"

namespace "Test" (function(_ENV)
	enum "A" {}

	print(A)  -- Test.A
end)
```

如例子所见，如果我们用Test作为函数的调用者，那么这个函数的环境所属的命名空间就是调用者本身。

不过这种方式并不推荐，因为**PLoop**库仅确保`_G`中的**PLoop**是来自自身，类似**class**, **namespace**等关键字可能会来自其他的Lua库。为了确保不会和其他Lua库冲突，使用**PLoop**作为调用者是最简单的方式。（当然如果你确保了没有冲突的可能，这种写法也没有任何问题）


### 全局变量的读取

当私有环境访问自身不存在的全局变量时，私有环境会根据自身配置按照顺序进行查找：

* 查找这个环境所属的命名空间

* 查找这个环境**import**的命名空间

* 查找公共命名空间

* 尝试匹配根命名空间，比如访问**System**

* 查找基础环境，私有环境可以设置自己的基础环境，通常是`_G`

在命名空间中查找变量名的规则是:

* 对比命名空间的名字（路径最后部分，比如**System.Form**的名字是**Form**)，一致就返回该命名空间

* 直接使用`命名空间[变量名]`获取，通常结果会是子命名空间比如`System["Form"]`得到**System.Form**，也可能是类型，比如`System.Collections["List"]`，也可能是类型本身提供的资源，比如类的静态方法，枚举类型的枚举值等。

```lua
require "PLoop"

PLoop (function(_ENV)
	namespace "Test"

	enum "A" {}
	enum "Test2.B" {}

	namespace "Another"
end)

PLoop (function(_ENV)
	namespace "Test"

	-- 访问同命名空间中的类型
	print(A)     -- Test.A

	import "Test2"

	-- 访问import的命名空间中的类型
	print(B)     -- Test2.B

	-- 访问公共命名空间中的类型
	print(List)  -- System.Collections.List

	-- 访问根命名空间
	print(Another) -- Another

	-- 访问基础环境
	print(math)    -- table:xxxxxxx
end)
```

### 自动缓存机制

为了运行效率，私有环境访问到不存在自身的全局变量时，并且处于运行阶段时，私有环境会自动缓存这个值，不过在定义阶段时，环境不会自动缓存。

```lua
require "PLoop"

PLoop (function(_ENV)
	-- System.Collections.List  nil
	print(List, rawget(_ENV, "List"))

	_G.Dojob = function()
		print(List, rawget(_ENV, "List"))
	end
end)

-- System.Collections.List  System.Collections.List
Dojob()
```

当使用**PLoop**调用函数体时，里面的代码处于定义期，定义期的代码只会运行一次，而被访问到的全局变量等几乎只会被访问这一次，所以，此时缓存是没有意义的。

当我们调用`Dojob()`时，它的代码是运行阶段，我们可以反复的调用这个函数，那么这时我们需要缓存访问的变量，之后就不会再进行查询了。

这个过程完全由系统自行控制，通常不需要在意这个细节。它也不会造成问题。（多OS-thread平台下有些区别，以后有专门文档讨论）


## 重载

在之前的例子中我们演示了函数参数的类型验证，不过`System.__Arguments__`的设计目的是为了实现方法重载。

在List对象的创建中，我们有多种参数组合来进行构建，如果完全依赖手写判定来区分这些组合，将会非常困难，同时我们也经常需要处理同一个方法，不同输入的情况，每次都自行实现既难以维护，也不方便扩展。

而借助`__Arguments__`，我们可以将选择权交给系统：

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ String }
		function SetInfo(self, name)
			print("The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function SetInfo(self, age)
			print("The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function SetInfo(self, name, age)
			self:SetInfo(name)
			self:SetInfo(age)
		end
	end)

	o = Person()

	-- The name is Ann
	-- The age is 24
	o:SetInfo("Ann", 24)
end)
```

可见，我们可以将一组函数绑定成一个方法，也可以做成构造体函数，元方法等。

如果我们需要调用同名的其他重载方法，我们只需要使用`obj:method(xxx)`的方式使用不同参数调用即可。

### this和构造体方法

调用对象构造体(`__exist`, `__new`, `__ctor`)有些特别，因为不存在类似`obj:method(xxx)`这样的方式直接使用。

重载系统为此提供了**this**关键字（注意它并非class系统提供的，class系统本身没有重载功能），我们仅需要使用`this(...)`将所需参数传入即可:


```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ String }
		function __exist(self, name)
			print("[exist]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function __exist(self, age)
			print("[exist]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function __exist(self, name, age)
			this(self, name)
			this(self, age)
		end

		__Arguments__{ String }
		function __new(self, name)
			print("[new]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function __new(self, age)
			print("[new]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function __new(self, name, age)
			this(self, name)
			this(self, age)
		end

		__Arguments__{ String }
		function Person(self, name)
			print("[ctor]The name is " .. name)
		end

		__Arguments__{ NaturalNumber }
		function Person(self, age)
			print("[ctor]The age is " .. age)
		end

		__Arguments__{ String, NaturalNumber }
		function Person(self, name, age)
			this(self, name)
			this(self, age)
		end
	end)

	-- [exist]The name is Ann
	-- [exist]The age is 12
	-- [new]The name is Ann
	-- [new]The age is 12
	-- [ctor]The name is Ann
	-- [ctor]The age is 12
	o = Person("Ann", 12)
end)
```

请不要在其他重载方法中使用**this**关键字，它仅用于这三种构造体方法。


### 使用超类方法处理未处理的参数样式

当我们重写了超类的方法或者构造体等，但我们有需要使用超类的方法来处理我们不希望自己处理的参数样式时，我们可以使用`__Arguments__.Rest()`特性修饰函数来传递给超类方法:

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ String, NaturalNumber }
		function Person(self, name, age)
			print("The name is " .. name)
			print("The age is " .. age)
		end
	end)

	class "Student" (function(_ENV)
		inherit "Person"

		__Arguments__{ String, NaturalNumber, Number }
		function Student(self, name, age, score)
			this(self, name, age)
			self.score = score
			print("The score is " .. score)
		end

		-- Rest表示捕捉其他任何参数组合
		__Arguments__.Rest()
		function Student(self, ...)
			super(self, ...)
		end
	end)

	-- The name is Ann
	-- The age is 12
	-- The score is 80
	o = Student("Ann", 12, 80)
end)
```

### System.Variable

之前的例子中使用的参数都是指定类型，这些都是必须参数，如果需要定义可选参数，可变参数时，我们就需要提供额外的信息。

`__Arguments__`只接受一个参数，这个参数的类型是**System.Variables**，它是一个数组结构体，它的元素类型是**System.Variable**，下面是它的结构演示:

```lua
struct "Variable" (function(_ENV)
	name    = NEString      -- 变量的名字
	type    = AnyType       -- 变量类型
	optional= Boolean       -- 是否可选变量
	default = Any           -- 可选变量的默认值
	varargs = Boolean       -- 是否可变参数
	mincount= NaturalNumber -- 可变参数最小数目，默认0

	-- 返回一个指定类型和默认值的可选参数
	Optional= function(type, default) end

	-- 返回一个指定类型和最小数量的可变参数
	Rest    = function(type, mincount) end
end)
```

这是可选参数的例子：

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ Variable.Optional(Number, 0) }
		function SetInfo(self, age)
			print("The age is " .. age)
		end
	end)

	o = Person()

	-- The age is 0
	o:SetInfo()
end)
```

下面是可变参数的例子：

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{ Variable.Rest(String) }
		function AddChild(self, ...)
		end
	end)

	o = Person()

	-- Usage: Person:AddChild([... as System.String]) - the 2nd argument must be string, got number
	o:AddChild("Ann", 1)
end)
```

我们也可以提供更多的信息，这样产生的错误信息会更明确：

```lua
require "PLoop"

PLoop (function(_ENV)
	class "Person" (function(_ENV)
		__Arguments__{
			Variable("name", String, true, "anonymous"),
			Variable("age", NaturalNumber, true, 0)
		}
		function SetInfo(self, name, age)
			self:SetInfo(name)
			self:SetInfo(age)
		end
	end)

	o = Person()

	-- Usage: Person:SetInfo([name as System.String = "anonymous"], [age as System.NaturalNumber = 0]) - the 1st argument must be string, got boolean
	o:SetInfo(true)
end)
```

### 申明变量的简易版本

为了定义可选和可变参数不断的使用**Variable**是比较辛苦的用法，因为过于常用，**PLoop**为此提供了简便的处理方式：


```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String/"anonymous", Number * 0 }
	function Test(...)
		print(...)
	end

	-- anonymous
	Test(nil)

	-- Usage: Test([System.String = "anonymous"], [... as System.Number]) - the 2nd argument must be number, got string
	Test("hi", "next")
end)
```

我们可以使用`type/default`（`type/nil`同样可以使用）来申明可选参数，使用`type * mincount`来申明可变参数。



## Throw Exception 异常处理

通常来说，错误有两种，一种是返回给调用者，说明调用错误的，一种是自身发生的。前者我们希望错误位置在调用处，后者我们希望错误就在原处，这样便于我们进行处理。

这里涉及到两个问题，第一是，调用层次不明，例如使用类构造对象时，如果单纯使用`error(msg, 2)`那么，定位在**PLoop**核心文件，而不是实际调用处，加上子类调用超类的问题，函数自身是无法定位自己的调用层级的。

解决第一个问题的方案是在最外层使用pcall捕获异常，然后处理后，将错误定位在调用处，但这就造成了第二个问题，如果是我们函数自身的错误，如果pcall将错误位置定位到调用处了，我们无法知道具体的错误地点。

为了解决这个问题，**PLoop**引入了**throw**关键字和**System.Exception**组成异常处理系统。

Lua有个特别的设计，`error(msg)`只允许抛出字符串作为错误信息，但如果使用`pcall`来调用函数，函数内可以用`error(table)`的方式抛出table作为错误信息，对我们而言就是错误对象。

如果我们抛出错误对象指明调用错误，而自身内部错误发生时，依然时抛出字符串，在pcall调用处根据错误类型，就可以很好的区分开调用错误和自身错误。

下面看构造体调用错误的处理例子：

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" (function(_ENV)
		local function check(self)
			throw("something wrong")
		end

		function A(self)
			check(self)
		end
	end)

	o = A() -- something wrong
end)
```

在构造体方法及被其调用的函数中，我们可以使用**throw**关键字，将错误消息（也可以传入Exception对象，但没有必要自己构建）使用**throw**抛出，可以看到错误发生在对象构建的地方。

另一种情况，是在使用重载系统时，函数自身也很难定位自己的被调用层级（因为还有其他的封装特性），同样可以使用throw来处理：

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ String }:Throwable()
	function test(name)
		throw("we have throwable exception here")
	end

	test("HI") -- we have throwable exception here
end)
```

注意，需要申明这个重载是`:Throwable()`的，重载方法才会使用pcall来调用实际函数，才能完成这个操作。

注意**throw**在`_G`中是无法使用的，必须在某个**PLoop**的私有环境中（关键字有特殊的设计，它能获取调用自身的环境，但`_G`是无法处理的）。

如果希望自己处理异常处理，那么可以参照下面的例子：

```lua
require "PLoop"

PLoop(function(_ENV)
	function safecall(func, ...)
		local ok, ret = pcall(func, ...)

		if not ok then
			if type(ret) == "string" then
				error(ret, 0) -- 保留错误消息的调用层级
			else
				error(tostring(ret), 2) -- 异常对象可以直接转换为字符串
			end
		end
	end

	function test()
		throw("some thing not right")
	end

	safecall(test) -- 定位在这里: some thing not right
end)
```

你也可以将**throw**修改为**error**来看下定位的差别。


## 模板类

**PLoop**的类型定义是使用函数来完成的，函数的第一个参数是`_ENV`用于确保能正确运行于Lua 5.2以上版本。同时，我们也有可能使用它传入其他参数，来对定义进行调整，而这个结果就是模板类：

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__ { AnyType }
	class "Array" (function(_ENV, eletype)
		__Arguments__{ eletype * 0 }
		function __new(cls, ...)
			return { ... }, true
		end
	end)

	--Error: Usage: Anonymous([... as System.Integer]) - the 4th argument must be number, got string
	o = Array[Integer](1, 2, 3, "hi", 5)
end)
```

首先我们需要使用`System.__Arguments__`特性来申明这个**Array**类是一个模板类，它的默认类型是**System.AnyType**也就是任意的其他类型都可以被使用。

同时，**Array**的定义函数需要增加一个额外参数，用于传递模板类型。

类型定义之后，我们可以使用`Array[Integer]`这种形式传入真实类型，然后使用被创建的新类型。

我们也可以创建多类型的模板类：

```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__ { AnyType, AnyType }
	class "Dict" (function(_ENV, ktype, vtype)
		__Arguments__{ ktype, vtype }
		function Add(self, key, value)
			self[key] = value
		end
	end)

	o = Dict[{Integer, String}]()

	-- Error: Usage: Anonymous:Add(System.Integer, System.String) - the 2nd argument must be string, got boolean
	o:Add(1, true)
end)
```

因为定义形式一样，也可以为定义接口(interface)模板或者结构体(struct)模板类型。

因为类型的定义实际是函数，那么我们也可以使用非类型参数来生成模板类型:


```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ Number, Number }
	struct "FixString" (function(_ENV, min, max)
		__base = String

		function __valid(val)
			return (#val > max or #val < min) and "the %s length must between [" .. min .. "," .. max .. "]"
		end
	end)

	V1_3 = FixString[{1, 3}]

	-- true 同样参数的模板类型不会重复生成
	print(V1_3 == FixString[{1, 3}])

	-- 我们可以获得模板类型的原型和参数
	-- FixString	1	3
	print(Struct.GetTemplate(V1_3), Struct.GetTemplateParameters(V1_3))

	-- Error:  the value length must between [1,3]
	a = V1_3("Hello")
end)
```

上面定义的模板类型，必须传入实际类型后才能被正确使用，但如果希望模板类型可被使用的话，也可以在`__Arguments`特性申明后，增加一次调用来传入模板参数:


```lua
require "PLoop"

PLoop(function(_ENV)
	__Arguments__{ Number, Number }(1, 4)
	struct "FixString" (function(_ENV, min, max)
		__base = String

		function __valid(val)
			return (#val > max or #val < min) and "the %s length must between [" .. min .. "," .. max .. "]"
		end
	end)

	-- Error: the value length must between [1,4]
	a = FixString("Hello")
end)
```


## System.Module

**PLoop**使用私有环境来隔离代码，但对于项目来说，我们依然需要它们之间能共享些资源。

为了对项目进行管理，**PLoop**提供了**System.Module**类，它的对象基于**PLoop**的私有环境系统定义的。

以一个例子开始：

```lua
require "PLoop"

_ENV = Module "TestMDL" "1.0.0"

namespace "Test"

__Async__()
function dotask()
	print(coroutine.running())
end
```

`Module "TestMDL"`是`Module("TestMLD")`的省略写法，它用来创建了一个Module对象，然后我们调用它，并传入一个版本号字符串（可以为空字符串），之后当前代码（仅限于这个文件）的执行环境会被修改为这个Module对象。使用`_ENV =`是为了确保在任何Lua5.1以上版本中都能使用。

之后，我们就可以随意使用**PLoop**提供的各种功能。

### child-modules 子模组

一个Module对象可以有多个子模组：

```lua
_ENV = Module "TestMDL.SubMDL" "1.0.0"

enum "A" {}

print(A) -- Test.A

dotask() -- thread: 02E7F75C	false

function dosubtask()
end
```

```lua
_ENV = Module "TestMDL.SubMDL2" "1.0.0"

print(dosubtask) -- nil
```

一个模组可以用任意多的子模组，但仅能有一个父模组，所以存在一个根模组，它的全局变量将被所有子模组共享。

子模组可以访问父模组的全局变量，而根模组可以访问`_G`中存有的全局变量，同样它们采用访问时缓存的模式来确保运行效率。

子模组被创建时，会使用父模组中申明的命名空间，除非主动使用**namespace**关键字来覆盖它。

子模组无法访问兄弟模组中定义全局变量，不过它们可以通过命名空间共享类型。

你可以无限制的创建子模组类似：

```lua
Module "TestMDL.SubMDL2.SSubMDL.XXXX"
```

依照这个模式，整个项目会被保存在一个树状的模组系统中。命名空间用于保存类型，而模组则用来保存代码。


## Attribute 特性系统

在上面的处理中，我们接触到了很多的内置特性，都是用于修改目标的行为。

### System.IAttribute

我们需要扩展**System.IAttribute**接口或者它的扩展接口来定义特性类：

* **System.IInitAttribute**     代表用于修改目标的定义的接口
* **System.IApplyAttribute**    代表用于修改目标的接口，类似__Flags__
* **System.IAttachAttribute**   代表用于附着数据给目标的接口，也可以用于将目标注册到某些系统等操作

它提供了一些虚属性可被覆盖:

* AttributeTarget   - 特性的目标类型，位标识枚举类型
	* System.AttributeTargets.All         (默认)
	* System.AttributeTargets.Function  - 普通Lua函数，事件处理方法
	* System.AttributeTargets.Namespace - 命名空间
	* System.AttributeTargets.Enum      - 枚举类型
	* System.AttributeTargets.Struct    - 结构体
	* System.AttributeTargets.Member    - 结构体成员
	* System.AttributeTargets.Method    - 结构体方法，对象方法，元方法等
	* System.AttributeTargets.Interface - 接口
	* System.AttributeTargets.Class     - 类
	* System.AttributeTargets.Object    - 对象
	* System.AttributeTargets.Event     - 事件
	* System.AttributeTargets.Property  - 属性

* Inheritable       - 特性是否可继承, 默认 false

* Overridable       - 特性附着的数据是否可覆盖, 默认 true

* Priority          - 特性的优先级，越高越先被使用
	* System.AttributePriority.Highest
	* System.AttributePriority.Higher
	* System.AttributePriority.Normal  (默认)
	* System.AttributePriority.Lower
	* System.AttributePriority.Lowest

* SubLevel          - 特性的优先级次级，数字，同样优先级的特性，SubLevel越高越先被使用, 默认 0

共有三种类型的特性，初始化特性在目标定义前使用，应用特性在目标定义时使用，附着特性在目标定义后被使用：

### System.IInitAttribute 初始化特性

初始化特性用于修改目标的定义，通常用于枚举类型或者函数：

```lua
require "PLoop"

PLoop(function(_ENV)
	class "__SafeCall__" (function(_ENV)
		extend "IInitAttribute"

		local function checkret(ok, ...)
			if ok then return ... end
		end

		--- modify the target's definition
		-- @param   target                      the target
		-- @param   targettype                  the target type
		-- @param   definition                  the target's definition
		-- @param   owner                       the target's owner
		-- @param   name                        the target's name in the owner
		-- @param   stack                       the stack level
		-- @return  definition                  the new definition
		function InitDefinition(self, target, targettype, definition, owner, name, stack)
			return function(...)
				return checkret(pcall(definition, ...))
			end
		end

		property "AttributeTarget" { default = AttributeTargets.Function + AttributeTargets.Method }
	end)

	__SafeCall__()
	function test1()
		return 1, 2, 3
	end

	__SafeCall__()
	function test2(i, j)
		return i/j
	end

	print(test1()) -- 1, 2, 3
	print(test2()) -- nothing
end)
```

这种类型必须扩展**System.IInitAttribute**并且覆盖**InitDefinition**虚方法，这个方法中的definition就是目标的定义，对于枚举类型来说，就是含有枚举值的table，对于函数，就是它本身。如果这个方法返回了一个新的值，这个值将被作为新的定义被继续使用。

### System.IApplyAttribute 应用特性

这种特性用来对目标进行调整，通常是系统的内置特性使用，以`__Sealed__`为例:

```lua
class "__Sealed__" (function(_ENV)
	extend "IApplyAttribute"

	--- apply changes on the target
	-- @param   target                      the target
	-- @param   targettype                  the target type
	-- @param 	manager 					the definition manager of the target
	-- @param   owner                       the target's owner
	-- @param   name                        the target's name in the owner
	-- @param   stack                       the stack level
	function ApplyAttribute(self, target, targettype, owner, name, stack)
		if targettype == AttributeTargets.Enum then
			Enum.SetSealed(target)
		elseif targettype == AttributeTargets.Struct then
			Struct.SetSealed(target)
		elseif targettype == AttributeTargets.Interface then
			Interface.SetSealed(target)
		elseif targettype == AttributeTargets.Class then
			Class.SetSealed(target)
		end
	end

	property "AttributeTarget" { default = AttributeTargets.Enum + AttributeTargets.Struct + AttributeTargets.Interface + AttributeTargets.Class }
end)
```

这些类型需要扩展**System.IApplyAttribute**，并覆盖**ApplyAttribute**虚方法。这类基本只被系统定义和使用。

对于**ApplyAttribute**方法，它有一个特别的参数*manager*，如果target是struct，interface或者class，那么manager就是它们的定义环境，通过它，我们可以实现一些危险但很有用的功能，比如定义一些通用的类型资源：

```lua
require "PLoop"

PLoop(function(_ENV)
	class "__Name__" (function(_ENV)
		extend "IApplyAttribute"

		--- apply changes on the target
		-- @param   target                      the target
		-- @param   targettype                  the target type
		-- @param 	manager 					the definition manager of the target
		-- @param   owner                       the target's owner
		-- @param   name                        the target's name in the owner
		-- @param   stack                       the stack level
		function ApplyAttribute(self, target, targettype, manager, owner, name, stack)
			if manager then
				Environment.Apply(manager, function(_ENV)
					property "Name" { type = String }
				end)
			end
		end

		property "AttributeTarget" { default = AttributeTargets.Interface + AttributeTargets.Class }
	end)

	__Name__()
	class "A" {}

	A().Name = 123 -- Error: the Name must be string, got number
end)
```

这是一个比较危险的机能，请按需使用。


### System.IAttachAttribute 附着特性

这种特性在目标的定义完成后，被使用，通常用于附着数据或者将目标注册到其它系统（因为此时所有对它的修改都已经完成）。

```lua
PLoop(function(_ENV)
	class "__DataTable__" (function(_ENV)
		extend "IAttachAttribute"

		--- apply changes on the target
		-- @param   target                      the target
		-- @param   targettype                  the target type
		-- @param   owner                       the target's owner
		-- @param   name                        the target's name in the owner
		-- @param   stack                       the stack level
		function AttachAttribute(self, target, targettype, owner, name, stack)
			return self.DataTable
		end

		property "AttributeTarget" { default = AttributeTargets.Class }

		property "DataTable" { type = String }
	end)

	__DataTable__{ DataTable = "Persons" }
	class "Person" {}

	-- Persons
	print(Attribute.GetAttachedData(__DataTable__, Person))
end)
```

这种类型需要扩展**System.IAttachAttribute**接口并覆盖**AttachAttribute**虚方法，这个方法的返回值会被保存，便于之后查询。

### System特性

#### `__Abstract__`

用于标记一个类为抽象类，抽象类无法构建对象。或者标记方法，事件，属性为虚方法，虚方法需要（但不是必须）被子类型实现。

特性目标类型:
* System.AttributeTargets.Class
* System.AttributeTargets.Method
* System.AttributeTargets.Event
* System.AttributeTargets.Property


#### `__AutoCache__`

用于标记一个类，它的对象将缓存自身访问到的对象方法，以保证下次访问时无需通过元表进行访问。但如果类开启了超类对象访问并且它覆盖了超类的方法或者资源，那么自动缓存机制不会被加入。同时，因为方法被缓存，对象也无法使用类重定义后的新方法。

特性目标类型:
* System.AttributeTargets.Class

用法：

```lua
require "PLoop"

PLoop(function()
	__AutoCache__()
	class "A" { Test = function() end}

	o = A()
	print("GET", rawget(o, "Test")) -- GET	nil
	o:Test()
	print("GET", rawget(o, "Test")) -- GET	function: 0x015be630
end)
```


#### `__AnonymousClass__`

详细信息见[Interface的匿名类](#interface的匿名类)

特性目标类型:
* System.AttributeTargets.Interface

#### `__AutoIndex__`

详细信息见[enum 枚举类型](#enum-枚举类型)

特性目标类型:
* System.AttributeTargets.Enum

#### `__Arguments__`

详细信息见[重载](#重载)以及[模板类](#模板类)

特性目标类型:
* System.AttributeTargets.Struct
* System.AttributeTargets.Interface
* System.AttributeTargets.Class
* System.AttributeTargets.Function
* System.AttributeTargets.Method


#### `__Async__`

详细信息见[特性(Attribute)和协程池(Thread Pool)](#特性attribute和协程池thread-pool)

Attribute Targets:
* System.AttributeTargets.Function
* System.AttributeTargets.Method

#### `__Base__`

详细信息见[struct 结构体](#struct-结构体)

特性目标类型:
* System.AttributeTargets.Struct

#### `__Default__`

详细信息见[enum 枚举类型](#enum-枚举类型)和[struct 结构体](#struct-结构体)

特性目标类型:
* System.AttributeTargets.Enum
* System.AttributeTargets.Struct
* System.AttributeTargets.Member

#### `__Delegate__`

封装目标函数来使用

特性目标类型:
* System.AttributeTargets.Function
* System.AttributeTargets.Member

用法：

```lua
require "PLoop"

PLoop(function(_ENV)
	function decorate(func, ...)
		print("Call", func, ...)
		return func(...)
	end

	__Delegate__(decorate)
	function test() end

	-- Call function: 02E7B1C8  1   2   3
	test(1, 2, 3)
end)
```

#### `__EventChangeHandler__`

详细信息见[事件处理方法变更的处理](#事件处理方法变更的处理)

特性目标类型:
* System.AttributeTargets.Event

#### `__Final__`

设置类或者接口为最终，最终类无法被继承，最终接口无法被其他类型扩展。或者用于标记方法，属性，事件为最终，它们不应被覆盖。

特性目标类型:
* System.AttributeTargets.Class
* System.AttributeTargets.Interface
* System.AttributeTargets.Method
* System.AttributeTargets.Event
* System.AttributeTargets.Property

#### `__Flags__`

详细信息见[enum 枚举类型](#enum-枚举类型)

特性目标类型:
* System.AttributeTargets.Enum

#### `__Get__`

详细信息见[Get/Set行为修饰](#getset行为修饰)

特性目标类型:
* System.AttributeTargets.Property

#### `__Indexer__`

详细信息见[索引属性](#索引属性)

特性目标类型:
* System.AttributeTargets.Property

#### `__Iterator__`

详细信息见[特性(Attribute)和协程池(Thread Pool)](#特性attribute和协程池thread-pool)

Attribute Targets:
* System.AttributeTargets.Function
* System.AttributeTargets.Method

#### `__Namespace__`

为下一个创建的类型设置姓名空间

特性目标类型:
* System.AttributeTargets.All

用法：

```lua
require "PLoop"

PLoop(function(_ENV)
	namespace "Test"

	__Namespace__ "MyNS"
	class "A" {}

	print(A)   -- MyNS.A
end)
```

#### `__NoNilValue__`

从类对象不存在的字段设置读取值是非法的。

特性目标类型:
* System.AttributeTargets.Class

用法：

```lua
require "PLoop"

PLoop(function(_ENV)
	__NoNilValue__()
	class "A" {}

	o = A()
	v = o.age -- Error: The object don't have any field that named "age"
end)
```

我们也可以给一个类进行标记，使它在任何平台设置下都可以被读取：

```lua
PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST = true, OBJECT_NO_NIL_ACCESS = true }

require "PLoop"

PLoop(function(_ENV)
	__NoNilValue__(false)
	class "A" {}

	print(A().Test) -- nil
end)
```

#### `__NoRawSet__`

向类对象不存在的字段设置值是非法的。

特性目标类型:
* System.AttributeTargets.Class

用法：

```lua
require "PLoop"

PLoop(function(_ENV)
	__NoRawSet__()
	class "A" {}

	o = A()
	o.age = 10 -- Error: The object can't accept field that named "age"
end)
```

我们也可以给一个类进行标记，使它在任何平台设置下都可以被赋值：

```lua
PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST = true, OBJECT_NO_NIL_ACCESS = true }

require "PLoop"

PLoop(function(_ENV)
	__NoRawSet__(false)
	class "A" {}

	A().Test = 123 -- Okay
end)
```

即便开启了禁止写入模式，我们依然可以使用函数覆盖对象的方法：

```lua
PLOOP_PLATFORM_SETTINGS = { OBJECT_NO_RAWSEST = true, OBJECT_NO_NIL_ACCESS = true }

require "PLoop"

PLoop(function(_ENV)
	class "A" { Test = function() end }

	o = A()
	o.Test = 123    -- 错误
	o.Test = print  -- 正常
	o.Test1= print  -- 错误
end)
```

#### `__ObjectAttr__`

用于标记类，这样特性系统可以使用在它生成的对象上。

特性目标类型:
* System.AttributeTargets.Class

用法：:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "__Reg__" (function(_ENV)
		extend "IAttachAttribute"

		function AttachAttribute(self, target, targettype)
			print("Attach To", target.name)
		end

		property "AttributeTarget"  { set = false, default = AttributeTargets.Object }
	end)

	__ObjectAttr__()
	class "A" { name = String }

	__Reg__()
	A{ name = "Ann" } -- Attach To Ann
end)
```

#### `__ObjFuncAttr__`

向目标类的对象写入新函数时，函数将被传入特性系统被调整（目标类型为function）

特性目标类型:
* System.AttributeTargets.Class

用法：

```lua
require "PLoop"

PLoop(function(_ENV)
	__ObjFuncAttr__()
	class "A" {}

	o = A()

	__Async__()
	function o:Test()
		print(coroutine.running())
	end

	o:Test() -- thread: 02F195E8
end)
```

如果这个类同时被标识为`__NoRawSet__`，我们依然可以向它赋予任意的函数值，因为`__ObjFuncAttr__`特性表明这个类的对象将被用来作为函数的容器。


#### `__ObjectSource__`

目标类的对象会被记录构造位置。

特性目标类型:
* System.AttributeTargets.Class

用法：

```lua
require "PLoop"

PLoop(function(_ENV)
	__ObjectSource__()
	class "A" {}

	o = A()

	print(Class.GetObjectSource(o)) -- @path_to_file\file.lua:7
end)
```

#### `__Require__`

设置一个接口的所需类，参考[接口的所需类](#接口的所需类)

特性目标类型:
* System.AttributeTargets.Interface


#### `__Return__`

为函数或方法绑定返回值类型进行验证

特性目标类型:
* System.AttributeTargets.Function
* System.AttributeTargets.Method

用法：

如果验证失败，因为调用已经完成，系统会尝试定位函数定义位置：

```lua
require "PLoop"

PLoop(function(_ENV)
	__Return__{ String }
	function Test() return 1 end

	-- Error: path_to_file:5: The Test Return: System.String - the 1st return value must be string, got number
	Test()
end)
```

我们可以依次绑定多种返回值格式:

```lua
require "PLoop"

PLoop(function(_ENV)
    __Return__{ String } { Boolean }
    function Test() return 1 end

    -- lua: path_to_file:5: The Test should return:
    --  Return: System.String
    --  Return: System.Boolean
    Test()
end)
```

类似`__Arguments__`, 我们也可以使用可选和可变参数定义形式:

```lua
require "PLoop"

PLoop(function(_ENV)
    __Return__{ String/"hello", Number * 0 }
    function Test() return nil, 1, 2, 3 end

    -- hello    1   2   3
    print(Test())
end)
```

大多数情况下，我们用于需要限定子类申明方法的返回值类型的接口和超类：

```lua
require "PLoop"

PLoop(function(_ENV)
    interface "IA" (function(_ENV)
        __Return__{ String, Number * 1 }:AsInheritable()
        __Abstract__() function Test() end
    end)

    class "A" { IA, Test = function() return "hi" end }

    -- Error: path_to_file:9: The A.Test Return: System.String, ... as System.Number - the ... must contains at least 1 return values
    A():Test()
end)
```


#### `__Sealed__`

封闭枚举，结构体，接口或者类，这样它们无法被重定义。

特性目标类型:
* System.AttributeTargets.Enum
* System.AttributeTargets.Struct
* System.AttributeTargets.Interface
* System.AttributeTargets.Class

#### `__Set__`

详细信息见[Get/Set行为修饰](#getset行为修饰)

特性目标类型:
* System.AttributeTargets.Property

#### `__SingleVer__`

详细信息见[类的多重版本](#类的多重版本)

特性目标类型:
* System.AttributeTargets.Class

#### `__Static__`

设置方法，属性或者事件为静态，只能被类型自身使用。

特性目标类型:
* System.AttributeTargets.Method
* System.AttributeTargets.Event
* System.AttributeTargets.Property

#### `__Super__`

为目标设置一个超类。

特性目标类型:
* System.AttributeTargets.Class

#### `__SuperObject__`

目标的对象是否使用超类对象访问形式，形如`super[self]:Method()`, `super[self].Name = xxx`.

特性目标类型:
* System.AttributeTargets.Class

用法：
```lua
-- 确保类A使用超类对象访问形式
__SuperObject__(true)
class "A" {}

-- 确保类B不使用超类对象访问形式
__SuperObject__(false)
class "B" {}
```


#### `__Throwable__`

标记属性的Set方法为throwable，详见[property-throw](#property-throw).

特性目标类型:
* System.AttributeTargets.Property


## keyword 关键字

### 全局关键字

**PLoop**提供两种关键字，一种是全局的，可以在所有**PLoop**的私有环境中使用:

* namespace  -- 为当前环境申明命名空间
* import     -- 为当前环境导入命名空间
* export     -- 导出内容到当前环境
* enum       -- 定义新枚举类型
* struct     -- 定义新结构体类型
* interface  -- 定义新接口类型
* class      -- 定义新类
* throw      -- 抛出异常
* with 	     -- 和System.IAutoClose对象一同使用，用于自动调用对象的Open和Close方法

#### export 关键字

关键字**export**是为了多os thread平台设计的：

```lua
PLOOP_PLATFORM_SETTINGS = { MULTI_OS_THREAD = true }

require "PLoop"

PLoop(function(_ENV)
	export {
		-- 缓存全局变量
		ipairs 	= ipairs,

		-- 也可以直接使用全局变量名
		"pairs",

		-- 导入类型，系统能直接获取它的名字
		-- 所以无需指定
		List,
	}

	_G.test = function()
		print("hi")
	end
end)

-- [PLoop: Warn]The [print] is auto saved to table: 030066C8, need use 'export{ "print" }'@path_to_file\file.lua:16
test()
```

在多os-thread模式中，**PLoop**会警告我们需要使用`export { "print" }`来导入*print*函数。

**export**关键字会将table中的内容直接保存在当前环境中，那么既然**PLoop**的私有环境可以自动缓存变量，我们还需要这么处理呢？

比较不幸的是，自动缓存机制在多os-thread环境下的运行机制有些差别，运行期，我们必须避免环境table的rehash问题造成多os-thread访问冲突，为了解决这个问题，**PLoop**另外使用了一个缓存表，每次新值加入时，新的表会被用来替换它，通过无rehash的处理来避免冲突。

但这就导致了，当我们通过私有环境获取自动缓存的全局变量实际时需要通过一次元表调用才能拿到，这虽然开销很小，但如果使用**export**我们可以完全去掉这开销。这对于写库是很重要的做法。

对于非多os-thread平台来说，也就是Lua常对应的平台，它可以配合[写非法全局变量](#写非法全局变量)来使用，我们可以将需要被定义全局变量都在**export**中申明，这样任意其他的全局变量赋值都是非法的：


```lua
PLOOP_PLATFORM_SETTINGS = { GLOBAL_VARIABLE_FILTER = function() return true end, GLOBAL_VARIABLE_FILTER_USE_WARN = true }

require "PLoop"

PLoop(function(_ENV)
	export {
		-- declare constant
		CONST_VAR_DATA  = 1,

		-- declare other global variables
		dotask 			= false,
	}

	function dotask() -- it's ok now
	end

	-- [PLoop: Warn]There is an illegal assignment for "test"@path_to_file\file.lua:17
	function test()
	end
end)
```

#### with 关键字

**System.IAutoClose**是一个很简单的接口:

```lua
interface "System.IAutoClose" (function(_ENV)
    __Abstract__() function Open(self) end
    __Abstract__() function Close(self, error) end
end)
```

它定义了打开和关闭资源的方法，可用于文件，数据库连接等场合。**with**关键字可以接受多个IAutoClose对象，并且自动调用打开和关闭方法，不管是否存在错误:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" { IAutoClose,

		Open = function(self)
			print( "Open " .. self.name )
		end,

		Close = function(self, err)
			print("Close " .. self.name .. (err and (" with " .. err) or " without error"))
		end,
	}

	-- Open task
	-- process task
	-- Close task without error
	with(A{ name = "task"})(function(obj)
		print("process " .. obj.name)
	end)

	-- Open task
	-- Open task2
	-- process task, task2
	-- Close task with path\test.lua:23: 2333
	-- Close task2 with path\test.lua:23: 2333
	-- Catch error:path\test.lua:23: 2333
	with(A{ name = "task"}, A{ name = "task2"})(function(obj, obj2)
		print("process " .. obj.name .. ", " .. obj2.name)
		error("2333")
	end, function(err)
		print("Catch error:" .. err)
	end)
end)
```

如例子所示，第二个方法被用于捕获错误，如果不指定，那么将直接使用error方法将错误继续抛出，直到它被处理。

我们可以获得所有内部处理的返回值:

```lua
require "PLoop"

PLoop(function(_ENV)
	class "A" { IAutoClose }

	-- 1	2	3	4
	print(with(A())(function(obj)
		return 1, 2, 3, 4
	end))
end)

```

下面是来源于实际DB处理的一个例子（参考System.Data系统）:

```lua
function RecordLastLogin(id)
	-- 创建DB上下文，打开数据库连接
	with(MyDBContext())(function(ctx)
		-- 启动数据库事务
		with(ctx.Transaction)(function(trans)
			-- 查询并锁定目标用户数据
			local user = ctx.Users:Lock{ id = id }:First()
			if user then
				user.LastLogin = Date.Now

				-- 提交修改给数据库
				ctx:SaveChanges()
			else
				-- 取消事务处理
				trans:Rollback()
			end
		end)
	end)
end
```


### 上下文相关的关键字

其他的关键字都是为了特定上下文定义的，比如结构体，接口，类的定义环境：

* struct
	* member   -- 定义结构体成员
	* array    -- 设置数组元素类型
* interface
	* require  -- 设置接口的需要类
	* extend   -- 扩展其他接口
	* field    -- 添加对象字段
	* event    -- 定义事件
	* property -- 定义属性
* class
	* inherit  -- 继承类
	* extend   -- 扩展其他接口
	* field    -- 添加对象字段
	* event    -- 定义事件
	* property -- 定义属性

### `_G`中可用的资源

**PLoop**会尝试将一些关键字和类型保存到`_G`中，这样你可以直接使用它们:

* PLoop 	 -- 所有命名空间的根
* namespace  -- 为`_G`申明命名空间
* import     -- 将命名空间及其内部的子命名空间实体都保存到`_G`
* enum       -- 定义新枚举类型
* struct     -- 定义新结构体类型
* interface  -- 定义新接口类型
* class      -- 定义新类
* Module     -- System.Module

只有**PLoop**必定存在，其他不会覆盖`_G`中同名的其他变量。


## Serialization 序列化

### 从JSON开始

这是一个完整的序列化和反序列化的例子：


```lua
require "PLoop" (function(_ENV)
	import "System.Serialization"

	json = [==[
	{
		"debug": "on\toff",
		"nums" : [1,7,89,4,5,6,9,3,2,1,1,9,3,0,11]
	}]==]

	-- 反序列化json数据为lua table
	data = Serialization.Deserialize(JsonFormatProvider(), json)

	-- 序列化lua table为字符串，带缩进
	-- {
	-- 		debug = "on	off",
	-- 		nums = {
	-- 			[1] = 1,
	-- 			[2] = 7,
	-- 			[3] = 89,
	-- 			[4] = 4,
	-- 			[5] = 5,
	-- 			[6] = 6,
	-- 			[7] = 9,
	-- 			[8] = 3,
	-- 			[9] = 2,
	-- 			[10] = 1,
	-- 			[11] = 1,
	-- 			[12] = 9,
	-- 			[13] = 3,
	-- 			[14] = 0,
	-- 			[15] = 11
	-- 		}
	-- }
	print(Serialization.Serialize(StringFormatProvider{Indent = true}, data))
end)
```

这个例子使用**System.Serialization**通过**System.Serialization.JsonFormatProvider**来反序列化json字符串为lua的普通table，然后使用**System.Serialization.StringFormatProvider**将这个普通table转换成lua的字符串。

**System.Serialization.Serialize**和 **System.Serialization.Deserialize**是两个静态方法。

**System.Serialization.Serialize**用于将**PLoop**的对象或者数据转换为普通的Lua数据，然后使用传入的格式工具（FormatProvider）将Lua数据转换为目标数据，例如字符串，或者JSON数据。

**System.Serialization.Deserialize**先使用传入的格式工具将目标数据转换为普通Lua数据，然后根据传入的类型将Lua数据转换为对象或者普通数据。

* Serialize : PLoop object -> lua table -> target format( string, json, xml )
* Deserialize : target format -> lua table -> PLoop object


Json是常见的序列化处理，每次使用JsonFormatProvider也比较麻烦，实际可以直接用`Toolset.json(data[,type])`将对象或者数据转换为Json数据包，或者用
`Toolset.parsejson(json[, type])`将Json数据转换为Lua的数据或者PLoop的对象。

同样，针对**StringFormatProvider**可以使用`Toolset.tostring(data[, type[, pretty]])`将对象或者数据序列化为字符串，或者用
`Toolset.parsestring(str[, type])`将字符串转换为Lua的数据或者PLoop的对象。


### 可序列化类型

并非所有的**PLoop**类型都是可以序列化的，枚举类型均是可序列化的，可序列化的类或自定义结构体必须使用`System.Serialization.__Serializable__`特性标记，一个数组结构体仅当它的元素类型是可序列化，一个成员结构体仅当它的所有成员类型是可序列化的。

可以使用`System.Serialization.__NonSerialized__`标记不可序列化的属性（property）或者结构体成员（member）。

后面的例子中，我们只使用字符串作为目标格式，所以，我们仅需要使用**StringFormatProvider**。

首先看一个例子：

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	namespace "Test"

	__Serializable__()
	class "Person" {
		Name = String,
		Age  = Number,
		Childs = struct { Person }
	}

	King = Person {
		Name = "King", Age = 65,
		Childs = {
			Person {
				Name = "Ann", Age = 33,
				Childs = {
					Person { Name = "Dio", Age = 12 }
				}
			}
		}
	}

	--	{
	--		__PLoop_Serial_ObjectType = "Test.Person",
	--		Childs = {
	--			[1] = {
	--				__PLoop_Serial_ObjectType = "Test.Person",
	--				Childs = {
	--					[1] = {
	--						__PLoop_Serial_ObjectType = "Test.Person",
	--						Name = "Dio",
	--						Age = 12
	--					}
	--				},
	--				Name = "Ann",
	--				Age = 33
	--			}
	--		},
	--		Name = "King",
	--		Age = 65
	--	}
	print( Serialization.Serialize( StringFormatProvider{ Indent = true }, King ) )
end)
```

**StringFormatProvider**有以下属性：

* Indent - 是否使用缩进，默认false
* LineBreak - 换行符, 默认'\n'
* IndentChar - 缩进符，默认'\t'
* ObjectTypeIgnored - 是否不保存对象类型，默认false

因为我们设置**Indent**为true，所以，我们的返回结果是格式化的。我们可以看到多个`__PLoop_Serial_ObjectType`，如果对象的类型不是匿名的，序列化时会保存数据的类型，便于之后反序列化时，系统知道该转换为何种类型。可以设置**ObjectTypeIgnored**为true关闭这个功能。

之后我们可以尝试进行反序列化：

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	namespace "Test"

	__Serializable__()
	class "Person" {
		Name = String,
		Age  = Number,
		Childs = struct { Person }
	}

	King = Person {
		Name = "King", Age = 65,
		Childs = {
			Person {
				Name = "Ann", Age = 33,
				Childs = {
					Person { Name = "Dio", Age = 12 }
				}
			}
		}
	}

	data = Serialization.Serialize( StringFormatProvider{ Indent = true }, King )

	p = Serialization.Deserialize( StringFormatProvider(), data)

	-- Test.Person	Dio
	print( getmetatable(p), p.Childs[1].Childs[1].Name)
end)
```

根据最后的结果，*p*是**Person**对象，我们拿回了所有的数据，如果我们开启**ObjectTypeIgnored**：

```lua
data = Serialization.Serialize( StringFormatProvider{ ObjectTypeIgnored  = true }, King )

p = Serialization.Deserialize( StringFormatProvider(), data)

-- nil	Dio
print( getmetatable(p), p.Childs[1].Childs[1].Name)
```

现在虽然我们拿到了*Name*，但*p*并非**Person**对象，这是因为系统无法知道数据对应的类型，我们可以在反序列化时传入类型：

```lua
data = Serialization.Serialize( StringFormatProvider{ ObjectTypeIgnored  = true }, King )

p = Serialization.Deserialize( StringFormatProvider(), data, Person)

-- Test.Person	Dio
print( getmetatable(p), p.Childs[1].Childs[1].Name)
```

通常来说，我们需要在**Serialize**和**Deserialize**中都传入类型，不过对于**Person**对象，系统可以直接从它上面获取类型信息，所以，在之前处理中可以无视这条。

不过如果我们对结构体使用序列化机制，就必须给出类型，因为系统无法自行获得。

至于为什么要提供结构体类型给普通的Lua数据（结构体数据一般都是普通Lua数据）。原因在于，类型会被传递给格式工具类，将会有利于格式工具处理数据，比如数据是数组结构体，那么生成Json时，就不需要检查里面的所有数据才能推断出来。

### 自定义序列化和反序列化

序列化系统只能处理类的属性值，而无法处理它可能存在的字段等，如果需要将这些数据序列化和反序列化，就需要类自行提供功能。如果类存在构造体，系统也无法直接传入初始化表来构造对象，同样需要类自己提供构造功能。

如果类需要自行处理序列化操作，它必须扩展**System.Serialization.ISerializable**接口，然后覆盖**Serialize**虚方法，这个方法接收一个**System.Serialization.SerializationInfo**对象，这个类有两个方法：

* obj:SetValue(name, value, valueType)  -- 将键值按照类型保存到obj对象中
* obj:GetValue(name, valueType)         -- 从obj对象中按类型获取值

利用这个**SerializationInfo**对象，类可以写入需要序列化的数据，也可以从中读取用来构造对象的值：

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	namespace "Test"

	__Serializable__()
	class "Person" (function (_ENV)
		extend "ISerializable"

		property "Name" { Type = String }
		property "Age"  { Type = Number }

		function Serialize(self, info)
			-- 按类型写入需要序列化的数据
			info:SetValue("name", self.Name, String)
			info:SetValue("age",  self.Age, Number)
		end

		__Arguments__{ String, Number }
		function Person(self, name, age)
			self.Name = name
			self.Age = age
		end

		-- 反序列化构造体
		__Arguments__{ SerializationInfo }
		function Person(self, info)
			-- 按类型获取保存的值
			this(self, info:GetValue("name", String) or "Noname", info:GetValue("age", Number) or 0)
		end
	end)

	__Serializable__()
	class "Student"(function (_ENV)
		inherit "Person"

		property "Score" { Type = Number }

		function Serialize(self, info)
			-- 保存子类型的数据
			info:SetValue("score", self.Score, Number)

			-- 调用超类的序列化方法
			super.Serialize(self, info)
		end

		-- 子类反序列化构造体
		__Arguments__{ SerializationInfo }
		function Student(self, info)
			-- 调用超类反序列化构造体
			super(self, info)

			-- 获取子类所需的值
			self.Score = info:GetValue("score", Number)
		end

		__Arguments__.Rest()
		function Student(self, ...)
			super(self, ...)
		end
	end)

	Ann = Student("Ann", 16)
	Ann.Score = 81

	data = Serialization.Serialize( StringFormatProvider(), Ann)

	-- {__PLoop_Serial_ObjectType="Test.Student",name="Ann",age=16,score=81}
	print(data)

	p = Serialization.Deserialize( StringFormatProvider(), data)

	-- Test.Student	Ann	16	81
	print( getmetatable(p), p.Name, p.Age, p.Score)
end)
```


## System.Collections 集合

在[从使用集合开始](#从使用集合开始)中我们已经了解了**List**和**Dictionary**两种集合类型，现在我们更深入的进行说明。

### System.Collections.Iterable

这个接口是集合最基本的接口，它只有一个虚方法**GetIterator**，用于返回一个供泛型for使用的迭代器。

### System.Collections.IList

**IList**接口代表数组集合，数组集合仅关心元素，它们的索引在通常操作中可以被无视。它扩展了**Iterable**接口。

特别的，List使用的**Map**, **Filter**, **Range**, **ToList**, **Reduce**, **Each**, **Any**, **All**, **First**这类链式方法都是定义在这个接口中，所以，如果类扩展了这个接口，就可以利用这些方法。

```lua
require "PLoop"

PLoop(function(_ENV)
	class "Queue" (function(_ENV)
		extend "IList"

		__Iterator__()
		function GetIterator(self)
			for i = self.Start, self.End - 1 do
				coroutine.yield(i, self[i])
			end
		end

		-- Queue(1, 2, 3, 4)
		function __new(cls, ...)
			return {...}, true
		end

		function Queue(self)
			self.Start = 1
			self.End   = #self + 1
		end

		function __call(self, val)
			if val ~= nil then
				-- queue
				local endp = self.End
				self[endp] = val
				self.End   = endp + 1
			else
				-- dequeue
				local start= self.Start
				if start < self.End then
					val    = self[start]
					self[start] = nil
					self.Start  = start + 1
					return val
				end
			end
		end
	end)

	queue = Queue(1, 2, 3, 4, 5)
	queue(queue())
	queue(queue())

	queue:Each(print) -- 3  4  5  1  2
end)
```

#### System.Collections.ICountable

**ICountable**代表可以计数的数组集合，它扩展了**IList**接口。

它只定义了一个**Count**虚属性，默认返回#self作为数组长度。

#### System.Collections.IIndexedList

**IIndexedList**接口代表数字索引集合，类可以使用`obj[idx]`的连续数字索引访问它的元素，它扩展了**ICountable**接口。

特别的，List使用的Sort之类排序算法都定义在这个接口中。

#### System.Collections.List

**List**类扩展了**IIndexedList**接口，所以它可以使用所有的链式方法和排序算法。

### System.Collections.IDictionary

**IDictionary**代表所有的键值对集合，它扩展了**Iterable**接口。

字典链式处理方法 **Map**, **Filter**, **Reduce**, **Each**和**Keys**, **Values**这两个终止属性都是定义在这个接口。

#### System.Collections.Dictionary

**IDictionary**的唯一实现，通常足以满足日常用途。

### List, Dictionary和序列化

为了简化序列化的处理，**List**和**Dictionary**都被申明为可序列化的类型：

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	o = Dictionary{ A = Date(2013, 8, 13), B = Date(2017, 4, 2), C = Date(2018, 3, 14)}

	v = Serialization.Serialize( StringFormatProvider{ Indent = true, ObjectTypeIgnored = false  }, o )

	--	{
	--		__PLoop_Serial_ObjectType = "System.Collections.Dictionary",
	--		[1] = {
	--			__PLoop_Serial_ObjectType = "System.Collections.List",
	--			[1] = "A",
	--			[2] = "C",
	--			[3] = "B"
	--		},
	--		[2] = {
	--			__PLoop_Serial_ObjectType = "System.Collections.List",
	--			[1] = {
	--				__PLoop_Serial_ObjectType = "System.Date",
	--				time = 1376366400
	--			},
	--			[2] = {
	--				__PLoop_Serial_ObjectType = "System.Date",
	--				time = 1521000000
	--			},
	--			[3] = {
	--				__PLoop_Serial_ObjectType = "System.Date",
	--				time = 1491105600
	--			}
	--		}
	--	}
	print(v)

	o = Serialization.Deserialize( StringFormatProvider(), v)

	-- 	A	2013-08-13 12:00:00
	-- 	B	2017-04-02 12:00:00
	-- 	C	2018-03-14 12:00:00
	o:Each(print)
end)
```

上面的**Sytem.Date**日期类型也是一个可序列化对象，所以它会被用于完成序列化处理。

仔细看*v*的输出，字典对象实际被分解成两个**List**对象之后再被序列化的。这里面有很多`__PLoop_Serial_ObjectType`来帮助反序列化处理。

不过很多场合下，我们无法传递对象类型:


```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	o = Dictionary{ A = Date(2013, 8, 13), B = Date(2017, 4, 2), C = Date(2018, 3, 14)}

	v = Serialization.Serialize( StringFormatProvider{ Indent = true, ObjectTypeIgnored = true  }, o )

	--	{
	--		[1] = {
	--			[1] = "A",
	--			[2] = "C",
	--			[3] = "B"
	--		},
	--		[2] = {
	--			[1] = {
	--				time = 1376366400
	--			},
	--			[2] = {
	--				time = 1521000000
	--			},
	--			[3] = {
	--				time = 1491105600
	--			}
	--		}
	--	}
	print(v)

	o = Serialization.Deserialize( StringFormatProvider(), v, Dictionary)

	--	A	table: 03026B90
	--	C	table: 03026CA8
	--	B	table: 03026CF8
	o:Each(print)
end)
```

可见，哪怕反序列化时，传入了**Dictionary**类型，因为序列化系统无法了解键值各自的类型，依然无法反序列化这些元素。

为了解决这个问题，**List**和**Dictionary**都被定义为[模板类](#模板类)，这样我们就可以很方便的键值的类型传进去：

```lua
require "PLoop"

PLoop(function(_ENV)
	import "System.Serialization"

	o = Dictionary{ A = Date(2013, 8, 13), B = Date(2017, 4, 2), C = Date(2018, 3, 14)}

	v = Serialization.Serialize( StringFormatProvider{ Indent = true, ObjectTypeIgnored = true  }, o )

	--	{
	--		[1] = {
	--			[1] = "A",
	--			[2] = "C",
	--			[3] = "B"
	--		},
	--		[2] = {
	--			[1] = {
	--				time = 1376366400
	--			},
	--			[2] = {
	--				time = 1521000000
	--			},
	--			[3] = {
	--				time = 1491105600
	--			}
	--		}
	--	}
	print(v)

	o = Serialization.Deserialize( StringFormatProvider(), v, Dictionary[{String, Date}])

	--	A	2013-08-13 12:00:00
	--	B	2017-04-02 12:00:00
	--	C	2018-03-14 12:00:00
	o:Each(print)
end)
```

现在，序列化系统可以获知键值的类型，我们也能获得我们所需要的对象。