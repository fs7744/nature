# 安装 OpenResty 

## Ubuntu

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

## 其他环境参见 https://openresty.org/cn/linux-packages.html

## 设置使用luajit

添加如下内容到 ~/.bashrc

```
export PATH="$PATH:/usr/local/openresty/luajit/bin"
```

## 安装ssl相关库

```
apt-get -y install openresty-openssl111-dev
apt-get -y install git openssl ca-certificates
```
## [openresty基础目录](https://fs7744.github.io/nature/prepare/openresty/index.html)
## [总目录](https://fs7744.github.io/nature/)