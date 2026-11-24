ARG SDK_IMAGE=openwrt/sdk:mediatek-filogic-25.12.6
FROM ${SDK_IMAGE} AS sdk

USER root
WORKDIR /builder

RUN [ -d ./scripts ] || ./setup.sh
COPY package /builder/package/podkop-subscriptions-local
RUN make defconfig
# These packages only install scripts and assets. Runtime dependencies remain
# in the package metadata and are installed on OpenWrt.
RUN make -C package/podkop-subscriptions-local/podkop-subscriptions TOPDIR=/builder CONFIG_PACKAGE_podkop-subscriptions=m compile V=s && \
    make -C package/podkop-subscriptions-local/luci-app-podkop-subscriptions TOPDIR=/builder CONFIG_PACKAGE_luci-app-podkop-subscriptions=m compile V=s && \
    find bin -name '*podkop-subscriptions*.apk' | tee /tmp/subscription-packages && \
    test "$(wc -l </tmp/subscription-packages)" -eq 2
FROM scratch AS packages
COPY --from=sdk /builder/bin/packages/*/base/*podkop-subscriptions*.apk /

