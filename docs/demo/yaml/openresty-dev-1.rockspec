package = "openresty"
version = "dev-1"

-- 自己编写第三方库时，如果希望别人远端仓库下载当前源码编译可以配置 source ，比如下git的配置
source = {
   url = "git+ssh://git@github.com:fs7744/nature.git",
   branch = "main",
}
-- 包描述
description = {
   homepage = "https://github.com/fs7744/nature",
   maintainer = "Victor.X.Qu"
}

-- 依赖包
dependencies = {
    "lua-tinyyaml >= 1.0",
}

-- 当前包如何编译，这里列举openresty常遇见的一些参数
build = {
    type = "make",
    build_variables = {
        CFLAGS="$(CFLAGS)",
        LIBFLAG="$(LIBFLAG)",
        LUA_LIBDIR="$(LUA_LIBDIR)",
        LUA_BINDIR="$(LUA_BINDIR)",
        LUA_INCDIR="$(LUA_INCDIR)",
        LUA="$(LUA)",
        OPENSSL_INCDIR="$(OPENSSL_INCDIR)",
        OPENSSL_LIBDIR="$(OPENSSL_LIBDIR)",
    },
    install_variables = {
        INST_PREFIX="$(PREFIX)",
        INST_BINDIR="$(BINDIR)",
        INST_LIBDIR="$(LIBDIR)",
        INST_LUADIR="$(LUADIR)",
        INST_CONFDIR="$(CONFDIR)",
    },
}