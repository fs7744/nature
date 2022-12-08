#!/usr/bin/env bash


# prev_workdir="$PWD"
# repo=$(basename "$prev_workdir")
# workdir=$(mktemp -d)
# cd "$workdir" || exit 1
# echo $workdir

or_ver="$1"

./patch.sh ${PWD}/openresty-${or_ver}

cc_opt=${cc_opt:-}
ld_opt=${ld_opt:-}
luajit_xcflags=${luajit_xcflags:="-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT"}
OR_PREFIX=${OR_PREFIX:="/usr/local/openresty"}
debug_args=${debug_args:-}

git clone https://github.com/Kong/lua-resty-events.git resty-events

cd openresty-${or_ver} || exit 1
./configure --prefix="$OR_PREFIX" \
    $debug_args \
    --add-module=../resty-events \
    --with-poll_module \
    --with-pcre-jit \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-lua_rds_parser \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_stub_status_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_random_index_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-threads \
    --with-compat \
    --with-luajit-xcflags="$luajit_xcflags" \
    -j`nproc`

make -j`nproc`
make install DESTDIR="$2"
OPENRESTY_PREFIX="$2$OR_PREFIX"
cd ..

cd resty-events || exit 1
DESTDIR="$OPENRESTY_PREFIX" LUA_LIB_DIR="lualib" make install
cd ..