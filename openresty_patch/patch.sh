#!/usr/bin/env bash
set -euo pipefail

err() {
    >&2 echo "$@"
}

usage() {
    err "usage: $1 ThePathOfYourOpenRestySrcDirectory"
    exit 1
}

failed_to_cd() {
    err "failed to cd $1"
    exit 1
}

apply_patch() {
    patch_dir="$1"
    root="$2"
    repo="$3"
    ver="$4"

    dir="$root/bundle/$repo-$ver"
    pushd "$dir" || failed_to_cd "$dir"
    for patch in "$patch_dir/$repo"-*.patch; do
        echo "Start to patch $patch to $dir..."
        patch -p0 --verbose < "$patch"
        #git apply -v "$patch"
    done
    popd
}

if [[ $# != 1 ]]; then
    usage "$0"
fi

root="$1"
if [[ "$root" == *openresty-1.21.4.* ]]; then
      patch_dir="$PWD/patch/1.21.4.1"
      apply_patch "$patch_dir" "$root" "lua-resty-core" "0.1.23"
      apply_patch "$patch_dir" "$root" "ngx_lua" "0.10.21"
      apply_patch "$patch_dir" "$root" "nginx" "1.21.4"
      apply_patch "$patch_dir" "$root" "LuaJIT" "2.1-20220411"
      apply_patch "$patch_dir" "$root" "lua-cjson" "2.1.0.10"
else
    err "can't detect OpenResty version"
    exit 1
fi