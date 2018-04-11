# 基于原型的Lua面向对象系统

**PLoop**是纯Lua的面向对象系统，它提供的语法规则类似于C#，支持Lua 5.1及以上版本，也支持luajit。也可以用于类似[OpenResty](https://github.com/openresty/lua-nginx-module)这样的多线程平台。

**PLoop**本身也提供了类似协程池，集合，序列化等通用功能。除了提供类型定义和通用类型外，**PLoop**也针对项目开发提供了诸如代码管理，类型验证等常用功能。


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

    在之前的例子中，封装代码的函数被传给**PLoop**后，将被绑定一个私有且特殊的**PLoop**环境，然后被执行。至于为什么采用这种形式，原因在于Lua的环境控制在5.1到5.2两个版本间有重大的变化，为了通用性，**PLoop**使用`PLoop(function(_ENV) end)`的形式来封装和调用代码，之后也会看到其他类似的处理，比如定义类`class "A" (function(_ENV) end)`。

    这么处理的好处我们将在以后的例子中逐步了解，这个例子中使用到的点是:

    * 全局变量属于该私有环境，在_G中无法访问到被创建的变量v等。

    * 可以随意使用例如math.random这样的保存在`_G`中的公共库或者变量，这样不会造成性能问题，私有环境会在第一次访问后自动缓存这些变量。

    * 可以直接访问**List**类，**PLoop**中有公共命名空间这个概念，公共命名空间不需要被**import**即可被所有的**PLoop**环境访问，默认的公共命名空间是**System**, **System.Collections**和**System.Threading**，后面都会接触到。

    公共命名空间的访问优先级低于被import的命名空间，所以，如果使用了`import "System.Form"`，那么访问List访问到的是**System.Form.List**。

    * 我们可以使用关键字**import**为私有环境或者`_G`引入命名空间，之后可以使用里面保存的类型。不同点在于，向`_G`中导入，是全部拷贝到`_G`中，而私有环境仅记录下自己导入的命名空间，当需要时，才取出要用的类型。

    * **PLoop**的私有环境，会在第一次读取某个全局变量时进行查找（查找到同样会自动缓存），顺序是:

    * 查找这个环境所属的命名空间（使用`namespace "MyNamesapce`"申明，之后在这个环境中定义的类型都会保存在这个命名空间中)

        * 查找这个环境**import**的命名空间

        * 查找公共命名空间

        * 查找根命名空间，比如直接访问**System**

        * 查找基础环境，私有环境可以设置自己的基础环境，通常是`_G`

    在命名空间中查找变量名的规则是:

    * 对比命名空间的名字（路径最后部分，比如**System.Form**的名字是**Form**)，一致就返回该命名空间

    * 直接使用`命名空间[变量名]`获取，通常结果会是子命名空间比如`System["Form"]`得到**System.Form**，也可能是类型，比如`System.Collections["List"]`，也可能是类型本身提供的资源，比如类的静态方法，枚举类型的枚举值等，后面会看到具体的例子。

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

```lua
require "PLoop"

PLoop(function(_ENV)
    obj = List(10)

    print(obj:Remove()) -- 10
end)
```

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
end)
```

这里有两种类型的方法：队列方法类似**Range**, **Filter**和**Map**，终止方法类似**Each**, **Reduce**等。

队列方法会记录操作和操作的参数，但并不执行，直到某个终止方法被调用，队列的操作会最终转换为一个新的迭代器供终止方法使用。实际处理来说，List对象调用某个队列方法后，一个流处理工作对象会被返回，所有的队列操作信息都保存在它里面，它本身也是一个特殊的列表对象（它的类不是List)，我们可以继续添加队列操作，直到最后调用终止方法，如果将上面的操作分开看，就是:

```lua
require "PLoop"

PLoop(function(_ENV)
    obj = List(10)

    -- 我们将解析下面的操作
    -- obj:Range(1, -1, 2)::Map(function(x) return 2^x end):Each(print)

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
FirstOrDefault(self, default, func, ...) |返回第一个使`func(element, ...)`返回非false值的元素，如果没有，返回default值
FirstOrDefault(self, default)            |返回列表的第一个元素，如果没有，返回default值
Reduce(self, func[, init])               |用于合并元素，参考上面计算总值的例子
ToList(self[, listtype])                 |使用迭代返回的元素创建一个新的列表对象，默认列表类型是**List**


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

构造方法                         |结果
:--------------------------------|:--------------------------------
Dictionary()                     |创建一个空dictionary对象
Dictionary(table)                |将输入的table转换成一个dictionary对象
Dictionary(table, table)         |接受两个数组，第一个数组的元素作为键，第二个数组的元素作为值，构建一个新的dictionary对象
Dictionary(listKey, listValue)   |接受两个列表对象，第一个列表的元素作为键，第二个列表的元素作为值，构建一个新的dictionary对象
Dictionary(dictionary)           |复制dictionary对象的键值对，创建新的对象
Dictionary(iter, obj, index)     |使用迭代器产生的键值对创建新的dictionary对象

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


这些dictionary对象实际就是普通的哈希表，所以我们可以使用**pairs**来遍历它们，也可以直接使用`obj[key] = value`去修改它们，这些操作和普通table是一样的，所以**Dictionary**仅提供**GetIterator**方法, 这个方式实际就是**pairs**.


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

通过这两个终止属性，我们可以将dictionaryd操作转换成list操作。

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

**List**和**Dictionary**的队列和终止，以及排序方法并非定义在它们内部，而是由接口提供鼓的，等了解类和接口后，我们可以创建新的集合类型扩展这些接口，然后直接享受这些方法带来的便利。


## 特性(Attribtue)和协程池(Thread Pool)

**List**和**Dictionary**展示了对象的构建和使用，接下来，我们可以来看关于**PLoop**私有环境的一些特殊用法。首先是特性和协程的合用：

```lua
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

另一种错误检测对应于对象的字段:

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

结构体类型是**PLoop**中的主要数据类型，也用来作为数据契约提供类型验证等功能。基于它们的结构，**PLoop**提供三种结构体类型。


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
end)
```

类似于使用**PLoop**启用私有环境运行代码，在**PLoop**定义结构体同样使用这种调用方式，里面被调用函数体就是Number这个结构体的定义。

这里的环境B是为了定义类型特殊设计的：

* 环境B的所属命名空间就是Number这个结构体类型，也就是说，在环境B中定义的其他类型都是Number的子命名空间。

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

`System.__Static__`用于指明下一个而定义的方法是静态方法。

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

例外的，使用**PLoop**的序列化机制序列化一个数组结构体数据时，因为系统明确知道它是数组类型，所以，不需要进行验证就可以按照数组的方式序列化它。

系统默认只提供一个数组结构体:

数组结构体                    |描述
:-----------------------------|:-----------------------------
**System.Variables**          |代表一组变量，我们会在重载系统中具体看它的用途


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
GetStructCategory(target)               |返回结构体的类型: CUSTOM, MEMBER, ARRAY
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
        print(member.GetName(member), Member.GetType(member))
    end
end)
```


枚举类型和结构体类型都是值类型，通常用于类型验证。而接口和类系统就是用来为生产提供各种资源。


## Class 类

类是从一组行为，属性类似的对象中抽象出来的，类为对象提供方法和属性等的实现。

**PLoop**中，类定义主要由几部分组成:

