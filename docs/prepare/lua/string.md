# 常用 string 方法

Lua 字符串库包含很多强大的字符操作函数。字符串库中的所有函数都导出在模块 string 中。在 Lua 5.1 中，它还将这些函数导出作为 string 类型的方法。这样假设要返回一个字符串转换后的大写形式，可以写成 `ans = string.upper(s)` , 也能写成 `ans = s:upper()`。为了避免与之前版本不兼容，此处使用前者。

Lua 字符串总是由字节构成的。Lua 核心并不尝试理解具体的字符集编码（比如 GBK 和 UTF-8 这样的多字节字符编码）。

需要特别注意的一点是，Lua 字符串内部用来标识各个组成字节的 **下标是从 1 开始的**，这不同于像 C 和 Perl 这样的编程语言。

这在计算字符串位置的时候再也不用调整了，对于非专业的开发者来说可能也是一个好事情，string.sub(str, 3, 7) 直接表示从第三个字符开始到第七个字符（含）为止的子串。

## string.byte(s [, i [, j ]])

返回字符 s[i]、s[i + 1]、s[i + 2]、······、s[j] 所对应的 ASCII 码。`i` 的默认值为 1，即第一个字节,`j` 的默认值为 i 。

> 示例代码

```lua
print(string.byte("abc", 1, 3))
print(string.byte("abc", 3)) -- 缺少第三个参数，第三个参数默认与第二个相同，此时为 3
print(string.byte("abc"))    -- 缺少第二个和第三个参数，此时这两个参数都默认为 1

-->output
97	98	99
99
97
```

由于 `string.byte` 只返回整数，而并不像 `string.sub` 等函数那样（尝试）创建新的 Lua 字符串，
因此使用 `string.byte` 来进行字符串相关的扫描和分析是最为高效的，尤其是在被 LuaJIT 2 所 JIT 编译之后。

## string.char (...)

接收 0 个或多个整数（整数范围：0~255），返回这些整数所对应的 ASCII 码字符组成的字符串。当参数为空时，默认是一个 0。

> 示例代码

```lua
print(string.char(96, 97, 98))
print(string.char())        -- 参数为空，默认是一个0，
                            -- 你可以用string.byte(string.char())测试一下
print(string.char(65, 66))

--> output
`ab

AB
```

**此函数特别适合从具体的字节构造出二进制字符串**。这通常比使用 `table.concat` 函数和 `..` 连接运算符更加高效。

## string.upper(s)

接收一个字符串 s，返回一个把所有小写字母 **变成了大写** 字母的字符串。

> 示例代码

```lua
print(string.upper("Hello Lua"))  -->output  HELLO LUA
```

## string.lower(s)

接收一个字符串 s，返回一个把所有大写字母 **变成了小写** 字母的字符串。

> 示例代码

```lua
print(string.lower("Hello Lua"))  -->output   hello lua
```

## string.len(s)

接收一个字符串，返回它的长度。

> 示例代码

```lua
print(string.len("hello lua")) -->output  9
```

使用此函数是 **不推荐** 的。应当总是使用 `#` 运算符来获取 Lua 字符串的长度。

由于 Lua 字符串的长度是专门存放的，并不需要像 C 字符串那样即时计算，因此获取字符串长度的操作总是 `O(1)` 的时间复杂度。

## string.find(s, p [, init [, plain]])

在 s 字符串中第一次匹配 p 字符串。
- 若匹配成功，则返回 p 字符串在 s 字符串中出现的开始位置和结束位置；
- 若匹配失败，则返回 nil。

第三个参数 init 默认为 1，并且可以为负整数。
当 init 为负数时，表示从 s 字符串的 `string.len(s) + init + 1` 位置开始向后匹配字符串 p 。

第四个参数默认为 false，当其为 true 时，只会把 p 看成一个字符串对待。

> 示例代码

