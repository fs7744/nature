# openresty中的日期时间函数

在 Lua 中，函数 `time`、`date` 和 `difftime` 提供了所有的日期和时间功能。

## （推荐）基于缓存的 ngx_lua 时间接口

事实上，在 Nginx/Openresty 中，会经常使用到获取时间操作，通常一次请求最少有几十次获取时间操作，当单核心 RPS/QPS 达到 10K 以上时，获取时间操作往往会达到 200K+量级的调用，是一个非常高频的调用。所以 Nginx 会将时间和日期进行缓存，并非每次调用或每次请求获取时间和日期。

**推荐** 使用 ngx_lua 模块提供的带缓存的时间接口，如 `ngx.today`, `ngx.time`, `ngx.utctime`,
`ngx.localtime`, `ngx.now`, `ngx.http_time`，以及 `ngx.cookie_time` 等。

## ngx.today()

语法：`str = ngx.today()`

该接口从 Nginx 缓存的时间中获取时间，返回当前的时间和日期，其格式为`yyyy-mm-dd`（与 Lua 的日期库不同，不涉及系统调用）。

## ngx.time()

语法：`secs = ngx.time()`

该接口从 Nginx 缓存的时间中获取时间，返回当前时间戳的历时秒数（与 Lua 的日期库不同，不涉及系统调用）。

## ngx.now()

语法：`secs = ngx.now()`

该接口从 Nginx 缓存的时间中获取时间，以秒为单位（包括小数部分的毫秒）返回从当前时间戳开始的浮点数（与 Lua 的日期库不同，不涉及系统调用）。

> ngx.time() 和 ngx.now() 辨析：ngx.time() 获取到的是秒级时间，ngx.now() 获取到的是毫秒级时间。

## ngx.localtime()

语法：`str = ngx.localtime()`

返回 Nginx 缓存时间的当前时间戳（格式为 `yyy-mm-dd hh:mm:ss`）（与 Lua 的日期库不同，不涉及系统调用）。

## ngx.utctime()

语法：`str = ngx.utctime()`

返回 Nginx 缓存时间的当前 UTC 时间戳（格式为 `yyyy-mm-dd hh:mm:ss`）（与 Lua 的日期库不同，不涉及系统调用）。

## ngx.update_time()

语法：`ngx.update_time()`

强制更新 Nginx 当前时间缓存。这个调用涉及到一个系统调用，因此有一些开销，所以不要滥用。

## 获取时间示例代码

示例代码：

```lua
ngx.log(ngx.INFO, ngx.today())
ngx.log(ngx.INFO, ngx.time())
ngx.log(ngx.INFO, ngx.now())
ngx.log(ngx.INFO, ngx.localtime())
ngx.log(ngx.INFO, ngx.utctime())

ngx.update_time()

ngx.log(ngx.INFO, ngx.today())
ngx.log(ngx.INFO, ngx.time())
ngx.log(ngx.INFO, ngx.now())
ngx.log(ngx.INFO, ngx.localtime())
ngx.log(ngx.INFO, ngx.utctime())

-->output
2020/12/31 15:37:27 [error] 15851#0: *2153324: 2020-12-31
2020/12/31 15:37:27 [error] 15851#0: *2153324: 1609400247
2020/12/31 15:37:27 [error] 15851#0: *2153324: 1609400247.704 --**
2020/12/31 15:37:27 [error] 15851#0: *2153324: 2020-12-31 15:37:27
2020/12/31 15:37:27 [error] 15851#0: *2153324: 2020-12-31 07:37:27
2020/12/31 15:37:27 [error] 15851#0: *2153324: 2020-12-31
2020/12/31 15:37:27 [error] 15851#0: *2153324: 1609400247
2020/12/31 15:37:27 [error] 15851#0: *2153324: 1609400247.705 --缓存时间有变化
2020/12/31 15:37:27 [error] 15851#0: *2153324: 2020-12-31 15:37:27
2020/12/31 15:37:27 [error] 15851#0: *2153324: 2020-12-31 07:37:27
```

os.time 相关函数不推荐，也不介绍了，因为这些函数通常会引发不止一个昂贵的系统调用，同时无法为 LuaJIT JIT 编译，对性能造成较大影响。

## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)