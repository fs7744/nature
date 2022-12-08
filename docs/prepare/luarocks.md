# luarocks介绍

## luarocks 是什么？

luarocks 是lua语言的包管理器

- 支持本地和远程存储库。
- 安装第三方包，甚至可以编译c库

Luarocks 文档： https://github.com/luarocks/luarocks/wiki

## 安装 luarocks

```
wget https://luarocks.org/releases/luarocks-3.7.0.tar.gz
tar zxpf luarocks-3.7.0.tar.gz
cd luarocks-3.7.0
```

Run `./configure --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 --with-lua=/usr/local/openresty/luajit` (如果环境不一样，请按照luarocks配置设置符合自己环境)
Run `make`.
As superuser, run `make install`.
Run `mkdir /root/.luarocks`

如果本机环境无法直接访问github，请用代理访问 github https，设置参考：
```
git config --global url."git@github.com:".insteadOf https://github.com/
git config --global url."git://".insteadOf https://
```


## 命令行

运行luarocks 命令可以看见所有功能命令:
```sh
 luarocks 
```
如果需要获取更详细辅助解释可以使用help:
```sh
 luarocks help install
```
常用的安装包命令如下:
```sh
 luarocks install dkjson
 ## 或者根据rockspec文件安装依赖
 luarocks install package-main-0.rockspec
```
上传包命令：
```sh
luarocks upload luafruits-1.0-1.rockspec --api-key=<your API key>
```

## rockspec 格式

rockspec 是lua包的定义文件，具体格式如下：

``` nginx
package = "xxpack"
version = "main-0"

## 支持远端仓库下载源码编译可以配置 source ，比如下git的配置
source = {
    url = "git+ssh://git@gitxxagent.git", 
    branch = "main",  
} 

## 包描述
description = {
    summary = "",
    homepage = "https://git",
    maintainer = "Victor.X.Qu"
}

## 依赖包
dependencies = {
    "lua >= 5.1, < 5.4", ## 如需限制lua版本可以用这样配置
    "lua-resty-etcd >= 1.8.0",
}

## 如何编译，如下是一些例子
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