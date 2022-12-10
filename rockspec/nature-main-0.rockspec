package = "nature"
version = "main-0"

source = {
    url = "git+ssh://git@github.com:fs7744/nature.git",
    branch = "main",
}

description = {
    summary = "nature is api gateway, just show you for how to bulid api gateway",
    homepage = "https://github.com/fs7744/nature",
    maintainer = "Victor.X.Qu"
}

dependencies = {
    "jsonschema >= 0.9.9",
    "lua-resty-ngxvar >= 0.5.2",
    "lua-resty-cookie >= 0.1.0",
    "lua-resty-radixtree >= 2.8.2",
    "lua-tinyyaml >= 1.0",
    "lua-resty-etcd >= 1.9.0",
    "lua-resty-mlcache >= 2.6.0",
    "lua-resty-balancer >= 0.04",
    "lua-resty-openssl >= 0.8.15",
    "lua-resty-healthcheck >= 2.0.0",
    "lua-resty-dns-client >= 6.0.2",
    "binaryheap >= 0.4",
    "lua-resty-jwt >= 0.2.3",
    "nginx-lua-prometheus >= 0.20220527",
    "lua-resty-redis-connector >= 0.11.0",
    "lua-resty-ctxdump = 0.1-0",
    "lua-resty-template >= 2.0-1",
    "lua-resty-env >= 0.4.0-1",
    "resty-redis-cluster >= 1.05-1",
    "luasocket >= 3.1.0-1",
}

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