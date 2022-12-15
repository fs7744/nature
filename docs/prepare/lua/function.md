# Lua 函数

在 Lua 中，函数是一种对语句和表达式进行抽象的主要机制。函数既可以完成某项特定的任务，也可以只做一些计算并返回结果。在第一种情况中，一句函数调用被视为一条语句；而在第二种情况中，则将其视为一句表达式。

> 示例代码：

```lua
print("hello world!")        -- 用 print() 函数输出 hello world！
local m = math.max(1, 5)     -- 调用数学库函数 max，
                             -- 用来求 1,5 中的最大值，并返回赋给变量 m
```

使用函数的好处：

1. 降低程序的复杂性：把函数作为一个独立的模块，写完函数后，只关心它的功能，而不再考虑函数里面的细节。
1. 增加程序的可读性：当我们调用 `math.max()` 函数时，很明显函数是用于求最大值的，实现细节就不关心了。
1. 避免重复代码：当程序中有相同的代码部分时，可以把这部分写成一个函数，通过调用函数来实现这部分代码的功能，节约空间，减少代码长度。
1. 隐藏局部变量：在函数中使用局部变量，变量的作用范围不会超出函数，这样它就不会给外界带来干扰。

## 函数定义

Lua 使用关键字 *function* 定义函数，语法如下：

```lua
function function_name (arc)  -- arc 表示参数列表，函数的参数列表可以为空
   -- body
end
```

上面的语法定义了一个全局函数，名为 `function_name`。 全局函数本质上就是函数类型的值赋给了一个全局变量，即上面的语法等价于：

```lua
function_name = function (arc)
  -- body
end
```

由于全局变量一般会污染全局名字空间，同时也有性能损耗（即查询全局环境表的开销），因此我们应当尽量使用“局部函数”，其记法是类似的，只是开头加上 `local` 修饰符：

```lua
local function function_name (arc)
  -- body
end
```

由于函数定义本质上就是变量赋值，而变量的定义总是应放置在变量使用之前，所以函数的定义也需要放置在函数调用之前。

> 示例代码：

```lua
local function max(a, b)  --定义函数 max，用来求两个数的最大值，并返回
   local temp = nil       --使用局部变量 temp，保存最大值
   if(a > b) then
      temp = a
   else
      temp = b
   end
   return temp            --返回最大值
end

local m = max(-12, 20)    --调用函数 max，找出 -12 和 20 中的最大值
print(m)                  --> output： 20
```

如果参数列表为空，必须使用 `()` 表明是函数调用。

> 示例代码：

```lua
local function func()   --形参为空
    print("no parameter")
end

func()                  --函数调用，圆扩号不能省

--> output：
no parameter
```

在定义函数时要注意几点：

1. 利用名字来解释函数、变量的意图，使人通过名字就能看出来函数、变量的作用。
2. 每个函数的长度要尽量控制在一个屏幕内，一眼可以看明白。
3. 让代码自己说话，不需要注释最好。

由于函数定义等价于变量赋值，我们也可以把函数名替换为某个 Lua 表的某个字段，例如

```lua
function foo.bar(a, b, c)
    -- body ...
end
```

此时我们是把一个函数类型的值赋给了 `foo` 表的 `bar` 字段。换言之，上面的定义等价于：

```lua
foo.bar = function (a, b, c)
    print(a, b, c)
end
```

对于此种形式的函数定义，不能再使用 `local` 修饰符了，因为不存在定义新的局部变量了。

## 函数的参数

### 按值传递

Lua 函数的参数大部分是按值传递的。值传递就是调用函数时，实参把它的值通过赋值运算传递给形参，然后形参的改变和实参就没有关系了。在这个过程中，实参是通过它在参数表中的位置与形参匹配起来的。

> 示例代码：

```lua
local function swap(a, b) --定义函数 swap，在函数内部交换两个变量的值
   local temp = a
   a = b
   b = temp
   print(a, b)
end

local x = "hello"
local y = 20
print(x, y)
swap(x, y)    --调用 swap 函数
print(x, y)   --调用 swap 函数后，x 和 y 的值并没有交换

-->output
hello 20
20  hello
hello 20
```

在调用函数的时候，若形参个数和实参个数不同时，Lua 会自动调整实参个数。调整规则：
- 若实参个数 **大于** 形参个数，从左向右，**多余的实参被忽略**；
- 若实参个数 **小于** 形参个数，从左向右，没有被实参初始化的形参会被初始化为 **nil**。

