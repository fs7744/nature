# 控制结构

## if-else

if-else 是我们熟知的一种控制结构。Lua 跟其他语言一样，提供了 if-else 的控制结构。因为是大家熟悉的语法，本节只简单介绍一下它的使用方法。

### 单个 if 分支 型

```lua
x = 10
if x > 0 then
    print("x is a positive number")
end
```

> 运行输出：x is a positive number

### 多个分支 if-elseif-else 型

```lua
score = 90
if score == 100 then
    print("Very good!Your score is 100")
elseif score >= 60 then
    print("Congratulations, you have passed it,your score greater or equal to 60")
--此处可以添加多个elseif
else
    print("Sorry, you do not pass the exam! ")
end
```

> 运行输出：Congratulations, you have passed it,your score greater or equal to 60

与 C 语言的不同之处是 else 与 if 是连在一起的，若将 else 与 if 写成 "else if" 则相当于在 else 里嵌套另一个 if 语句，如下代码：

```lua
score = 0
if score == 100 then
    print("Very good!Your score is 100")
elseif score >= 60 then
    print("Congratulations, you have passed it,your score greater or equal to 60")
else
    if score > 0 then
        print("Your score is better than 0")
    else
        print("My God, your score turned out to be 0")
    end --与上一示例代码不同的是，此处要添加一个end
end
```

> 运行输出：My God, your score turned out to be 0

## while

Lua 跟其他常见语言一样，提供了 while 控制结构，语法上也没有什么特别的。但是没有提供 do-while 型的控制结构，但是提供了功能相当的 `repeat`。

while 型控制结构语法如下，当表达式值为假（即 false 或 nil）时结束循环。也可以使用 `break` 语言提前跳出循环。

```lua
while 表达式 do
--body
end
```

> 示例代码，求 1 + 2 + 3 + 4 + 5 的结果

```lua
x = 1
sum = 0

while x <= 5 do
    sum = sum + x
    x = x + 1
end
print(sum)  -->output 15
```

值得一提的是，Lua 并没有像许多其他语言那样提供类似 `continue` 这样的控制语句用来立即进入下一个循环迭代（如果有的话）。因此，我们需要仔细地安排循环体里的分支，以避免这样的需求。

没有提供 `continue`，却也提供了另外一个标准控制语句 `break`，可以跳出当前循环。例如我们遍历 table，查找值为 11 的数组下标索引：

```lua
local t = {1, 3, 5, 8, 11, 18, 21}

local i
for i, v in ipairs(t) do
    if 11 == v then
        print("index[" .. i .. "] have right value[11]")
        break
    end
end
```
## repeat

Lua 中的 repeat 控制结构类似于其他语言（如：C++ 语言）中的 do-while，但是控制方式是刚好相反的。简单点说，执行 repeat 循环体后，直到 until 的条件为真时才结束，而其他语言（如：C++ 语言）的 do-while 则是当条件为假时就结束循环。

> 以下代码将会形成死循环：

```lua
x = 10
repeat
    print(x)
until false
```

> 该代码将导致死循环，因为until的条件一直为假，循环不会结束

除此之外，repeat 与其他语言的 do-while 基本是一样的。同样，Lua 中的 repeat 也可以在使用 break 退出。

## for

Lua 提供了一组传统的、小巧的控制结构，包括用于条件判断的 if，用于迭代的 while、repeat 和 for，本章节主要介绍 for 的使用。

### 一，for 数字型

for 语句有两种形式：数字 for（numeric for）和范型 for（generic for）。

> 数字型 for 的语法如下：

```lua
for var = begin, finish, step do
    --body
end
```

关于数字 for 需要关注以下几点：
- 1、var 从 begin 变化到 finish，每次变化都以 step 作为步长递增 var；
- 2、begin、finish、step 三个表达式只会在循环开始时执行一次；
- 3、第三个表达式 step 是可选的，默认为 1；
- 4、控制变量 var 的作用域仅在 for 循环内，若需要在外面控制，则需将值赋给一个新的变量；
- 5、循环过程中不要改变控制变量的值，那样会带来不可预知的影响。

> 示例

```lua
for i = 1, 5 do
  print(i)
end

-- output:
1
2
3
4
5
```

...

```lua
for i = 1, 10, 2 do
  print(i)
end

-- output:
1
3
5
7
9
```

> 以下是这种循环的一个典型示例：

```lua
for i = 10, 1, -1 do
  print(i)
end

-- output:
...
```

如果不想给循环设置上限的话，可以使用常量 math.huge：

```lua
for i = 1, math.huge do
    if (0.3*i^3 - 20*i^2 - 500 >=0) then
      print(i)
      break
    end
end
```

### 二，for 泛型

泛型 for 循环通过一个迭代器（iterator）函数来遍历所有值：

```lua
-- 打印数组 a 的所有值
local a = {"a", "b", "c", "d"}
for i, v in ipairs(a) do
  print("index:", i, " value:", v)
end

-- output:
index:  1  value: a
index:  2  value: b
index:  3  value: c
index:  4  value: d
```

Lua 的基础库提供了 ipairs，这是一个用于遍历数组的迭代器函数。在每次循环中，i 会被赋予一个索引值，同时 v 被赋予一个对应于该索引的数组元素值。

> 下面是另一个类似的示例，演示了如何遍历一个 table 中所有的 key

```lua
-- 打印table t中所有的key
for k in pairs(t) do
    print(k)
end
```

从外观上看泛型 for 比较简单，但其实它是非常强大的。通过不同的迭代器，几乎可以遍历所有的东西，
而且写出的代码极具可读性。

