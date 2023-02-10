# 项目架构

nature 是一个简化的api gateway，具体内容可以参考下面结构

```
|- demo             示例，主要为配置示例
|- docs             文档文件夹，所有的说明都在这儿
|- nature           lua 代码文件夹，
    |- balancer     负载均衡实现
    |- cli          命令行
    |- config       配置同步实现（etcd、yaml）
    |- core         核心lua辅助库 （动态插件实现、context实现等）
    |- discovery    服务发现  （dns、配置）
    |- plugins      插件 （waf）
    |- router       路由实现
|- openresty_patch  如何对openresty做patch的内容
|- t                单元测试示例，主要说明基本单元测试怎么做
|- Makefile         项目构建等基本的命令
|- nature.sh        项目命令行入口示例
```

## [目录](https://fs7744.github.io/nature/)