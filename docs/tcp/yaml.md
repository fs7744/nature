# 监听yaml配置

接下来我们试试从yaml文件中读取配置，当然这不是动态配置分发的好方式

别急，一口吃不成大胖子

这里其实会为大家介绍不少东西：

- 如何引入第三方库以及配置openresty
- lua 文件读取
- yaml 库
- openresty init_worker
- openresty timer
- privileged agent
- 代码触发 openresty 热重启

## 创建yaml配置文件

手动创建conf.yaml文件

```sh
$ touch conf.yaml
```
以下内容写入 conf.yaml

```yaml
upstream:
  a8699:
    host: '127.0.0.1'
    port: 6699

```

非常简单地一个upstream配置， 如果大家配置都是这样简单，是不是nginx用起来会舒服（不过现实总是那么不简单）

接下来我们来实现如何读取它呢

## 引入yaml库

我们将使用 luarocks 这个lua包管理工具，其介绍在[luarocks介绍](../prepare/lua/luarocks.md)，这里不再赘述，如不了解请一定要查阅。

首先我们手动创建luarocks文件

```sh
$ touch openresty-dev-1.rockspec
```
以下内容写入 openresty-dev-1.rockspec
``` nginx
package = "openresty"
version = "dev-1"

-- 自己编写第三方库时，如果希望别人远端仓库下载当前源码编译可以配置 source ，比如下git的配置
source = {
   url = "git+ssh://git@github.com:fs7744/nature.git",
   branch = "main",
}
-- 包描述
description = {
   homepage = "https://github.com/fs7744/nature",
   maintainer = "Victor.X.Qu"
}

-- 依赖包
dependencies = {
    "lua-tinyyaml >= 1.0",
}

-- 当前包如何编译，这里列举openresty常遇见的一些参数
build = {
    type = "make",
    build_variables = {
        CFLAGS="$(CFLAGS)",
        LIBFLAG="$(LIBFLAG)",
        LUA_LIBDIR="$(LUA_LIBDIR)",
        LUA_BINDIR="$(LUA_BINDIR)",
        LUA_INCDIR="$(LUA_INCDIR)",
        LUA="$(LUA)",
        OPENSSL_INCDIR="$(OPENSSL_INCDIR)",
        OPENSSL_LIBDIR="$(OPENSSL_LIBDIR)",
    },
    install_variables = {
        INST_PREFIX="$(PREFIX)",
        INST_BINDIR="$(BINDIR)",
        INST_LIBDIR="$(LIBDIR)",
        INST_LUADIR="$(LUADIR)",
        INST_CONFDIR="$(CONFDIR)",
    },
}
```

这里不使用 `luarocks init`是因为其默认项目结构包含了太多我们不需要的东西，为了不干扰大家，就说明了。

为了方便大家测试，我们将yaml 依赖包安装到当前目录下

```sh
$ luarocks install openresty-dev-1.rockspec --tree=deps --only-deps
# 得到以下执行结果
Missing dependencies for openresty dev-1:
   lua-tinyyaml >= 1.0 (not installed)

openresty dev-1 depends on lua-tinyyaml >= 1.0 (not installed)
Installing https://luarocks.org/lua-tinyyaml-1.0-0.rockspec
Cloning into 'lua-tinyyaml'...
remote: Enumerating objects: 13, done.
remote: Counting objects: 100% (13/13), done.
remote: Compressing objects: 100% (13/13), done.
remote: Total 13 (delta 0), reused 8 (delta 0), pack-reused 0
Unpacking objects: 100% (13/13), 10.32 KiB | 330.00 KiB/s, done.
Note: switching to 'b130c2b375d4560d5b812e1a9c3a60b2a0338d65'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false


No existing manifest. Attempting to rebuild...
lua-tinyyaml 1.0-0 is now installed in /root/openresty-test/deps (license: MIT License)

Stopping after installing dependencies for openresty dev-1

# 查看目录可以看到完整的包结构
$ tree deps/
deps/
├── lib
│   └── luarocks
│       └── rocks-5.1
│           ├── lua-tinyyaml
│           │   └── 1.0-0
│           │       ├── doc
│           │       │   ├── LICENSE
│           │       │   └── README.md
│           │       ├── lua-tinyyaml-1.0-0.rockspec
│           │       └── rock_manifest
│           └── manifest
└── share
    └── lua
        └── 5.1
            └── tinyyaml.lua
```

