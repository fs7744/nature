# Lua 面向对象编程

## 类

在 Lua 中，我们可以使用表和函数实现面向对象。将函数和相关的数据放置于同一个表中就形成了一个对象。

请看文件名为 `account.lua` 的源码：

```Lua
local _M = {}

local mt = { __index = _M }

function _M.deposit (self, v)
	self.balance = self.balance + v
end

function _M.withdraw (self, v)
	if self.balance > v then
		self.balance = self.balance - v
	else
		error("insufficient funds")
	end
end

function _M.new (self, balance)
	balance = balance or 0
	return setmetatable({balance = balance}, mt)
end

return _M
```

> 引用代码示例：

```
local account = require("account")

local a = account:new()
a:deposit(100)

local b = account:new()
b:deposit(50)

print(a.balance)  --> output: 100
print(b.balance)  --> output: 50
```

上面这段代码 "setmetatable({balance = balance}, mt)"，其中 mt 代表 `{ __index = _M }` ，这句话值得注意。根据我们在元表这一章学到的知识，我们明白，setmetatable 将 `_M` 作为新建表的原型，所以在自己的表内找不到 'deposit'、'withdraw' 这些方法和变量的时候，便会到 \_\_index 所指定的 _M 类型中去寻找。

## 继承

继承可以用元表实现，它提供了在父类中查找存在的方法和变量的机制。在 Lua 中是不推荐使用继承方式完成构造的，这样做引入的问题可能比解决的问题要多，下面一个是字符串操作类库，给大家演示一下。

```lua
---------- s_base.lua
local _M = {}

local mt = { __index = _M }

function _M.upper (s)
	return string.upper(s)
end

return _M

---------- s_more.lua
local s_base = require("s_base")

local _M = {}
_M = setmetatable(_M, { __index = s_base })


function _M.lower (s)
    return string.lower(s)
end

return _M

---------- test.lua
local s_more = require("s_more")

print(s_more.upper("Hello"))   -- output: HELLO
print(s_more.lower("Hello"))   -- output: hello
```



## 成员私有性

在动态语言中引入成员私有性并没有太大的必要，反而会显著增加运行时的开销，毕竟这种检查无法像许多静态语言那样在编译期完成。下面的技巧把对象作为各方法的 upvalue，本身是很巧妙的，但会让子类继承变得困难，同时构造函数动态创建了函数，会导致构造函数无法被 JIT 编译。

在 Lua 中，成员的私有性，使用类似于函数闭包的形式来实现。在我们之前的银行账户的例子中，我们使用一个工厂方法来创建新的账户实例，通过工厂方法对外提供的闭包来暴露对外接口。而不想暴露在外的例如 balance 成员变量，则被很好的隐藏起来。

```Lua
function newAccount (initialBalance)
	local self = {balance = initialBalance}
	local withdraw = function (v)
		self.balance = self.balance - v
	end
	local deposit = function (v)
		self.balance = self.balance + v
	end
	local getBalance = function () return self.balance end
	return {
		withdraw = withdraw,
		deposit = deposit,
		getBalance = getBalance
	}
end

a = newAccount(100)
a.deposit(100)
print(a.getBalance()) --> 200
print(a.balance)      --> nil
```


## [lua 语言目录](https://fs7744.github.io/nature/prepare/lua/index.html)
## [总目录](https://fs7744.github.io/nature/)


