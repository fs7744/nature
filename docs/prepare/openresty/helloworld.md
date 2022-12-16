# HelloWorld

`HelloWorld` 是我们亘古不变的第一个入门程序。但是 `OpenResty` 不是一门编程语言，跟其他编程语言的 `HelloWorld` 不一样，让我们看看都有哪些不一样吧。

## 熟悉openresty命令

可以通过 openresty -h 了解相关命令

```sh
$ openresty -h
nginx version: openresty/1.21.4.1
Usage: nginx [-?hvVtTq] [-s signal] [-p prefix]
             [-e filename] [-c filename] [-g directives]

Options:
  -?,-h         : this help
  -v            : show version and exit
  -V            : show version and configure options then exit
  -t            : test configuration and exit
  -T            : test configuration, dump it and exit
  -q            : suppress non-error messages during configuration testing
  -s signal     : send signal to a master process: stop, quit, reopen, reload
  -p prefix     : set prefix path (default: /usr/local/openresty/nginx/)
  -e filename   : set error log file (default: logs/error.log)
  -c filename   : set configuration file (default: conf/nginx.conf)
  -g directives : set global directives out of configuration file
```
可以看到和nginx的命令一模一样 (其实openresty等同于nginx的特殊发行版，配置命令保持一致，只是多了独有的lua部分)

## 创建工作目录

OpenResty 安装之后就有配置文件及相关的目录的，为了工作目录与安装目录互不干扰，并顺便学下简单的配置文件编写，我们另外创建一个 OpenResty 的工作目录来练习，并且另写一个配置文件。我选择在当前用户目录下创建 openresty-test 目录，并在该目录下创建 logs 和 conf 子目录分别用于存放日志和配置文件。

```sh
$ mkdir -p ~/openresty-test ~/openresty-test/logs/ ~/openresty-test/conf/
$ tree ~/openresty-test
/root/openresty-test
├── conf
└── logs

2 directories, 0 files
```

## 创建配置文件

在 conf 目录下创建一个文本文件作为配置文件，命名为 openresty.conf，文件内容如下:

```nginx
worker_processes  1;        #nginx worker 数量
error_log logs/error.log;   #指定错误日志文件路径
events {
    worker_connections 1024;
}

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

## 万事俱备只欠东风

我们启动 openresty 即可，输入命令形式为：`openresty -p ~/openresty-test -c openresty.conf -g 'daemon off;'`，如果没有提示错误。如果提示 openresty 不存在，则需要在环境变量中加入安装路径，可以根据你的操作平台，参考前面的安装章节（一般需要重启生效）。

启动后我们也可以观察 openresty 进程情况
```shell
$ ps -ef | grep nginx
root     27689    11  0 08:39 pts/0    00:00:00 nginx: master process openresty -p /root/openresty-test -c openresty.conf -g daemon off;
nobody   27690 27689  0 08:39 pts/0    00:00:00 nginx: worker process
$ curl http://localhost:6699 -i
HTTP/1.1 200 OK
Server: openresty/1.21.4.1
Date: Fri, 16 Dec 2022 00:43:57 GMT
Content-Type: text/html
Transfer-Encoding: chunked
Connection: keep-alive

HelloWorld
```

## [openresty基础目录](https://fs7744.github.io/nature/prepare/openresty/index.html)
## [总目录](https://fs7744.github.io/nature/)