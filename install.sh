#!/bin/sh
set -eu

repo=https://github.com/grachevvladislav/podkop-subscriptions

fail() { printf 'Ошибка: %s\n' "$*" >&2; exit 1; }

main() {
	[ "$(id -u)" = 0 ] || fail 'Запусти установку от root на OpenWrt.'
	[ -r /etc/openwrt_release ] || fail 'Установщик предназначен для OpenWrt.'
	grep -Eq "^DISTRIB_RELEASE=['\"]?25\.12([.'\"]|$)" /etc/openwrt_release ||
		fail 'Этот выпуск собран для OpenWrt 25.12.'
	grep -Eq "^DISTRIB_ARCH=['\"]?aarch64_cortex-a53(['\"]|$)" /etc/openwrt_release ||
		fail 'Этот выпуск собран для aarch64_cortex-a53 (mediatek/filogic).'
	for tool in apk sha256sum; do
		command -v "$tool" >/dev/null 2>&1 || fail "Не найдена команда $tool."
	done
	apk info -e podkop >/dev/null 2>&1 || fail 'Сначала установи Podkop.'
	sing-box tools decode-link --help >/dev/null 2>&1 ||
		fail 'Нужен движок с командой sing-box tools decode-link, например podkop-engine.'
	if ! command -v curl >/dev/null 2>&1; then
		apk add curl ca-bundle || fail 'Не удалось установить curl для загрузки APK.'
	fi

	umask 077
	tmp=$(mktemp -d /tmp/podkop-subscriptions.XXXXXX)
	trap 'rm -rf "$tmp"' EXIT
	trap 'exit 1' HUP INT TERM
	cd "$tmp"
	for asset in podkop-subscriptions.apk luci-app-podkop-subscriptions.apk SHA256SUMS; do
		curl -q -fLsS --proto '=https' --proto-redir '=https' --connect-timeout 15 \
			--max-time 60 -o "$asset" "$repo/releases/latest/download/$asset" ||
			fail "Не удалось скачать $asset из GitHub Releases."
	done
	sha256sum -c SHA256SUMS || fail 'Контрольная сумма APK не совпала.'
	apk add --allow-untrusted "$tmp/podkop-subscriptions.apk" "$tmp/luci-app-podkop-subscriptions.apk"
	printf '\nУстановлено. Открой Services → Podkop subscriptions в LuCI.\n'
}

main "$@"
