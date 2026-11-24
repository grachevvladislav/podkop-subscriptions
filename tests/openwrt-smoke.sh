#!/bin/sh
# Run in a disposable preview container.
set -eu
lock=/tmp/podkop-subscriptions.lock
mkdir "$lock"
exec 8>/tmp/podkop-subscriptions.guard
flock -n 8
podkop-subscriptions status >/dev/null
rc=0
podkop-subscriptions update || rc=$?
[ "$rc" = 75 ]
[ -d "$lock" ]
flock -u 8
exec 8>&-
rmdir "$lock"

uci set podkop-subscriptions.fixture=source
uci set podkop-subscriptions.fixture.schedule=manual
uci set podkop-subscriptions.fixture.url=https://example.invalid/fixture
uci commit podkop-subscriptions
# A manual source is still fetched once when first saved.
mkdir -p /etc/podkop-subscriptions
printf '%s' https://example.invalid/fixture | sha256sum >/etc/podkop-subscriptions/source-fixture.attempt-url
uci export podkop-subscriptions | sha256sum >/etc/podkop-subscriptions/settings-attempt
/usr/libexec/podkop-subscriptions/update scheduled
[ ! -d "$lock" ]
[ ! -e /etc/podkop-subscriptions/status ]

uci set podkop-subscriptions.fixture.url=http://example.invalid/fixture
uci commit podkop-subscriptions
if podkop-subscriptions update; then exit 1; fi
podkop-subscriptions status | grep -q 'not an HTTPS URL'
[ ! -d "$lock" ]
echo 'OpenWrt update lock, manual schedule and URL validation passed'
