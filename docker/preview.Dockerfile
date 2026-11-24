FROM openwrt/rootfs:armsr-armv8-25.12.6
RUN apk update && apk add luci-light uhttpd-mod-ubus curl jq ca-bundle flock
RUN set -eu; \
    for pkg in podkop luci-app-podkop; do \
      curl -fsSL "https://github.com/itdoginfo/podkop/releases/download/0.7.24/$pkg-0.7.24-r1.apk" -o "/tmp/$pkg.apk"; \
    done; \
    curl -fsSL https://github.com/podkop-net/podkop-engine/releases/download/v1.14.4-r28/podkop-engine_1.14.4-r28_openwrt_aarch64_generic.apk -o /tmp/podkop-engine.apk; \
    apk add --allow-untrusted /tmp/podkop.apk /tmp/luci-app-podkop.apk /tmp/podkop-engine.apk; \
    rm /tmp/podkop.apk /tmp/luci-app-podkop.apk /tmp/podkop-engine.apk
COPY package/luci-app-podkop-subscriptions/files/ /
COPY package/podkop-subscriptions/files/ /
COPY docker/preview-start.sh /preview-start.sh
COPY docker/preview-system.sh /usr/libexec/rpcd/system
COPY docker/preview-sing-box.sh /etc/init.d/sing-box
COPY docker/preview-sing-box.json /etc/sing-box/config.json
RUN chmod 755 /usr/libexec/rpcd/system /etc/init.d/sing-box && \
    uci set podkop.main.proxy_config_type=urltest && uci commit podkop
EXPOSE 80
CMD ["/bin/sh", "/preview-start.sh"]
