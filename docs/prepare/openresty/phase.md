# 理解执行阶段

OpenResty 处理一个Http请求，它的处理流程请参考下图（从 Request start 开始）：

![openresty_phases](../../img/openresty_phases.png)

我们在这里做个测试，示例代码如下：
```nginx
location /mixed {
    set_by_lua_block $a {
        ngx.log(ngx.ERR, "set_by_lua*")
    }
    rewrite_by_lua_block {
        ngx.log(ngx.ERR, "rewrite_by_lua*")
    }
    access_by_lua_block {
        ngx.log(ngx.ERR, "access_by_lua*")
    }
    content_by_lua_block {
        ngx.log(ngx.ERR, "content_by_lua*")
    }
    header_filter_by_lua_block {
        ngx.log(ngx.ERR, "header_filter_by_lua*")
    }
    body_filter_by_lua_block {
        ngx.log(ngx.ERR, "body_filter_by_lua*")
    }
    log_by_lua_block {
        ngx.log(ngx.ERR, "log_by_lua*")
    }
}
```


执行结果日志(截取了一下)：

```
set_by_lua*
rewrite_by_lua*
access_by_lua*
content_by_lua*
header_filter_by_lua*
body_filter_by_lua*
log_by_lua*
```

这几个阶段的存在，应该是 OpenResty 不同于其他多数 Web 平台编程的最明显特征了。由于 Nginx 把一个请求分成了很多阶段，这样第三方模块就可以根据自己行为，挂载到不同阶段进行处理达到目的。OpenResty 也应用了同样的特性。所不同的是，OpenResty 挂载的是我们编写的 Lua 代码。

这样我们就可以根据我们的需要，在不同的阶段直接完成大部分典型处理了。

http 涉及阶段如下：

- init_by_lua*: 自定义初始化，比如全局公用变量等
- init_worker_by_lua*: 初始化worker进程独有的变量等
- set_by_lua*: 流程分支处理判断变量初始化
- rewrite_by_lua*: 转发、重定向、缓存等功能(例如特定请求代理到外网)
- access_by_lua*: IP 准入、接口权限等情况集中处理(例如配合 iptable 完成简单防- 火墙)
- content_by_lua*: 内容生成
- header_filter_by_lua*: 响应头部过滤处理(例如添加头部信息)
- body_filter_by_lua*: 响应体过滤处理(例如完成应答内容统一成大写)
- log_by_lua*: 会话完成后本地异步完成日志记录(日志可以记录在本地，还可以同步到其他机器)

stream（tcp、udp 代理）涉及阶段如下：

- init_by_lua*: 自定义初始化，比如全局公用变量等
- init_worker_by_lua*: 初始化worker进程独有的变量等
- ssl_certificate_by_lua*: SSL 握手过程
- preread_by_lua*: tcp 第一次握手建立的时机
- log_by_lua*: 会话完成后本地异步完成日志记录(日志可以记录在本地，还可以同步到其他机器)

## [openresty基础目录](https://fs7744.github.io/nature/prepare/openresty/index.html)
## [总目录](https://fs7744.github.io/nature/)