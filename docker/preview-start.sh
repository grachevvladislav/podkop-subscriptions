#!/bin/sh
set -eu
mkdir -p /var/run/ubus /var/lock
sh /etc/uci-defaults/30_luci-theme-bootstrap
sh /etc/uci-defaults/50_luci-mod-admin-full
printf 'podkop-preview\npodkop-preview\n' | passwd root
ubusd -s /var/run/ubus/ubus.sock &
sleep 1
rpcd &
/usr/sbin/podkop-subscriptions daemon &
exec uhttpd -f -p 0.0.0.0:80 -h /www -x /cgi-bin -u /ubus
