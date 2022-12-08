# 5. 了解openresty

openresty 最好的教程大概就是这份了：[OpenResty 最佳实践](https://github.com/moonbingbing/openresty-best-practices/blob/master/SUMMARY.md)

最好能先阅读一下这份教程，因为这里不想花时间重复整理对应的知识，毕竟没有动力手把手完成每一个细节知识点，万一没人看，还是先省点力气吧。哈哈哈哈。

本文内容暂只点名大家一定从教程中要了解的内容：

## lua
  - 语法
  - 模块加载机制

## openresty
  - nginx 配置
  - openresty执行阶段概念以及对应api
  - openresty 测试

## 安装 OpenResty 

### Ubuntu

你可以在你的 Ubuntu 系统中添加我们的 APT 仓库，这样就可以便于未来安装或更新我们的软件包（通过 apt-get update 命令）。 运行下面的命令就可以添加仓库（每个系统只需要运行一次）：

步骤一：安装导入 GPG 公钥时所需的几个依赖包（整个安装过程完成后可以随时删除它们）：

```
sudo apt-get -y install --no-install-recommends wget gnupg ca-certificates
```
步骤二：导入我们的 GPG 密钥：

```
wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
```
步骤三：添加我们官方 APT 仓库。

对于 x86_64 或 amd64 系统，可以使用下面的命令：

```
echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
    | sudo tee /etc/apt/sources.list.d/openresty.list
```
而对于 arm64 或 aarch64 系统，则可以使用下面的命令:
```
echo "deb http://openresty.org/package/arm64/ubuntu $(lsb_release -sc) main" \
    | sudo tee /etc/apt/sources.list.d/openresty.list
```
步骤四：更新 APT 索引：
```
sudo apt-get update
```
然后就可以像下面这样安装软件包，比如 openresty：
```
sudo apt-get -y install openresty
```

### 其他环境参见 https://openresty.org/cn/linux-packages.html

### 设置使用luajit

添加如下内容到 ~/.bashrc

```
export PATH="$PATH:/usr/local/openresty/luajit/bin"
```

## 安装ssl相关库

```
apt-get -y install openresty-openssl111-dev
apt-get -y install git openssl ca-certificates
```

## 安装 Test::Nginx

```
sudo cpan Test::Nginx
```

如需代理，请设置：

```
perl -MCPAN -e shell
```

在 perl shell 中
```
o conf init /proxy/
```

按照提示设置代理
最后一定要

```
o conf commit
```

可以通过如下命令查看已设置效果
```
o conf http_proxy
```

ctrl + D 可跳出 perl 的 shell.

添加如下内容到 ~/.bashrc

```
export PATH=/usr/local/openresty/nginx/sbin:$PATH
```

文档： https://metacpan.org/pod/Test::Nginx
