#!/bin/sh
case "$1" in
	list) echo '{"board":{}}' ;;
	call) [ "$2" = board ] && echo '{"hostname":"Podkop Preview","release":{"description":"OpenWrt 25.12.6"}}' ;;
esac
