# nature

nature is api gateway, just show you for how to bulid api gateway

本教程将向大家介绍如何构建一个高性能，动态化，http、tcp的api gateway。

不仅包含一个完整可用的代码框架，也具有完整的实践教程，按图索骥即可拥有编写api gateway的能力。

但是需注意，本教程不会是傻瓜式一步一步带你怎么做，只会拆分细点说明一些核心要点。

具体内容 : [https://fs7744.github.io/nature/](https://fs7744.github.io/nature/)

# 目录

## 知识预备篇

* 概念介绍
    - [gateway 是什么？](prepare/gateway.md)
    - [反向代理是什么？](prepare/reverse_proxy.md)
    - [网络概念](prepare/network.md)
    - [网络协议](prepare/protocol.md)
    - [进程间通讯](prepare/ipc.md)
* [扯一扯技术选型](prepare/choose.md)
* [lua语言](prepare/lua/index.md)
* [luarocks介绍](prepare/lua/luarocks.md)
* [nginx](prepare/nginx.md)
* [openresty基础](prepare/openresty/index.md)  入门者建议按照下面实践教程逐步理解
 
## 实践篇

### tcp 代理

* [了解一下基本的tcp代理配置](tcp/conf.md)
* [如何简化配置](tcp/simple_conf.md)
* [监听yaml配置](tcp/yaml.md)

### http 代理

* [了解一下基本的http代理配置](http/conf.md)
* [路由实现](http/router.md)
* [负载均衡](http/lb.md)
* [健康检查](http/healthcheck.md)
* [基于etcd实现动态配置同步](http/etcd.md)

## nature 代码

* [项目架构](nature/src.md)
* [动态插件](nature/plugin.md)
* [如何为openresty打patch](nature/patch.md)

# 文档概述

本文档目的为介绍如何基于 openresty 构建现代api gateway

使用openresty用于介绍主要避免大家恐惧于高性能一词，也让大家能站于巨人肩上轻松构建高性能api gateway

相应的代码仓库也将为一个实际可用的核心结构，希望如此可惜便于大家理解

需注意，请不要用于商业行为，本文档只为介绍技术这一单一目的

该仓库代码没有经过长时间产线验证且很多部分为了便于理解简化了很多，

而且有很多参考于 openresty 技术代表的标杆api gateway ：[apisix](https://github.com/apache/apisix) 和 [kong](https://github.com/Kong/kong)

如需产线使用，请优先考虑它们，如不够场景则可考虑自建

该文档基础知识部分很多节选自 [OpenResty 最佳实践](https://github.com/moonbingbing/openresty-best-practices/blob/master/SUMMARY.md)， 推荐大家阅读

# 仓库结构说明
```
|- demo             示例，主要为配置示例
|- docs             文档文件夹，所有的说明都在这儿
|- nature           lua 代码文件夹，
|- openresty_patch  如何对openresty做patch的内容
|- t                单元测试示例，主要说明基本单元测试怎么做
|- Makefile         项目构建等基本的命令
|- nature.sh        项目命令行入口示例
```