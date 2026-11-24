#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CORE="$ROOT/package/podkop-subscriptions/files/usr/libexec/podkop-subscriptions/update"
CLI="$ROOT/package/podkop-subscriptions/files/usr/sbin/podkop-subscriptions"
UI="$ROOT/package/luci-app-podkop-subscriptions/files/www/luci-static/resources/view/podkop-subscriptions/overview.js"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok: %s\n' "$*"; }

for script in "$CORE" "$CLI" "$ROOT/install.sh" "$ROOT"/tests/*.sh "$ROOT"/docker/*.sh \
	"$ROOT/package/podkop-subscriptions/files/etc/init.d/podkop-subscriptions"; do
	sh -n "$script" || fail "shell syntax: $script"
done
pass 'shell syntax'

if ! command -v node >/dev/null 2>&1 || ! node --check "$UI" >/dev/null; then
	fail 'LuCI JavaScript syntax'
fi
pass 'LuCI JavaScript syntax'

share="$ROOT/package/luci-app-podkop-subscriptions/files/usr/share"
for config in "$share"/luci/menu.d/*.json "$share"/rpcd/acl.d/*.json "$ROOT"/docker/*.json; do
	node -e 'JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"))' "$config" ||
		fail "JSON syntax: $config"
done
pass 'JSON syntax'

for package in podkop-subscriptions luci-app-podkop-subscriptions; do
	[ -f "$ROOT/package/$package/Makefile" ] || fail "missing $package Makefile"
done
pass 'package manifests'

