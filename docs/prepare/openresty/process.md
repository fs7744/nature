# openresty 不同进程

OpenResty 里的进程分为如下六种类型：

* single：单一进程，即非 master/worker 模式；
* master：监控进程，即 master 进程；
* signaller：信号进程，即 “-s” 参数时的进程；
* worker：工作进程，最常用的进程，处理大家请求的的进程， 一般一个对应一个cpu核心；
* helper：辅助进程，不对外提供服务，例如 cache 进程；
* privileged agent：特权进程，OpenResty 独有的进程类型。

当前代码所在的进程类型可以用函数 `ngx.process.type` 获取，例如：

``` lua
local process require "ngx.process"                             
local str = process.type()                                      -- 获取当前的进程类型
ngx.say("type is", str)                                         -- 通常就是 "worker"
```

## privileged agent 特权进程

特权进程是一种特殊的 worker 进程，权限与 master 进程一致（通常就是 root），拥有其他 worker 进程相同的数据和代码，但关闭了所有的监听端口，不对外提供服务，像是一个 “沉默的聋子”。

特权进程必须显式调用函数 ngx.process.enable_privileged_agent 才能启用。而且只能在 “init_by_lua” 阶段里运行，通常的形式是：

``` nginx
init_by_lua_block {
    local process = require "ngx.process"
    local ok, err = process.enable_privileged_agent()           -- 启动特权进程
    if not ok then                                              -- 检查是否启动成功
        ngx.log(ngx.ERR, "failed: ", err)
    end
}
```

因为关闭了所有的监听端口，特权进程不能接受请求，“rewrite_by_lua” “access_by_lua” "content_by_lua" “log_by_lua” 等请求处理相关的执行阶段没有意义，这些阶段里的代码在特权进程里都不会运行。

但有一个阶段是它可以使用的，那就是 “init_worker_by_lua”，特权进程要做的工作就是 ngx.timer.* 启动若干个定时器，运行周期任务，通过共享内存等方式与其他 worker 进程通信，利用自己的 root 权限做其他 worker 进程想做而不能做的工作。

例如我们这里用来检查配置变化

或者可以用 get_master_pid 获取 master 进程的 pid，然后在特权进程里调用系统命令 kill 发送 SIGHUP/SIGQUIˇ/SIGUSRl 等信号，实现服务的自我管理。

## 进程管理

大家常用的 nginx 命令中的 热重启便是利用了各个系统标准定义的系统进程标准信号， 如下为在lua 中如何手动调用, 

``` lua
local process = require("ngx.process")
local signal = require('resty.signal')

signal.kill(process.get_master_pid(), signal.signum("HUP")) -- reload

signal.kill(process.get_master_pid(), signal.signum("QUIT")) -- quit

signal.kill(process.get_master_pid(), signal.signum("USR1")) -- reopen_log
```

所以大家就可以在特权进程完成这些自我管理行为。

## [openresty基础目录](https://fs7744.github.io/nature/prepare/openresty/index.html)
## [总目录](https://fs7744.github.io/nature/)