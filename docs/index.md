# 文档概述

本文档目的为介绍如何基于 openresty 构建现代api gateway

使用openresty用于介绍主要避免大家恐惧于高性能一词，也让大家能站于巨人肩上轻松构建高性能api gateway

相应的代码仓库也将为一个实际可用的核心结构，希望如此可惜便于大家理解

需注意，请不要用于商业行为，本文档只为介绍技术这一单一目的

该仓库代码没有经过长时间产线验证且很多部分为了便于理解简化了很多，

而且有很多参考于 openresty 技术代表的标杆api gateway ：[apisix](https://github.com/apache/apisix) 和 [kong](https://github.com/Kong/kong)

如需产线使用，请优先考虑它们，如不够场景则可考虑自建

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
# 目录

## 知识预备篇

* 概念介绍
    - [gateway 是什么？]()
    - [反向代理是什么？]()
    - [网络概念]()
    - [网络协议]()
* [lua语言介绍]()
* [openresty介绍]()