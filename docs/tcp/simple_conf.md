# 如何简化配置

上述说过openresty本身配置复杂，上手难度高，也不利于分发配置，为什么呢？

1. 配置格式有着比较复杂的语法，不是单纯的数据，所以学习成本高了
2. 配置有了复杂的语法，变更时不像一条数据更改那么容易，可能导致格式错乱，也就不利于分发配置了

那么我们第一步就着眼于如何让大家不需要学习nginx配置语法，(动态配置等等问题后续再逐步实践演示)

openresty本身的配置我们不可能在不修改源码情况下去除，

不过其本身其实不太复杂，核心复杂的地方是路由关系处理这部分：
- tcp 哪个端口对应哪个后端服务，比如 8999 对应 www.baidu.com 还是www.google.com
- http  同理 /api/a 对应哪个后端服务，是对应 www.baidu.com 还是www.google.com

当有大量路由配置需要在一个多个文件中且还有语法关系关联呈现，复杂度就高了

如果能用代码来处理这些数据，那么大家配置必然简单了。

那么openresty 是否有相关api让我们修改upstream信息吗？

## ngx.balancer

ngx.balancer 模块可以当前请求转到哪里，是对应 www.baidu.com 还是www.google.com

一个简单演示如下

``` nginx
worker_processes  1;        
error_log logs/error.log;   
events {
    worker_connections 1024;
}

stream {
    log_format main '$remote_addr [$time_local] $protocol $status';  
    access_log logs/access.log main buffer=16384 flush=3;            

    upstream nature_upstream {
        server 127.0.0.1:80; # 占位，因为openresty 配置语法检查必须要有

        balancer_by_lua_block {
            local balancer = require "ngx.balancer"

            local host = "127.0.0.1"
            local port = 6699

            local ok, err = balancer.set_current_peer(host, port)  --核心靠set_current_peer方法设置请求转发的地址， 需注意host必须为ip，所以域名只能自己先dns解析到ip使用
            if not ok then
                ngx.log(ngx.ERR, "failed to set the current peer: ", err)
                return ngx.exit(ngx.ERROR)
            end
        }
    }

    server {
        listen 8699 reuseport;

        proxy_pass nature_upstream; 
    }
}

http {
    server {
        listen 6699;
        location / {
            default_type text/html;

            content_by_lua_block {
                ngx.say("HelloWorld")
            }
        }
    }
}
```

## 还可以利用不同执行阶段初始化 upstream 数据

例子如下 （篇幅关系，简化为仅仅变更的部分，后续如此）

``` nginx
stream {  

    init_by_lua_block {
        -- 初始化数据，这里先模拟
        upstreams = {['8699'] = { host ="127.0.0.1", port = 6699 }}
    }        

    upstream nature_upstream {
        server 127.0.0.1:80; # 占位，因为openresty 配置语法检查必须要有

        balancer_by_lua_block {
            local balancer = require "ngx.balancer"
            local upstream = ngx.ctx.api_ctx.upstream
            local ok, err = balancer.set_current_peer(upstream.host, upstream.port)
            -- 核心靠set_current_peer方法设置请求转发的地址， 需注意host必须为ip，所以域名只能自己先dns解析到ip使用
            if not ok then
                ngx.log(ngx.ERR, "failed to set the current peer: ", err)
                return ngx.exit(ngx.ERROR)
            end
        }
    }

    server {
        listen 8699 reuseport;
        listen 8689 reuseport; #添加一个其他端口模拟测试没有端口配置的情况

        proxy_pass nature_upstream; 

        preread_by_lua_block {
            -- ngx.var.server_port 该变量可以获取到当前请求访问到的port
            -- 我们这里用port确定后端upstream 是哪个
            -- 没有对应配置则直接返回404 终止该tcp连接
            local upstream = upstreams[tostring(ngx.var.server_port)]
            if upstream then
                ngx.ctx.api_ctx = { upstream = upstream }
            else
                ngx.exit(404)
            end
            
        }
    }
}
```

完整的例子在： [simple_conf.conf](https://github.com/fs7744/nature/blob/main/docs/demo/simple_conf.conf)

下一篇将介绍如何读取yaml中的配置以及如何监听变化

## [目录](https://fs7744.github.io/nature/)