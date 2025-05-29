#!/usr/bin/env sh

set -e

curdir=$(cd "$(dirname "$0")" && pwd)

cd "$curdir"

./autogen.sh

CFLAGS="-O3" WEBDIR=/var/www ./configure --prefix=/usr

make

strip src/thttpd
