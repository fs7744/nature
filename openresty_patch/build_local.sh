#!/usr/bin/env bash

or_ver="1.21.4.1"

tempdir=$(mktemp -d)
echo "do at ${tempdir}"
cp -R ./ ${tempdir}
cd ${tempdir}
cp ./patch/${or_ver}/Dockerfile ./
wget --no-check-certificate https://openresty.org/download/openresty-${or_ver}.tar.gz
tar -zxvpf openresty-${or_ver}.tar.gz > /dev/null
sh build.sh $or_ver