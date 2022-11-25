package t::nature;

use Cwd qw(cwd);
use Test::Nginx::Socket::Lua::Stream -Base;
use Test::Nginx::Socket::Lua::Stream;

repeat_each(1);
log_level('info');
no_long_string();
no_shuffle();
no_root_location(); # avoid generated duplicate 'location /'
worker_connections(128);
master_on();

my $prefix = cwd();

add_block_preprocessor(sub {
    my ($block) = @_;

    my $http_config = $block->http_config // '';
    $http_config .= <<EOF;
    lua_package_path  "$prefix/t/?.lua;$prefix/deps/share/lua/5.1/?.lua;$prefix/deps/share/lua/5.1/?/init.lua;$prefix/?.lua;$prefix/?/init.lua;;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua;";
    lua_package_cpath "$prefix/deps/lib64/lua/5.1/?.so;$prefix/deps/lib/lua/5.1/?.so;;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;";
    
    lua_shared_dict lrucache_lock        10m;
EOF
    $block->set_value("http_config", $http_config);

    my $stream_config = $block->stream_config // '';
    my $stream_server_config = $block->stream_server_config;
    if($stream_server_config) {
        $stream_config .= <<EOF;
    lua_package_path  "$prefix/t/?.lua;$prefix/deps/share/lua/5.1/?.lua;$prefix/deps/share/lua/5.1/?/init.lua;$prefix/?.lua;$prefix/?/init.lua;;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua;";
    lua_package_cpath "$prefix/deps/lib64/lua/5.1/?.so;$prefix/deps/lib/lua/5.1/?.so;;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;";

    lua_shared_dict stream_lrucache_lock        10m;
EOF
        $block->set_value("stream_config", $stream_config);
    }
    $block;
});