标准库提供了几种迭代器，包括：
- 用于迭代文件中每行的（io.lines）；
- 迭代 table 元素的（pairs）；
- 迭代数组元素的（ipairs）；
- 迭代字符串中单词的（string.gmatch）等。

泛型 for 循环与数字型 for 循环有两个相同点：
（1）循环变量是循环体的局部变量；
（2）决不应该对循环变量作任何赋值。

对于泛型 for 的使用，再来看一个更具体的示例。假设有这样一个 table，它的内容是一周中每天的名称：

```lua
local days = {
  "Sunday", "Monday", "Tuesday", "Wednesday",
  "Thursday", "Friday", "Saturday"
}
```

现在要将一个名称转换成它在一周中的位置。为此，需要根据给定的名称来搜索这个 table。然而
在 Lua 中，通常更有效的方法是创建一个“逆向 table”。例如这个逆向 table 叫 revDays，它以
一周中每天的名称作为索引，位置数字作为值：

```lua
  local revDays = {
    ["Sunday"]    = 1,
    ["Monday"]    = 2,
    ["Tuesday"]   = 3,
    ["Wednesday"] = 4,
    ["Thursday"]  = 5,
    ["Friday"]    = 6,
    ["Saturday"]  = 7
  }
```

接下来，要找出一个名称所对应的位置，只需用名字来索引这个逆向 table 即可：

```lua
local x = "Tuesday"
print(revDays[x])  -->3
```

当然，不必手动声明这个逆向 table，而是通过原来的 table 自动地构造出这个逆向 table：

```lua
local days = {
   "Monday", "Tuesday", "Wednesday", "Thursday",
   "Friday", "Saturday","Sunday"
}

local revDays = {}
for k, v in pairs(days) do
  revDays[v] = k
end

-- print value
for k,v in pairs(revDays) do
  print("k:", k, " v:", v)
end

-- output:
k:  Tuesday   v: 2
k:  Monday    v: 1
k:  Sunday    v: 7
k:  Thursday  v: 4
k:  Friday    v: 5
k:  Wednesday v: 3
k:  Saturday  v: 6
```

这个循环会为每个元素进行赋值，其中变量 k 为 key(1、2、...)，变量 v 为 value("Sunday"、"Monday"、...)。

值得一提的是，在 LuaJIT 2.1 中，`ipairs()` 内建函数是可以被 JIT 编译的，而 `pairs()` 则只能被解释执行。因此在性能敏感的场景，应当合理安排数据结构，避免对哈希表进行遍历。事实上，即使未来 `pairs` 可以被 JIT 编译，哈希表的遍历本身也不会有数组遍历那么高效，毕竟哈希表就不是为遍历而设计的数据结构。

## break
语句 `break` 用来终止 `while`、`repeat` 和 `for` 三种循环的执行，并跳出当前循环体，
继续执行当前循环之后的语句。下面举一个 `while` 循环中的 `break` 的例子来说明：


```lua
-- 计算最小的 x，使从 1 到 x 的所有数相加和大于 100
sum = 0
i = 1
while true do
    sum = sum + i
    if sum > 100 then
        break
    end
    i = i + 1
end
print("The result is " .. i)  -->output:The result is 14
```

在实际应用中，`break` 经常用于嵌套循环中。

## return

`return` 主要用于从函数中返回结果，或者用于简单的结束一个函数的执行。
关于函数返回值的细节可以参考 [函数的返回值](lua/function_result.md) 章节。`return` 只能写在语句块的最后，一旦执行了 `return` 语句，该语句之后的所有语句都不会再执行。若要写在函数中间，则只能写在一个显式的语句块内，参见示例代码：


```lua
local function add(x, y)
    return x + y
    --print("add: I will return the result " .. (x + y))
    --因为前面有个return，若不注释该语句，则会报错
end

local function is_positive(x)
    if x > 0 then
        return x .. " is positive"
    else
        return x .. " is non-positive"
    end

    --由于return只出现在前面显式的语句块，所以此语句不注释也不会报错，
    --但是不会被执行，此处不会产生输出
    print("function end!")
end

local sum = add(10, 20)
print("The sum is " .. sum)  -->output:The sum is 30
local answer = is_positive(-10)
print(answer)                -->output:-10 is non-positive
```

有时候，为了调试方便，我们可以在某个函数的中间提前 `return`，以进行控制流的短路。此时我们可以将 `return` 放在一个 `do ... end` 代码块中，例如：

```lua
local function foo()
    print("before")
    do return end
    print("after")  -- 这一行语句永远不会执行到
end
```

## goto

LuaJIT 一开始对标的是 Lua 5.1，但渐渐地也开始加入部分 Lua 5.2 甚至 Lua 5.3 的有用特性。
`goto` 就是其中一个不得不提的例子。

有了 `goto`，我们可以实现 `continue` 的功能：
```lua
for i=1, 3 do
    if i <= 2 then
        print(i, "yes continue")
        goto continue
    end

    print(i, " no continue")

    ::continue::
    print([[i'm end]])
end
```

输出结果：

```shell
$ luajit test.lua
1   yes continue
i'm end
2   yes continue
i'm end
3    no continue
i'm end
```

在 [GotoStatement](http://lua-users.org/wiki/GotoStatement) 这个页面上，你能看到更多用 `goto` 玩转控制流的脑洞。

`goto` 的另外一项用途，就是简化错误处理的流程。有些时候你会发现，直接 goto 到函数末尾统一的错误处理过程，是更为清晰的写法。
```lua
local function process(input)
    print("the input is", input)
    if input < 2 then
        goto failed
    end
    -- 更多处理流程和 goto err

    print("processing...")
    do return end
    ::failed::
    print("handle error with input", input)
end

process(1)
process(3)
```

## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)