# Log

Nginx 日志主要有两种：access_log (访问日志) 和 error_log (错误日志)。

## access_log 访问日志

`access_log` 主要记录客户端访问 Nginx 的每一个请求，格式可以自定义。通过 `access_log` 你可以得到用户地域来源、跳转来源、使用终端、某个 URL 访问量等相关信息。

### `log_format` 指令用于定义日志的格式。
- 语法: `log_format name string;`
    - name：表示格式名称
    - string：表示定义的格式字符串

`log_format` 有一个默认的无需设置的组合日志格式。

> 默认格式：

```nginx
log_format combined '$remote_addr - $remote_user  [$time_local]  '
                    ' "$request"  $status  $body_bytes_sent  '
                    ' "$http_referer"  "$http_user_agent" ';
```

### `access_log` 指令
### 用来指定访问日志文件的存放路径（包含日志文件名）、格式和缓存大小。
- 语法：`access_log path [format_name [buffer=size | off]];`
    - path： 表示访问日志存放路径
    - format_name： 表示访问日志格式名称
    - buffer： 表示缓存大小
    - off： 表示关闭访问日志

> log_format 使用示例：

```nginx
# 在 access.log 中记录客户端 IP 地址、请求状态和请求时间
log_format myformat '$remote_addr  $status  $time_local';
access_log logs/access.log  myformat;
```

需要注意的是：
- `log_format` 配置必须放在 `http` 或 `stream` 内，否则会出现警告。
- Nginx 进程设置的用户和组必须对日志路径有创建文件的权限，否则，会报错。

> 定义日志使用的字段及其作用：

以下为 http 常用字段

|  字段                                 |  作用                                                             |
|:--------------------------------------|:------------------------------------------------------------------|
|  $remote_addr 与 $http_x_forwarded_for  |  记录客户端IP地址                                                 |
|  $remote_user                         |  记录客户端用户名称                                               |
|  $request                             |  记录请求的 URI 和 HTTP 协议                                          |
|  $status                              |  记录请求状态                                                     |
|  $body_bytes_sent                     |  发送给客户端的字节数，不包括响应头的大小                         |
|  $bytes_sent                          |  发送给客户端的总字节数                                           |
|  $connection                          |  连接的序列号                                                     |
|  $connection_requests                 |  当前通过一个连接获得的请求数量                                   |
|  $msec                                |  日志写入时间。单位：秒，精度：毫秒                               |
|  $pipe                                |  如果请求是通过 HTTP 流水线 (pipelined) 发送，pipe 值为 “p”，否则为 “.”  |
|  $http_referer                        |  记录从哪个页面链接访问过来的                                     |
|  $http_user_agent                     |  记录客户端浏览器相关信息                                         |
|  $request_length                      |  请求的长度（包括请求行，请求头和请求正文）                       |
|  $request_time                        |  请求处理时间，单位：秒，精度：毫秒                                 |
|  $time_iso8601                        |  ISO8601 标准格式下的本地时间                                      |
|  $time_local                          |  记录访问时间与时区                                               |

以下为 stream 字段

|  字段                                 |  作用                                                             |
|:--------------------------------------|:------------------------------------------------------------------|
|  $remote_addr   |  记录客户端IP地址                                                 |
|  $remote_port   |  记录客户端port址                                                 |
|  $server_addr   |  接受请求的服务ip                                                 |
|  $server_port   |  接受请求的服务port                                                 |
|  $connection                          |  连接的序列号                                                     |
|  $msec                                |  日志写入时间。单位：秒，精度：毫秒                               |
|  $status                              |  记录请求状态                                                     |
|  $time_iso8601                        |  ISO8601 标准格式下的本地时间                                      |
|  $time_local                          |  记录访问时间与时区                                               |

## error_log 错误日志

`error_log` 主要记录客户端访问 Nginx 出错时的日志，格式不支持自定义。
通过查看错误日志，你可以得到系统某个服务或 server 的性能瓶颈等。因此，将日志利用好，你可以得到很多有价值的信息。

### `error_log` 指令用来指定错误日志。
- 语法: `error_log path [level]`;
    - path： 表示错误日志存放路径
    - level： 表示错误日志等级
        日志等级包括（详细程度逐级递减）：
        - debug (最详细)
        - info
        - notice
        - warn
        - error (默认)
        - crit
        - alert
        - emerg (最少)

**注意**：`error_log off` 并不能关闭错误日志记录，此时日志信息会被写入到文件名为 off 的文件当中。如果要关闭错误日志记录，可以使用如下配置：

- (1) Linux 系统把存储位置设置为空设备

    ```nginx

    error_log /dev/null;

    http {
        # ...
    }
    ```

- (2) Windows 系统把存储位置设置为空设备

    ```nginx

    error_log nul;

    http {
        # ...
    }
    ```

另外 Linux 系统可以使用 `tail` 命令方便的查阅正在改变的文件,`tail -f filename` 会把 filename 里最尾部的内容显示在屏幕上, 并且不断刷新, 使你看到最新的文件内容。
Windows 系统没有这个命令，你可以在网上找到动态查看文件的工具。

### lua 中如何操作error log 内容

#### 写入 

默认提供 `ngx.log` 方法， syntax: ngx.log(log_level, ...)

已经处理了 常见的非string 类型处理（如 number -> string ）， 多个string 合并等等，

log_level 如下

``` nginx
ngx.STDERR
ngx.EMERG
ngx.ALERT
ngx.CRIT
ngx.ERR
ngx.WARN
ngx.NOTICE
ngx.INFO
ngx.DEBUG
```

#### 推荐使用 "ngx.errlog"

`ngx.errlog` 可以捕获log 内容， 这样可以做一些比如把log 发送的 es 等等操作

例子如下

```nginx
error_log logs/error.log info;

http {
    # enable capturing error logs
    lua_capture_error_log 32m;

    init_by_lua_block {
        local errlog = require "ngx.errlog"
        local status, err = errlog.set_filter_level(ngx.WARN)
        if not status then
            ngx.log(ngx.ERR, err)
            return
        end
        ngx.log(ngx.WARN, "set error filter level: WARN")
    }

    server {
        # ...
        location = /t {
            content_by_lua_block {
                local errlog = require "ngx.errlog"
                ngx.log(ngx.INFO, "test1")
                ngx.log(ngx.WARN, "test2")
                ngx.log(ngx.ERR, "test3")

                local logs, err = errlog.get_logs(10)
                if not logs then
                    ngx.say("FAILED ", err)
                    return
                end

                for i = 1, #logs, 3 do
                    ngx.say("level: ", logs[i], " time: ", logs[i + 1],
                            " data: ", logs[i + 2])
                end
            }
        }
    }
}
```

结果如下

``` 
level: 5 time: 1498546995.304 data: 2017/06/27 15:03:15 [warn] 46877#0:
    [lua] init_by_lua:8: set error filter level: WARN
level: 5 time: 1498546999.178 data: 2017/06/27 15:03:19 [warn] 46879#0: *1
    [lua] test.lua:5: test2, client: 127.0.0.1, server: localhost, ......
level: 4 time: 1498546999.178 data: 2017/06/27 15:03:19 [error] 46879#0: *1
    [lua] test.lua:6: test3, client: 127.0.0.1, server: localhost, ......
```

## [openresty基础目录](https://fs7744.github.io/nature/prepare/openresty/index.html)
## [总目录](https://fs7744.github.io/nature/)