## 在openresty中引入当前目录依赖包

大家可以基于上一节中的配置文件修改，（这来不列举完整的内容，避免篇幅过长）

在其中添加如下配置

``` nginx
# 在 stream 下面添加
stream {

    # $prefix 为 启动openresty 时的参数 -p prefix 
    # 下面比较长的路径是将各种情况列举处理，基本满足了一般liunx环境下依赖包搜索的大部分可能性
    lua_package_path  "$prefix/deps/share/lua/5.1/?.lua;$prefix/deps/share/lua/5.1/?/init.lua;$prefix/?.lua;$prefix/?/init.lua;;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua;";
    lua_package_cpath "$prefix/deps/lib64/lua/5.1/?.so;$prefix/deps/lib/lua/5.1/?.so;;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;";
    # 开启 lua code 缓存
    lua_code_cache on;  
}
```

## 在init 时机读取yaml配置

``` nginx
stream {
    init_by_lua_block {
        -- 文件读取比较长，这里用函数避免影响大家理解
        local function read_all(path)
            local open  = io.open
            local close = io.close
            local file, data, err
            file, err = open(path, "rb")
            if not file then
                return nil, "open: " .. path .. " with error: " .. err
            end

            data, err = file:read("*all")
            if err ~= nil then
                file:close()
                return nil, "read: " .. path .. " with error: " .. err
            end

            file:close()
            return data
        end
    
        local yaml_path = ngx.config.prefix()..'/conf.yaml'
        -- 读取 yaml 文件
        local content, err = read_all(yaml_path)
        -- 转换yaml数据为lua table结构
        local yaml = require("tinyyaml")
        local conf = yaml.parse(content)
        -- 设置到全局变量中
        upstreams = conf.upstream
    }        

    server {
        preread_by_lua_block {
             -- 这里故意加了个a前缀以区分之前的测试代码
            local upstream = upstreams['a'..tostring(ngx.var.server_port)]
        }
    }
}
```

启动服务并测试，与之前保持一样效果
```sh
$ openresty -p ~/openresty-test -c openresty.conf #启动
$ curl http://localhost:8699 -i  #测试
HTTP/1.1 200 OK
Date: Fri, 16 Dec 2022 05:19:34 GMT
Content-Type: text/html
Transfer-Encoding: chunked
Connection: keep-alive

HelloWorld
$ curl http://localhost:8689 -i  #测试没有upstrem的情况
curl: (56) Recv failure: Connection reset by peer
```

## 如何监控yaml文件变动呢？

大家都知道我们不可能像指挥家里小朋友帮我们打酱油一样随意指挥系统在文件变化时通知我们的程序。

不过我们可以安排我们的程序定时检查文件是否被修改了

### 定时任务api

openresty 里面 可以做定时任务的api 为 `ngx.timer.every`

我们试一试

``` nginx
stream {
    init_by_lua_block {
        ngx.timer.every(1, function()
            ngx.log(ngx.ERR, 'hello ngx.timer.every')
        end)
    }
```

启动服务并测试
```sh
$ openresty -p ~/openresty-test -c openresty.conf -g 'daemon off;' #启动
nginx: [error] init_by_lua error: init_by_lua:31: no request
stack traceback:
        [C]: in function 'every'
        init_by_lua:31: in main chunk
# 很不幸，报错了
```

为什么呢？

其实大家在查阅 openresty api 文档时，总是会看到有很长一个 context 列表，里面全是一些执行阶段

#### ngx.timer.every
---------------

**syntax:** *hdl, err = ngx.timer.every(delay, callback, user_arg1, user_arg2, ...)*

**context:** *init_worker_by_lua&#42;, set_by_lua&#42;, rewrite_by_lua&#42;, access_by_lua&#42;, content_by_lua&#42;, header_filter_by_lua&#42;, body_filter_by_lua&#42;, log_by_lua&#42;, ngx.timer.&#42;, balancer_by_lua&#42;, ssl_certificate_by_lua&#42;, ssl_session_fetch_by_lua&#42;, ssl_session_store_by_lua&#42;, ssl_client_hello_by_lua&#42;*