> 示例代码：

```lua
local function fun1(a, b)       --两个形参，多余的实参被忽略掉
   print(a, b)
end

local function fun2(a, b, c, d) --四个形参，没有被实参初始化的形参，用 nil 初始化
   print(a, b, c, d)
end

local x = 1
local y = 2
local z = 3

fun1(x, y, z)         -- z 被函数 fun1 忽略掉了，参数变成 x, y
fun2(x, y, z)         -- 后面自动加上一个 nil，参数变成 x, y, z, nil

-->output
1   2
1   2   3   nil
```

### 变长参数

上面函数的参数都是固定的，其实 Lua 还支持变长参数。若形参为 `...` ， 表示该函数可以接收不同长度的参数。访问参数的时候也要使用 `...`。

> 示例代码：

```lua
local function func( ... )                -- 形参为 ... ，表示函数采用变长参数

   local temp = {...}                     -- 访问的时候也要使用 ...
   local ans = table.concat(temp, " ")    -- 使用 table.concat 库函数对数
                                          -- 组内容使用 " " 拼接成字符串。
   print(ans)
end

func(1, 2)        -- 传递了两个参数
func(1, 2, 3, 4)  -- 传递了四个参数

-->output
1 2

1 2 3 4
```

**值得一提的是，LuaJIT 2 尚不能 JIT 编译这种变长参数的用法，只能解释执行。所以对性能敏感的代码，应当避免使用此种形式。**

### 具名参数

Lua 还支持通过名称来指定实参，这时候要把所有的实参组织到一个 table 中，并将这个 table 作为唯一的实参传给函数。

> 示例代码：

```lua
local function change(arg) -- change 函数，改变长方形的长和宽，使其各增长一倍
  arg.width = arg.width * 2
  arg.height = arg.height * 2
  return arg
end

local rectangle = { width = 20, height = 15 }
print("before change:", "width  =", rectangle.width,
                        "height =", rectangle.height)
rectangle = change(rectangle)
print("after  change:", "width  =", rectangle.width,
                        "height =", rectangle.height)

-->output
before change: width = 20  height =  15
after  change: width = 40  height =  30
```


### 按引用传递

当函数参数是 table 类型时，传递进来的是 实际参数的引用，此时在函数内部对该 table 所做的修改，会直接对调用者所传递的实际参数生效，而无需自己返回结果和让调用者进行赋值。
我们把上面改变长方形长和宽的例子修改一下。

> 示例代码：

```lua
function change(arg)         --chang 函数，改变长方形的长和宽，使其各增长一倍
  arg.width = arg.width * 2  --表 arg 不是表 rectangle 的拷贝，他们是同一个表
  arg.height = arg.height * 2
end                          -- 没有return语句了

local rectangle = { width = 20, height = 15 }
print("before change:", "width = ", rectangle.width,
                        " height = ", rectangle.height)
change(rectangle)
print("after change:", "width = ", rectangle.width,
                       " height =", rectangle.height)

--> output
before change: width = 20  height = 15
after  change: width = 40  height = 30
```

在常用基本类型中，除了 table 是 **按址** 传递类型外，其它的都是 **按值** 传递参数。
用全局变量来代替函数参数的不好编程习惯应该被抵制，良好的编程习惯应该是减少全局变量的使用。

## 函数返回值

Lua 具有一项与众不同的特性，允许函数返回多个值。Lua 的库函数中，有一些就是返回多个值。

> 示例代码：使用库函数 `string.find`，在源字符串中查找目标字符串，若查找成功，则返回目标字符串在源字符串中的起始位置和结束位置的下标。

```lua
local s, e = string.find("hello world", "llo")
print(s, e)  -->output 3  5
```

返回多个值时，值之间用“,”隔开。

> 示例代码：定义一个函数，实现两个变量交换值

```lua
local function swap(a, b)   -- 定义函数 swap，实现两个变量交换值
   return b, a              -- 按相反顺序返回变量的值
end

local x = 1
local y = 20
x, y = swap(x, y)           -- 调用 swap 函数
print(x, y)                 --> output   20     1
```

当函数返回值的个数和接收返回值的变量的个数不一致时，Lua 也会自动调整参数个数。