```lua
local find = string.find
print(find("abc cba", "ab"))
print(find("abc cba", "ab", 2))     -- 从索引为2的位置开始匹配字符串：ab
print(find("abc cba", "ba", -1))    -- 从索引为7的位置开始匹配字符串：ba
print(find("abc cba", "ba", -3))    -- 从索引为5的位置开始匹配字符串：ba
print(find("abc cba", "(%a+)", 1))  -- 从索引为1处匹配最长连续且只含字母的字符串
print(find("abc cba", "(%a+)", 1, true)) --从索引为1的位置开始匹配字符串：(%a+)

-->output
1   2
nil
nil
6   7
1   3   abc
nil
```

对于 LuaJIT 这里有个性能优化点，string.find 方法，当只有字符串查找匹配时，是可以被 JIT 编译器优化的，有关 JIT 可以编译优化清单，大家可以参考 [http://wiki.luajit.org/NYI](http://wiki.luajit.org/NYI)，性能提升是非常明显的，通常是 100 倍量级。

这里有个的例子，大家可以参考 [https://groups.google.com/forum/m/#!topic/openresty-en/rwS88FGRsUI](https://groups.google.com/forum/m/#!topic/openresty-en/rwS88FGRsUI)。

## string.format(formatstring, ...)

按照格式化参数 formatstring，返回后面 `...` 内容的格式化版本。编写格式化字符串的规则与标准 C 语言中 printf 函数的规则基本相同：
- 它由常规文本和指示组成，这些指示控制了每个参数应放到格式化结果的什么位置，及如何放入它们。
- 一个指示由字符 `%` 加上一个字母组成，这些字母指定了如何格式化参数，例如:
    - `d` 用于十进制数、
    - `x` 用于十六进制数、
    - `o` 用于八进制数、
    - `f` 用于浮点数、
    - `s` 用于字符串等。
- 在字符 `%` 和字母之间可以再指定一些其他选项，用于控制格式的细节。

> 示例代码

```lua
print(string.format("%.4f", 3.1415926))      -- 保留 4 位小数
print(string.format("%d %x %o", 31, 31, 31)) -- 十进制数 31 转换成不同进制

d = 29; m = 7; y = 2015                      -- 一行包含几个语句，用；分开
print(string.format("%s %02d/%02d/%d", "today is:", d, m, y))

-->output
3.1416
31 1f 37
today is: 29/07/2015
```

## string.match(s, p [, init])

在字符串 s 中匹配（模式）字符串 p。
- 若匹配成功，则返回目标字符串中与模式匹配的子串；
- 否则返回 nil。

第三个参数 init 默认为 1，并且可以为负整数。
当 init 为负数时，表示从 s 字符串的 `string.len(s) + init + 1` 位置开始向后匹配字符串 p。

> 示例代码

```lua
print(string.match("hello lua", "lua"))
print(string.match("lua lua", "lua", 2))  --匹配后面那个lua
print(string.match("lua lua", "hello"))
print(string.match("today is 27/7/2015", "%d+/%d+/%d+"))

-->output
lua
lua
nil
27/7/2015
```

`string.match` 目前并不能被 JIT 编译，应 **尽量** 使用 ngx_lua 模块提供的 `ngx.re.match` 等接口。

## string.gmatch(s, p)

返回一个迭代器函数，通过这个迭代器函数可以遍历到在字符串 s 中出现模式串 p 的所有地方。

> 示例代码

```lua
s = "hello world from Lua"
for w in string.gmatch(s, "%a+") do  --匹配最长连续且只含字母的字符串
    print(w)
end

-->output
hello
world
from
Lua


t = {}
s = "from=world, to=Lua"
for k, v in string.gmatch(s, "(%a+)=(%a+)") do  --匹配两个最长连续且只含字母的
    t[k] = v                                    --字符串，它们之间用等号连接
end
for k, v in pairs(t) do
print (k,v)
end

-->output
to      Lua
from    world
```

此函数目前并不能被 LuaJIT 所 JIT 编译，而只能被解释执行。应 **尽量** 使用 ngx_lua 模块提供的 `ngx.re.gmatch` 等接口。

## string.rep(s, n)

返回字符串 s 的 n 次拷贝。

> 示例代码

```lua
print(string.rep("abc", 3)) --拷贝3次"abc"

-->output  abcabcabc
```

## string.sub(s, i [, j])

返回字符串 s 中，索引 i 到索引 j 之间的子字符串。
- 当 j 缺省时，默认为 -1，也就是字符串 s 的最后位置。
- i 可以为负数。当索引 i 在字符串 s 的位置在索引 j 的后面时，将返回一个空字符串。

> 示例代码

```lua
print(string.sub("Hello Lua", 4, 7))
print(string.sub("Hello Lua", 2))
print(string.sub("Hello Lua", 2, 1))    --看到返回什么了吗
print(string.sub("Hello Lua", -3, -1))

-->output
lo L
ello Lua

Lua
```

如果你只是想对字符串中的 **单个字节** 进行检查，使用 `string.char` 函数通常会更为高效。

## string.gsub(s, p, r [, n])

将目标字符串 s 中所有的子串 p 替换成字符串 r。
- 可选参数 n，表示限制替换次数。
- 返回值有两个，第一个是被替换后的字符串，第二个是替换了多少次。

> 示例代码

```lua
print(string.gsub("Lua Lua Lua", "Lua", "hello"))
print(string.gsub("Lua Lua Lua", "Lua", "hello", 2)) --指明第四个参数

-->output
hello hello hello   3
hello hello Lua     2
```

此函数不能为 LuaJIT 所 JIT 编译，而只能被解释执行。一般我们推荐使用 ngx_lua 模块提供的 `ngx.re.gsub` 函数。

## string.reverse (s)

接收一个字符串 s，返回这个字符串的反转。

> 示例代码

```lua
print(string.reverse("Hello Lua"))  --> output: auL olleH
```

## 正则表达式

### POSIX 规范
在 OpenResty 中，同时存在两套正则表达式规范：Lua 语言的规范和 `ngx.re.*` 的规范，即使您对 Lua 语言中的规范非常熟悉，我们 **强烈建议不使用 Lua 中的正则表达式**。
- 一是因为 Lua 中正则表达式的性能并不如 `ngx.re.*` 中的正则表达式优秀；
- 二是 Lua 中的正则表达式并 **不符合 POSIX 规范**，而 `ngx.re.*` 中实现的是标准的 POSIX 规范，后者明显更具备通用性。

### 性能对比
Lua 中的正则表达式与 Nginx 中的正则表达式相比，有 5% - 15% 的性能损失，原因如下：
- Lua 将表达式编译成 Pattern 之后，并不会将 Pattern 缓存，而是每次使用都重新编译一遍，潜在地降低了性能。

`ngx.re.*` 中的 `o` 选项，指明该参数，被编译的 Pattern 将会在工作进程中缓存，并且被当前工作进程的每次请求所共享。Pattern 缓存的上限值通过 `lua_regex_cache_max_entries` 来修改，它的默认值为1024。

### `ngx.re.*` 中的选项：

- `ngx.re.*` 中的 `o` 选项，若指明该参数，被编译的 Pattern 将会在工作进程中 **缓存**，并且被当前工作进程的每次请求所 **共享**。
Pattern 缓存的上限值通过 `lua_regex_cache_max_entries` 来修改，它的默认值为 1024。

- `ngx.re.*` 中的 `j` 选项，若指明该参数，如果使用的 PCRE 库支持 JIT，OpenResty 会在编译 Pattern 时启用 JIT。 启用 JIT 后正则匹配会有明显的性能提升。
较新的平台，自带的 PCRE 库均支持 JIT。 如果系统自带的 PCRE 库不支持 JIT，出于性能考虑，最好自己编译一份 libpcre.so，然后在编译 OpenResty 时链接过去。

要想验证当前 PCRE 库是否支持 JIT，可以这么做：
- 1、 编译 OpenResty 时在 `./configure` 中指定 `--with-debug` 选项；
- 2、 在 `error_log` 指令中指定日志级别为 `debug`；
- 3、 运行正则匹配代码，查看日志中是否有 `pcre JIT compiling result: 1`。

即使运行在不支持 JIT 的 OpenResty 上，加上 `j` 选项也不会带来坏的影响。在 OpenResty 官方的 Lua 库中，正则匹配至少都会带上 `jo` 这两个选项。

```nginx
location /test {
    content_by_lua_block {
        local regex = [[\d+]]

        -- 参数 "j" 启用 JIT 编译，参数 "o" 是开启缓存必须的
        local m = ngx.re.match("hello, 1234", regex, "jo")
        if m then
            ngx.say(m[0])
        else
            ngx.say("not matched!")
        end
    }
}
```

测试结果如下：

```shell
➜  ~ curl 127.0.0.1/test
1234
```

另外还可以试试引入 `lua-resty-core` 中的正则表达式 API。这么做需要在代码里加入 `require('resty.core.regex')`。
`lua-resty-core` 版本的 `ngx.re.*`，是通过 FFI 而非 Lua/C API 来跟 OpenResty C 代码交互的。某些情况下，会带来明显的性能提升。

### Lua 正则简单汇总

Lua 中正则表达式语法上 **最大的区别，Lua 使用 `%` 来进行转义**，而其他语言的正则表达式使用 **`\`** 符号来进行转义。 其次，Lua 中并不使用 **`?`** 来表示非贪婪匹配，而是定义了不同的字符来表示是否为贪婪匹配。

定义如下：
| 符号 | 匹配次数 | 匹配模式 |
|:---:|:---|:---|
| `+` | 匹配前一字符 1 次或多次 | 非贪婪 |
| `*` | 匹配前一字符 0 次或多次 | 贪婪   |
| `-` | 匹配前一字符 0 次或多次 | 非贪婪 |
| `?` | 匹配前一字符 0 次或 1 次  | 仅用于此，不用于标识是否贪婪 |

| 符号 | 匹配模式 |
|:---:|:----------|
| x  |x 是一个随机字符，代表它自身。(x 不是^$()%.[]*+-? 等特殊字符）     |
| .  |任意字符     |
| %a |字母         |
| %c |控制字符     |
| %d |数字         |
| %l |小写字母     |
| %p |标点字符     |
| %s |空白符       |
| %u |大写字母     |
| %w |字母和数字   |
| %x |十六进制数字 |
| %z |代表 0 的字符|
| [ABC] |匹配 `[...]` 中的所有字符，例如 `[aeiou]` 匹配字符串 "google runoob taobao" 中所有的 e o u a 字母。|
| [^ABC] |匹配除了 `[...]` 中字符的所有字符，例如 `[^aeiou]` 匹配字符串 "google runoob taobao" 中除了 e o u a 字母的所有字母。|

### 常用的正则函数
- `string.find` 的基本应用是在目标串内搜索匹配指定的模式的串。
    - 函数如果找到匹配的串，就返回它的开始索引和结束索引，否则返回 `nil`。
    - `find` 函数第三个参数是可选的：标示目标串中搜索的起始位置。
    例如当我们想实现一个迭代器时，可以传进上一次调用时的结束索引，如果返回了一个 `nil` 值的话，说明查找结束了。

    ```lua
    local s    = "hello world"
    local i, j = string.find(s, "hello")
    print(i, j) --> 1 5
    ```

- `string.gmatch` 我们也可以使用返回迭代器的方式。

    ```lua
    local s = "hello world from Lua"

    for w in string.gmatch(s, "%a+") do
        print(w)
    end

    -- output :
    --    hello
    --    world
    --    from
    --    Lua
    ```

- `string.gsub` 用来查找匹配模式的串，并使用替换串将其替换掉，但并不修改原字符串，而是返回一个修改后的字符串的副本。
    函数有 **目标串、模式串、替换串** 三个参数，使用范例如下：

    ```lua
    local a = "Lua is cute"
    local b = string.gsub(a, "cute", "great")
    print(a) --> Lua is cute
    print(b) --> Lua is great
    ```

-  还有一点值得注意的是，**'%b' 用来匹配对称的字符，而不是一般正则表达式中的单词的开始、结束。 而且采用的是贪婪匹配模式**。
    常写为 '%bxy'，x 和 y 是任意两个不同的字符，x 作为匹配的开始，y 作为匹配的结束。 比如，'%b()' 匹配以 '(' 开始，以 ')' 结束的字符串，示例如下：

    ```lua
    print(string.gsub("a (enclosed (in) parentheses) line", "%b()", ""))

    -- output: a  line 1
    ```


## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)