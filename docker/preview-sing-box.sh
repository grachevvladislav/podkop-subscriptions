#!/bin/sh
set -eu
case "${1:-}" in
	restart)
		if [ -r /tmp/preview-sing-box.pid ]; then
			kill "$(cat /tmp/preview-sing-box.pid)" 2>/dev/null || true
		fi
		(
			trap '' HUP
			exec /usr/bin/sing-box run -c /etc/sing-box/config.json
		) >/tmp/preview-sing-box.log 2>&1 </dev/null &
		echo "$!" >/tmp/preview-sing-box.pid
		;;
	*) exit 2 ;;
esac
