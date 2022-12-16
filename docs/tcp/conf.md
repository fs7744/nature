# 了解一下基本的tcp代理配置

我们首先用一个简单例子了解一下基本的tcp代理配置

```nginx
worker_processes  1;        #nginx worker 数量
error_log logs/error.log;   #指定错误日志文件路径
events {
    worker_connections 1024;
}

stream {
    log_format main '$remote_addr [$time_local] $protocol $status';  #access_log format: 访问的远端服务地址 时间 协议 状态码
    access_log logs/access.log main buffer=16384 flush=3;            #access_log 文件配置

    upstream nature_upstream {
        server 127.0.0.1:6699; #upstream 配置为 hello world 服务
    }

    server {
		#监听端口，若你的8699端口已经被占用，则需要修改
        listen 8699 reuseport;

        proxy_pass nature_upstream; #转发到 upstream
    }
}

#为了大家方便理解和测试，我们引入一个hello world 服务
http {
    server {
		#监听端口，若你的6699端口已经被占用，则需要修改
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

启动服务并测试
```sh
$ openresty -p ~/openresty-test -c openresty.conf #启动
$ curl http://localhost:8699 -i  #测试
HTTP/1.1 200 OK
Date: Fri, 16 Dec 2022 05:19:34 GMT
Content-Type: text/html
Transfer-Encoding: chunked
Connection: keep-alive

HelloWorld
```
观察 access.log 文件可以看到有两条记录
```sh
$ cat logs/access.log
127.0.0.1 - - [16/Dec/2022:13:23:22 +0800] "GET / HTTP/1.1" 200 21 "-" "curl/7.68.0" # 6699端口的hello world 服务记录
127.0.0.1 [16/Dec/2022:13:23:22 +0800] TCP 200  # 8699端口的代理服务记录
```

如此基本的配置，大家就算了解了。

但是也可以看到如此配置，大家可以发现离一个优秀的gateway来说，

除了少了漂亮的UI之外，至少少了以下要点：

1. 配置复杂，上手难度高，nginx配置毕竟算包含逻辑
2. 多实例，动态配置变更不支持
4. 不能动态变更处理逻辑（代码）

接下来就逐步来实践如何优化解决这些配置问题，当然也希望大家首先思考一下这些问题原因在哪儿

## [目录](https://fs7744.github.io/nature/)