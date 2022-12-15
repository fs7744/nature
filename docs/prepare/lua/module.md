# 模块

从 Lua 5.1 语言添加了对模块和包的支持。一个 Lua 模块的数据结构是一个 Lua 值（通常是一个 Lua 表或者 Lua 函数）。一个 Lua 模块代码就是一个会返回这个 Lua 值的代码块。
可以使用内建函数 `require()` 来加载和缓存模块。简单的说，一个代码模块就是一个程序库，可以通过 `require()` 来加载。模块加载后的结果通常是一个 Lua table，这个表就像是一个命名空间，其内容就是模块中导出的所有东西，比如函数和变量。`require()` 函数会返回 Lua 模块加载后的结果，即用于表示该 Lua 模块的 Lua 值。

## `require()` 函数

Lua 提供了一个名为 `require()` 的函数用来加载模块。要加载一个模块，只需要简单地调用 `require("file")`  就可以了，file 指模块所在的文件名。这个调用会返回一个由模块函数组成的 table，并且还会定义一个包含该 table 的全局变量。

在 Lua 中创建一个模块最简单的方法是：创建一个 table，并将所有需要导出的函数放入其中，最后返回这个 table 就可以了。

相当于将导出的函数作为 table 的一个字段，在 Lua 中函数是第一类值，提供了天然的优势。

> 把下面的代码保存在文件 my.lua 中

```lua
local _M = {}

local function get_name()
    return "Lucy"
end

function _M.greeting()
    print("hello " .. get_name())
end

return _M
```

> 把下面代码保存在文件 main.lua 中，然后执行 main.lua，调用上述模块。

```lua
local my_module = require("my")
my_module.greeting()     -->output: hello Lucy
```

注：对于需要导出给外部使用的公共模块，出于安全考虑，要避免全局变量的出现。
我们可以使用 lj-releng 或 luacheck 工具完成全局变量的检测。至于如何做，到后面再讲。

另一个要注意的是，由于在 LuaJIT 中，`require()` 函数内不能进行上下文切换，所以不能够在模块的顶级上下文中调用 cosocket 一类的 API。
否则会报 `attempt to yield across C-call boundary` 错误。

## 到底是怎么工作的呢？
1.  require 函数会在模块path列表搜索模块，openresty可以指定如下两种：

    - lua 库： ```lua_package_path "./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;";```
    - c 库： ```lua_package_cpath "./?.so;/usr/local/lib/lua/5.1/?.so;";```
2. 找到模块文件之后，就会解析执行整个文件的内容（类似函数 loadstring），由于最后是return 模块变量，我们就可以使用这个变量的函数等等一切了

3. 在openresty中，如果开启了 ```lua_code_cache on```， require 函数会将第二步拿到的变量存在 ```package.loaded``` 这个table 中，达到缓存效果

##  那么如何卸载呢？
非常简单，只需一句：

``` lua
package.loaded['xxxmodule'] = nil
```

由于lua模块动态的机制，所以我们可以利用其在openresty中实现动态插件机制(后续将介绍)

## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)