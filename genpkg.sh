#!/usr/bin/env sh

set -e

curdir=$(cd "$(dirname "$0")" && pwd)

dst_bindir=/usr/sbin
dst_cfgdir=/etc
dst_srvdir=/lib/systemd/system

temp_pkgdir=/tmp/thttpd
temp_cfgdir=$temp_pkgdir/$dst_cfgdir
temp_srvdir=$temp_pkgdir/$dst_srvdir
temp_debian_dir=$temp_pkgdir/DEBIAN

test -d "$temp_pkgdir" && rm -fr "$temp_pkgdir"

mkdir -p "$temp_cfgdir"
mkdir -p "$temp_srvdir"
mkdir -p "$temp_debian_dir"

cd "$curdir"
DESTDIR="$temp_pkgdir" make install

cd "$curdir/docs"
DESTDIR="$temp_pkgdir" make install

# -- gen config file -----------------------------------------------------------

echo "Generating $temp_cfgdir/thttpd.conf"

cat > "$temp_cfgdir/thttpd.conf" << EOF
dir=/var/www
logfile=/var/log/thttpd.log
charset=UTF-8
EOF

# -- gen service unit file -----------------------------------------------------

echo "Generating $temp_srvdir/thttpd.service"

cat > "$temp_srvdir/thttpd.service" << EOF
[Unit]
Description=shttpd - A fork of Jef Poskanzer's popular thttpd.
After=network.target

[Service]
Type=forking
Restart=always
RestartSec=20
ExecStart="$dst_bindir/thttpd" -C "$dst_cfgdir/thttpd.conf"

[Install]
WantedBy=multi-user.target
EOF

# -- gen control file ----------------------------------------------------------

pkgname=thttpd
version=2.27.1
arch=amd64

cat > "$temp_debian_dir/control" << EOF
Package: $pkgname
Version: $version
License: Proprietary
Section: net
Priority: optional
Architecture: $arch
Maintainer: Jef Poskanzer
Description: sthttpd - a fork of thttpd, a tiny/turbo/throttling HTTP server
EOF

# -- gen postinst script -------------------------------------------------------

cat > "$temp_debian_dir/postinst" << EOF
#!/usr/bin/env sh

systemctl daemon-reload
systemctl enable --now thttpd
EOF

chmod 755 "$temp_debian_dir/postinst"

# -- gen prerm script ----------------------------------------------------------

cat > "$temp_debian_dir/prerm" << EOF
#!/usr/bin/env sh

systemctl disable --now thttpd
systemctl daemon-reload
EOF

chmod 755 "$temp_debian_dir/prerm"

# -- build package -------------------------------------------------------------

dpkg-deb --build "$temp_pkgdir" "$curdir"

# -- cleanup -------------------------------------------------------------------

rm -fr "$temp_pkgdir"
