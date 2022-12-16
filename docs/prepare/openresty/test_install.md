# 安装 Test::Nginx

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

## [openresty基础目录](https://fs7744.github.io/nature/prepare/openresty/index.html)
## [总目录](https://fs7744.github.io/nature/)