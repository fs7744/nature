# 安装 LuaJIT

## liunx (使用openresty内置的luajit)

在安装好openresty之后，配置好对应环境变量，举例如下：

添加如下内容到 ~/.bashrc

``` sh
export PATH="$PATH:/usr/local/openresty/luajit/bin"
```

## linux (单独安装)

到 LuaJIT 官网 [http://luajit.org/download.html](http://luajit.org/download.html) 下载源码


``` sh
wget http://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz
tar -xvf LuaJIT-2.1.0-beta3.tar.gz
cd LuaJIT-2.1.0-beta3
make
sudo make install
sudo ln -sf `pwd`/luajit-2.1.0-beta3 /usr/local/bin/luajit
```

## 验证 LuaJIT 是否安装成功

``` sh
luajit -v
```
得到如下结果
``` sh
LuaJIT 2.1.0-beta3 -- Copyright (C) 2005-2022 Mike Pall. https://luajit.org/
```
## 或者试试 hello world

``` sh
echo "print('hello world')" >> hello.lua
luajit hello.lua
```
得到如下结果
``` sh
hello world
```

## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)