调整规则：
- 若返回值个数 **大于** 接收变量的个数，**多余的返回值会被忽略掉**；
- 若返回值个数 **小于** 参数个数，从左向右，没有被返回值初始化的变量会被初始化为 **nil**。

> 示例代码：

```lua
function init()             --init 函数 返回两个值 1 和 "lua"
  return 1, "lua"
end

x = init()
print(x)

x, y, z = init()
print(x, y, z)

--output
1
1 lua nil
```

当一个函数有一个以上返回值，且函数调用不是一个列表表达式的最后一个元素，那么函数调用只会产生一个返回值, 也就是第一个返回值。

> 示例代码：

```lua
local function init()       -- init 函数 返回两个值 1 和 "lua"
    return 1, "lua"
end

local x, y, z = init(), 2   -- init 函数的位置不在最后，此时只返回 1
print(x, y, z)              -->output  1  2  nil

local a, b, c = 2, init()   -- init 函数的位置在最后，此时返回 1 和 "lua"
print(a, b, c)              -->output  2  1  lua
```

函数调用的实参列表也是一个列表表达式。考虑下面的例子：

```lua
local function init()
    return 1, "lua"
end

print(init(), 2)   -->output  1  2
print(2, init())   -->output  2  1  lua
```

如果你确保只取函数返回值的第一个值，可以使用括号运算符，例如

```lua
local function init()
    return 1, "lua"
end

print((init()), 2)   -->output  1  2
print(2, (init()))   -->output  2  1
```

**值得一提的是，如果实参列表中某个函数会返回多个值，同时调用者又没有显式地使用括号运算符来筛选和过滤，则这样的表达式是不能被 LuaJIT 2 所 JIT 编译的，而只能被解释执行。**

## 全动态函数调用

调用回调函数，并把一个数组参数作为回调函数的参数。

```lua
local args = {...} or {}
method_name(unpack(args, 1, table.maxn(args)))
```

### 使用场景

如果你的实参 table 中确定没有 nil 空洞，则可以简化为

```lua
method_name(unpack(args))
```

1. 你要调用的函数参数是未知的；
2. 函数的实际参数的类型和数目也都是未知的。

> 伪代码

```lua
add_task(end_time, callback, params)

if os.time() >= endTime then
	callback(unpack(params, 1, table.maxn(params)))
end
```

值得一提的是，`unpack` 内建函数还不能为 LuaJIT 所 JIT 编译，因此这种用法总是会被解释执行。对性能敏感的代码路径应避免这种用法。

### 小试牛刀

```lua
local function run(x, y)
    print('run', x, y)
end

local function attack(targetId)
    print('targetId', targetId)
end

local function do_action(method, ...)
    local args = {...} or {}
    method(unpack(args, 1, table.maxn(args)))
end

do_action(run, 1, 2)         -- output: run 1 2
do_action(attack, 1111)      -- output: targetId    1111
```

### 调用代码前先定义函数

Lua 里面的函数定义 **必须** 放在调用它的代码之前，下面的代码是一个常见的错误：

```lua
-- test.lua 文件
local i = 100
i = add_one(i)

function add_one(i)
	return i + 1
end
```

我们将得到如下错误：

```shell
# luajit test.lua
luajit: test.lua:2: attempt to call global 'add_one' (a nil value)
stack traceback:
    test.lua:2: in main chunk
    [C]: at 0x0100002150
```

为什么放在调用后面就找不到呢？原因是 Lua 里的 function 定义本质上是变量赋值，即

```lua
function foo() ... end
```

等价于

```lua
foo = function () ... end
```

因此在函数定义之前使用函数相当于在变量赋值之前使用变量，Lua 世界对于没有赋值的变量，默认都是 `nil`，所以这里也就产生了一个 `nil` 的错误。

一般地，由于全局变量是每个请求的生命期，因此，以此种方式定义的函数的生命期也是每个请求的。为了避免每个请求创建和销毁 Lua closure 的开销，建议将函数的定义都放置在自己的 Lua module 中，例如：

```lua
-- my_module.lua
local _M = {_VERSION = "0.1"}

function _M.foo()
    -- your code
    print("i'm foo")
end

return _M
```

然后，再在 `content_by_lua_file` 指向的 `.lua` 文件中调用它：

```lua
local my_module = require("my_module")
my_module.foo()
```

因为 Lua module **只会在第一次请求时加载一次**（除非显式禁用了 `lua_code_cache` 配置指令），后续请求便可直接复用。


## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)