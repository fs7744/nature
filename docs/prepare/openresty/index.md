# openresty介绍

OpenResty(又称：ngx_openresty) 是一个基于 NGINX 的可伸缩的 Web 平台，由中国人章亦春发起，提供了很多高质量的第三方模块。

OpenResty 是一个强大的 Web 应用服务器，Web 开发人员可以使用 Lua 脚本语言调动 Nginx 支持的各种 C 以及 Lua 模块,更主要的是在性能方面，OpenResty可以 快速构造出足以胜任 10K 以上并发连接响应的超高性能 Web 应用系统。

openresty 最好的教程大概就是这份了：[OpenResty 最佳实践](https://github.com/moonbingbing/openresty-best-practices/blob/master/SUMMARY.md)

以下内容为整理后的简化内容，大家不一定按照顺序阅读，可以参考总目录的教程顺序入手或者选择自己兴趣点优先阅读。

## openresty基础目录

* [安装](install.md)
* [helloworld](helloworld.md)
* [理解执行阶段](phase.md)
* [使用 Nginx 内置绑定变量](inline_var.md)
* [不同阶段共享变量](share_var.md)
- [理解openresty 不同进程](process.md)
- [理解openresty timer](timer.md)
- [怎样理解 cosocket](cosocket.md)
## 测试目录

* [测试框架安装](test_install.md)

