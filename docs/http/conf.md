# 了解一下基本的http代理配置

我们首先用一个简单例子了解一下基本的http代理配置

```nginx
worker_processes  1;        #nginx worker 数量
error_log logs/error.log;   #指定错误日志文件路径
events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr [$time_local] $status $request_time $upstream_status $upstream_addr $upstream_response_time';
    access_log logs/access.log main buffer=16384 flush=3;            #access_log 文件配置

    upstream nature_upstream {
        server 127.0.0.1:6699; #upstream 配置为 hello world 服务
    }

    server {
		#监听端口，若你的8699端口已经被占用，则需要修改
        listen 8699 reuseport;

        location / {
            proxy_http_version                  1.1;
            proxy_pass http://nature_upstream; #转发到 upstream
        }
    }


    #为了大家方便理解和测试，我们引入一个hello world 服务
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
127.0.0.1 [27/Dec/2022:16:53:26 +0800] 200 0.000 200 127.0.0.1:6699 0.000 # 8699端口的代理服务记录
127.0.0.1 [27/Dec/2022:16:53:26 +0800] 200 0.000 - - - # 6699端口的hello world 服务记录
```

如此基本的配置，大家就算了解了。

大家也可以思考一下为什么 access.log 的顺序与之前tcp配置的结果相反

## [目录](https://fs7744.github.io/nature/)