# 变量

变量在使用前，需要在代码中进行声明，即创建该变量。

编译程序执行代码之前编译器需要知道如何给语句变量开辟存储区，用于存储变量的值。

依据变量的作用域我们可以将变量分为三类：

- 全局变量：除非显示的声明一个局部变量，否则所有的变量都被默认当作全局变量。
- 局部变量：如果我们将一个变量定义为局部变量，那么这么变量的作用域就被限制在函数内。
- 表字段：这种特殊的变量可以是除了 nil 以外的所有类型，包括函数。

变量的默认值均为 nil。

举例如下

``` lua
a = 5               -- 全局变量
local b = 5         -- 局部变量

function joke()
    c = 5           -- 全局变量
    local d = 6     -- 局部变量
end

joke()
print(c,d)          --> 5 nil

do
    local a = 6     -- 局部变量
    b = 6           -- 对局部变量重新赋值
    print(a,b);     --> 6 6
end

print(a,b)      --> 5 6
```

## 使用局部变量的好处

- 1、 局部变量可以避免因为命名问题污染了全局环境。
- 2、 local 变量的访问比全局变量更快。
- 3、 由于局部变量出了作用域之后生命周期结束，这样可以被垃圾回收器及时释放。

常见实现如：`local print = print`

在 Lua 中，应该尽量让定义变量的语句靠近使用变量的语句，这也可以被看做是一种良好的编程风格。在 C 这样的语言中，强制程序员在一个块（或一个过程）的起始处声明所有的局部变量，所以有些程序员认为在一个块的中间使用声明语句是一种不良好地习惯。

实际上，在需要时才声明变量并且赋予有意义的初值，这样可以提高代码的可读性。对于程序员而言，相比在块中的任意位置顺手声明自己需要的变量，和必须跳到块的起始处声明，大家应该能掂量出哪种做法比较方便了吧？

**尽量使用局部变量** 是一种良好的编程风格。然而，初学者在使用 Lua 时，在定义局部变量时很容易忘记加上 local，这时变量就会自动变成全局变量，很可能导致程序出现意想不到的问题。

那么我们怎么检测哪些变量是全局变量呢？如何防止全局变量导致的影响呢？下面给出一段代码，利用元表的方式来自动检查全局变量，并打印必要的调试信息。

## 检查模块的函数使用全局变量

> 把下面代码保存在 `foo.lua` 文件中。

```lua
local _M = { _VERSION = '0.01' }

function _M.add(a, b)     --两个 number 型变量相加
    return a + b
end

function _M.update_A()    --更新变量值
    A = 365
end

return _M
```

> 把下面代码保存在 `use_foo.lua` 文件中。该文件和 `foo.lua` 在相同目录。

```lua
A = 360     --定义全局变量
local foo = require("foo")

local b = foo.add(A, A)
print("b = ", b)

foo.update_A()
print("A = ", A)
```

> 输出结果：

```lua
#  luajit use_foo.lua
b =   720
A =   365
```

无论是做基础模块或是上层应用，肯定都不愿意这类灰色情况存在，因为它给我们的系统带来很多不确定性（注意 OpenResty 会限制请求过程中全局变量的使用）。 生产中我们是要尽力避免这种情况的出现。

## 虚变量

当一个方法返回多个值时，有些返回值有时候用不到，要是声明很多变量来一一接收，显然不太合适（不是不能）。Lua 提供了一个虚变量 (dummy variable) 的概念，
按照 [惯例](https://www.lua.org/pil/1.3.html) 以一个下划线（`_`）来命名，用它来表示丢弃不需要的数值，仅仅起到占位的作用。

> 看一段示例代码：

```lua
-- string.find (s,p)：
-- 两个 string 类型的变量 s 和 p，从变量 s 的开头向后匹配变量 p，
-- 若匹配不成功，返回 nil，
-- 若匹配成功，返回第一次匹配成功的起止下标。

local start, finish = string.find("hello", "he") --start 值为起始下标，
                                                 --finish 值为结束下标
print(start, finish)                             --输出 1   2

local start = string.find("hello", "he")    -- start值为起始下标
print(start)                                -- 输出 1


local _,finish = string.find("hello", "he") --采用虚变量（即下划线），
                                            --接收起始下标值，然后丢弃，
                                            --finish 接收结束下标值
print(finish)                               --输出 2
print(_)                                    --输出 1, `_` 只是一个普通变量,我们习惯上不会读取它的值
```

代码倒数第二行，定义了一个用 local 修饰的 **虚变量**（即 单个下划线）。使用这个虚变量接收 `string.find()` 第一个返回值，忽略不用，直接使用第二个返回值。

虚变量不仅仅可以被用在返回值，还可以用在迭代等。

> 在for循环中的使用：

```lua
-- test.lua 文件
local t = {1, 3, 5}

print("all  data:")
for i,v in ipairs(t) do
    print(i,v)
end

print("")
print("part data:")
for _,v in ipairs(t) do
    print(v)
end
```

执行结果：

```shell
# luajit test.lua
all  data:
1   1
2   3
3   5

part data:
1
3
5
```

当有多个返回值需要忽略时，可以重复使用同一个虚变量:
> 多个占位:

```lua
-- test.lua 文件
function foo()
    return 1, 2, 3, 4
end

local _, _, bar = foo();    -- 我们只需要第三个
print(bar)
```

执行结果：

```shell
# luajit test.lua
3
```


## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)