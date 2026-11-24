#!/bin/sh
# Runs in an isolated podkop-luci-preview container with podkop-engine installed.
set -eu

if [ "${0##*/}" = curl ]; then
	while [ "$#" -gt 0 ]; do
		case "$1" in
			https://fixture.invalid/*) source=${1##*/} ;;
			-o) shift; output=$1 ;;
		esac
		shift
	done
	base=vless://11111111-1111-4111-8111-111111111111@fixture.invalid:443
	case "$source" in
		first) printf '%s\n' "$base?type=tcp&security=tls#First%20Berlin" >"$output" ;;
		second)
			printf '%s\n' "$base?security=tls&type=tcp#Second%20Berlin" \
				'vless://22222222-2222-4222-8222-222222222222@fixture.invalid:443?type=tcp&security=tls#Second%20Berlin' >"$output"
			;;
		*) exit 28 ;;
	esac
	exit
fi

mkdir /tmp/subscription-fixtures
ln -s "$0" /tmp/subscription-fixtures/curl
export PATH="/tmp/subscription-fixtures:$PATH"
for source in first second; do
	uci set "podkop-subscriptions.$source=source"
	uci set "podkop-subscriptions.$source.url=https://fixture.invalid/$source"
	uci set "podkop-subscriptions.$source.schedule=manual"
done
uci commit podkop-subscriptions
updater=/usr/libexec/podkop-subscriptions/update
count_links() { uci export podkop | grep -c 'list urltest_proxy_links'; }

"$updater" scheduled
[ "$(count_links)" = 2 ]
podkop-subscriptions status | grep -Eq '\|applied\|2\|0\|0\|1$'

uci set 'podkop-subscriptions.first.exclude_regex=^first'
uci commit podkop-subscriptions
"$updater" scheduled
[ "$(count_links)" = 2 ]
status=$(podkop-subscriptions status)
printf '%s\n' "$status" | grep -Eq '\|unchanged\|2\|0\|1\|0$' || { printf '%s\n' "$status" >&2; exit 1; }

# A Podkop regeneration can replace the runtime group without changing the
# subscriptions. A manual refresh must still repair that drift.
uci delete podkop.main.urltest_proxy_links
uci commit podkop
"$updater" update
[ "$(count_links)" = 2 ]
podkop-subscriptions status | grep -Eq '\|applied\|2\|0\|1\|0$'

uci set podkop-subscriptions.second.enabled=0
uci delete podkop-subscriptions.first.exclude_regex
uci commit podkop-subscriptions
"$updater" scheduled
[ "$(count_links)" = 1 ]

uci set podkop-subscriptions.first.enabled=0
uci commit podkop-subscriptions
"$updater" scheduled
[ "$(count_links)" = 1 ]
echo 'Overlapping sources, source-local filters, distinct credentials and disabling sources passed'