Similar to the `ngx.timer.at` API function, but

.....

这是openresty以及nginx设计带来的限制，只允许在对应执行阶段运行相应的api

简单来说：

为了高性能，openresty 利用nginx的事件通知机制 + 协程 避免了自身执行的阻塞，

但是大家写代码总是喜欢同步阻塞的思路，为了减少你等我，我等你等死锁情况以及nginx在一些宝贵的执行阶段对资源、时间非常“小气”，所以限制了很多api的使用

比如 init 阶段， nginx的事件通知机制并未完全建立，所以很多api无法使用

总之这些限制出于性能与安全的考虑。（详细可以参考openresty）


我们换到 init_worker

``` nginx
stream {
    init_worker_by_lua_block {
        ngx.timer.every(1, function()
            ngx.log(ngx.ERR, 'hello ngx.timer.every')
        end)
    }
```

启动服务
```sh
$ openresty -p ~/openresty-test -c openresty.conf #启动
$ cat logs/error.log
# 可以看到每秒都有两个执行log，这由于我们启动了2个worker，所以init_worker_by_lua_block被执行了两次
2022/12/17 15:55:45 [error] 2784#2784: *19 stream [lua] init_worker_by_lua:3: hello ngx.timer.every, context: ngx.timer
2022/12/17 15:55:45 [error] 2785#2785: *20 stream [lua] init_worker_by_lua:3: hello ngx.timer.every, context: ngx.timer
2022/12/17 15:55:46 [error] 2784#2784: *21 stream [lua] init_worker_by_lua:3: hello ngx.timer.every, context: ngx.timer
2022/12/17 15:55:46 [error] 2785#2785: *22 stream [lua] init_worker_by_lua:3: hello ngx.timer.every, context: ngx.timer
```

如果我们想只有一个 worker 处理，我们也可以通过 判断`ngx.worker.id()`实现，

不过更加推荐以下的特权进程方式

### 特权进程

特权进程 是为了不影响 worker 处理用户真实请求，而大家总有额外处理其他东西的需求，比如我们这里的监听文件变化，不需要每个worker都监听

特权进程很特别：

它不监听任何端口，这就意味着不会对外提供任何服务；

它拥有和 master 进程一样的权限，一般来说是 root 用户的权限，这就让它可以做很多 worker 进程不可能完成的任务；

特权进程只能在 init_by_lua 上下文中开启；

我们改动一下代码

``` nginx
stream {
    init_by_lua_block {
        -- 开启特权进程
        local process = require("ngx.process")
        local ok, err = process.enable_privileged_agent()
        if not ok then
            log.error("failed to enable privileged_agent: ", err)
        end
    }

    init_worker_by_lua_block {
        -- 限制只允许特权进程执行 hello ngx.timer.every
        if require("ngx.process").type() ~= "privileged agent" then
            return
        end
        ngx.timer.every(1, function()
            ngx.log(ngx.ERR, 'hello ngx.timer.every')
        end)
    }
}
```

启动服务
```sh
$ openresty -p ~/openresty-test -c openresty.conf #启动
$ cat logs/error.log
# 可以看到只有每秒一个执行log
2022/12/17 16:13:50 [error] 3094#3094: *7 stream [lua] init_worker_by_lua:7: hello ngx.timer.every, context: ngx.timer
2022/12/17 16:13:51 [error] 3094#3094: *8 stream [lua] init_worker_by_lua:7: hello ngx.timer.every, context: ngx.timer
2022/12/17 16:13:52 [error] 3094#3094: *9 stream [lua] init_worker_by_lua:7: hello ngx.timer.every, context: ngx.timer
```

### 监听文件变化

实现如下

