#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CORE="$ROOT/package/podkop-subscriptions/files/usr/libexec/podkop-subscriptions/update"
CLI="$ROOT/package/podkop-subscriptions/files/usr/sbin/podkop-subscriptions"
UI="$ROOT/package/luci-app-podkop-subscriptions/files/www/luci-static/resources/view/podkop-subscriptions/overview.js"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok: %s\n' "$*"; }

sh -n "$CORE" || fail 'updater shell syntax'
sh -n "$CLI" || fail 'CLI shell syntax'
pass 'shell syntax'

if ! command -v node >/dev/null 2>&1 || ! node --check "$UI" >/dev/null; then
	fail 'LuCI JavaScript syntax'
fi
pass 'LuCI JavaScript syntax'

grep -q 'decode-link --compact' "$CORE" || fail 'all-protocol sing-box decoder is missing'
grep -q 'Filters left no usable links' "$CORE" || fail 'empty-result protection is missing'
grep -q "skipped=\$skipped" "$CORE" || fail 'invalid-link reporting is missing'
grep -q 'cmp -s.*fingerprint' "$CORE" || fail 'semantic change detection is missing'
! grep -q 'get_list' "$CORE" || fail 'unsupported UCI get_list usage'
pass 'core safety invariants'

grep -q '15m' "$UI" || fail '15-minute schedule missing from UI'
grep -q 'exclude_country' "$UI" || fail 'country filtering missing from UI'
grep -q 'Update now' "$UI" || fail 'manual update missing from UI'
pass 'UI feature invariants'

for package in podkop-subscriptions luci-app-podkop-subscriptions; do
	[ -f "$ROOT/package/$package/Makefile" ] || fail "missing $package Makefile"
done
pass 'package manifests'

