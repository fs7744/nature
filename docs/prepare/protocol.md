# 网络协议

## 什么是网络协议？
在网络中，协议是一套用于格式化和处理数据的规则。网络协议就像计算机的一种共同语言。一个网络中的计算机可能会使用截然不同的软件和硬件，然而，协议的使用使它们能够相互通信。

标准化协议就像计算机可以使用的共同语言，类似于来自世界不同地区的两个人可能不理解对方的母语，但他们可以使用共同的第三语言进行交流。如果一台计算机使用互联网协议 (IP)，而第二台计算机也使用该协议，它们将能够进行通信——就像联合国依靠其 6 种官方语言在全球各地的代表之间进行交流一样。但是，如果一台电脑使用 IP，而另一台电脑不知道该协议，则它们将无法通信。

在互联网上，不同类型的进程有不同的协议。协议通常与进程在 OSI 模型中所属的层相关。

例如，互联网协议 (IP) 通过表明数据包*的来源和目的地，对数据进行路由。IP 使网络到网络的通信成为可能。因此，IP 被认为是一个网络层（第 3 层）协议。

再比如，传输控制协议 (TCP) 用于确保数据包在网络上的运输顺利进行。因此，TCP 被认为是一个传输层（第 4 层）协议。

*数据包是一个小的数据段，所有通过网络发送的数据都被分成多个数据包。

## 哪些协议在网络层运行？
如上所述，IP 是一个负责路由的网络层协议，但它不是唯一的网络层协议。

- IPsec：互联网协议安全性 (IPsec) 通过虚拟专用网络 (VPN) 建立加密、认证的 IP 连接。从技术上讲，IPsec 不是一个协议，而是一个协议的集合，包括封装安全协议 (ESP)、身份验证头 (AH) 和安全关联 (SA)。

- ICMP：互联网控制信息协议 (ICMP) 报告错误并提供状态更新。例如，如果一个路由器无法传送一个数据包，它将传回一个 ICMP 消息到数据包的来源。

- IGMP：互联网组管理协议 (IGMP) 建立一对多的网络连接。IGMP 有助于设置多播，这意味着多台计算机可以接收指向一个 IP 地址的数据包。

## 互联网上还使用哪些协议？
需要了解的一些重要协议包括：

- TCP：前面讲过，TCP 是一个传输层协议，用于确保可靠的数据传输。TCP 与 IP 一起使用，这两个协议经常被合称为 TCP/IP。

- HTTP： 超文本传输协议 (HTTP) 是万维网（大多数用户与之交互的互联网）的基础，用于在设备之间传输数据。HTTP 属于应用程序层（第 7 层），因为它将数据转换成应用程序（如浏览器）无需进一步解释即可直接使用的格式。OSI 模型的较低层由计算机的操作系统处理，而非应用程序。

    - HTTP/1.1 – 标准化的协议于1997年初发布，文本协议，基于tcp
    - HTTP/2 - 为了更优异的表现，在 2010 年到 2015 年，谷歌通过实践了一个实验性的 SPDY 协议，证明了一个在客户端和服务器端交换数据的另类方式。其收集了浏览器和服务器端的开发者的焦点问题。明确了响应数量的增加和解决复杂的数据传输，SPDY 成为了 HTTP/2 协议的基础。
  
        HTTP/2 在 HTTP/1.1 有几处基本的不同：

            - HTTP/2 是二进制协议而不是文本协议。不再可读，也不可无障碍的手动创建，改善的优化技术现在可被实施。
            - 这是一个复用协议。并行的请求能在同一个链接中处理，移除了 HTTP/1.x 中顺序和阻塞的约束。
            - 压缩了 headers。因为 headers 在一系列请求中常常是相似的，其移除了重复和传输重复数据的成本。
            - 其允许服务器在客户端缓存中填充数据，通过一个叫服务器推送的机制来提前请求。
    - HTTP/3 - 仍在开发中，主要目的为替换tcp，基于一种新的传输协议 QUIC 上运行。QUIC 专为移动密集型互联网使用而设计，在这种环境中，人们携带的智能手机会在一天中不断地从一个网络切换到另一个网络。开发第一个互联网协议时情况并非如此：当时设备的便携性较差，且不经常切换网络。

QUIC 的使用意味着 HTTP/3 依赖于用户数据报协议 (UDP)，而不是传输控制协议 (TCP)。切换到 UDP 将使在线浏览时的连接速度和用户体验更快。

QUIC 协议由 Google 于 2012 年开发，并在互联网工程任务组 (IETF)（一个厂商中立的标准组织）开始创建新的 HTTP/3 标准时采用。在咨询了世界各地的专家之后，IETF 进行了许多更改以开发自己的 QUIC 版本。

- HTTPS：HTTP 的问题是它没有加密，任何截获 HTTP 信息的攻击者都可以读取它。HTTPS（HTTP 安全）通过加密 HTTP 信息修复了此问题。

- TLS/SSL：传输层安全性 (TLS) 是 HTTPS 用于加密的协议。TLS 曾被称为安全套接字层 (SSL)。

- UDP：用户数据报协议 (UDP) 是传输层中 TCP 的一个替代品，速度更快，但没那么可靠。它经常被用于视频流和游戏等服务，在这些服务中，快速的数据传输最为重要。

## 路由器使用什么协议？
网络路由器使用某些协议来发现通往其他路由器的最有效网络路径。这些协议不用于传输用户数据。重要的网络路由协议包括：

- BGP：边界网关协议 (BGP) 是一个应用程序层协议，网络使用该协议来广播它们控制的 IP 地址。该信息可让路由器决定数据包在前往目的地的途中应经过哪些网络。

- EIGRP：增强型内部网关路由协议 (EIGRP) 用于识别路由器之间的距离。EIGRP 自动更新每个路由器的最佳路由记录（称为路由表），并将这些更新广播给网络内的其他路由器。

- OSPF：开放式最短路径优先 (OSPF) 协议根据各种因素（包括距离和带宽）计算最有效的网络路线。

- RIP：路由信息协议 (RIP) 是一个较早的路由协议，用于识别路由器之间的距离。RIP 是一个应用程序层协议。

## 网络协议对网关软件的困扰

可以看到网络协议如此繁花似锦，上述列举的主体协议之外，还有各种场景有着自己的协议，甚至mysql，redis也是有着自己的通信协议。

不过基本99.9%都是基于tcp、udp，这两核心协议无论在系统、网卡、编程语言都有着强大的支持。所以对网关来说，支持了他们俩无疑等同于支持了全部。

但是对于具体网站的性能优化上，无论在复用、安全等各方面存在缺失，所以也是http的七层负载均衡代理软件网关如此流行的原因。

支持如此多协议便是对开发网关软件终身的困扰，只有协议没有使用的那天，才是网关不支持协议的时候。

后面我们将构建 tcp 、udp、http的网关。


## [目录](https://fs7744.github.io/nature/)