``` nginx
stream {
    init_worker_by_lua_block {
        -- 限制只允许特权进程执行 文件监听
        if require("ngx.process").type() ~= "privileged agent" then
            return
        end
        -- 对比变化占位变量
        local yaml_change_time = nil
        ngx.timer.every(1, function()
            -- 获取文件属性
            local lfs    = require("lfs")
            local yaml_path = ngx.config.prefix()..'/conf.yaml'
            local attributes, err = lfs.attributes(yaml_path)
            if not attributes then
                ngx.log(ngx.ERR, "failed to fetch ", yaml_path, " attributes: ", err)
                return
            end
            -- 对比变化时间
            local last_change_time = attributes.change
            if yaml_change_time == last_change_time then
                return
            end
            yaml_change_time = last_change_time
            ngx.log(ngx.ERR, yaml_path,' change at ', yaml_change_time)
        end)
    }
}
```

启动服务
```sh
$ openresty -p ~/openresty-test -c openresty.conf #启动
# 我们修改几次conf.yaml文件后
$ cat logs/error.log
# 可以看到每次变化时都有log输出
2022/12/17 16:21:11 [error] 3211#3211: *4 stream [lua] init_worker_by_lua:23: /root/openresty-test//conf.yaml change at 1671247838, context: ngx.timer
2022/12/17 16:21:21 [error] 3211#3211: *14 stream [lua] init_worker_by_lua:23: /root/openresty-test//conf.yaml change at 1671265280, context: ngx.timer
```

### 如何通知配置变化呢？

由于我们监听yaml文件是在特权进程，无法直接更新worker进程内的upstream数据

当然我们可以通过一些进程间通信机制实现，

但这里篇幅关系，我们先直接最简单办法，让 openresty 热重启，重新读取配置

实现如下：

``` nginx
stream {
    init_worker_by_lua_block {
        -- 对比变化占位变量
        local yaml_change_time = nil
        ngx.timer.every(1, function()
            -- 省略代码
            yaml_change_time = last_change_time
            
            -- 发送热重启信号
            local signal = require('resty.signal')
            signal.kill(process.get_master_pid(), signal.signum("HUP"))
        end)
    }
}
```

在启动服务后，

直接测试，可以得到与之前相反的结果
```sh
$ curl http://localhost:8699 -i  #测试， yaml配置还有upstrem的情况
HTTP/1.1 200 OK
Date: Sat, 17 Dec 2022 08:39:35 GMT
Content-Type: text/html
Transfer-Encoding: chunked
Connection: keep-alive

HelloWorld
$ curl http://localhost:8689 -i  #测试 yaml配置没有upstrem的情况
curl: (56) Recv failure: Connection reset by peer
```

我们修改conf.yaml

```yaml
upstream:
  a8689:
    host: '127.0.0.1'
    port: 6699
```

直接测试，可以得到与之前相反的结果
```sh
$ curl http://localhost:8699 -i  #测试， yaml配置已经没有upstrem的情况
curl: (56) Recv failure: Connection reset by peer
$ curl http://localhost:8689 -i  #测试 yaml配置已经有upstrem的情况
HTTP/1.1 200 OK
Date: Sat, 17 Dec 2022 08:39:59 GMT
Content-Type: text/html
Transfer-Encoding: chunked
Connection: keep-alive

HelloWorld
```

完整的例子在： [https://github.com/fs7744/nature/blob/main/docs/demo/yaml](https://github.com/fs7744/nature/blob/main/docs/demo/yaml)

## 小结

我们完成一个基本的tcp代理动态配置的实现，

也同时也简单了解了

- 如何引入第三方库以及配置openresty
- lua 文件读取
- yaml 库
- openresty init_worker
- openresty timer
- privileged agent
- 代码触发 openresty 热重启

以下针对一些特别介绍，大家要想搞懂openresty，一定要阅读和理解

- [luarocks介绍](../prepare/lua/luarocks.md)
- [curl](https://curl.se/docs/manpage.html)
- [openresty log](../prepare/openresty/log.md)
- [lua file操作](../prepare/lua/file.md)
- [理解openresty 执行阶段](../prepare/openresty/phase.md)
- [理解openresty 不同进程](../prepare/openresty/process.md)
- [理解openresty timer](../prepare/openresty/timer.md)
- [热重启机制](../prepare/openresty/hup.md)
- [进程间通讯](../prepare/ipc.md)


## [目录](https://fs7744.github.io/nature/)