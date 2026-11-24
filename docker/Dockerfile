ARG SDK_IMAGE
FROM ${SDK_IMAGE}

USER root
WORKDIR /builder
COPY package /builder/package/podkop-subscriptions-local

# Package feeds vary between SDK releases. The build fails loudly if the target
# image lacks Podkop, which is preferable to producing an unusable package.
RUN [ -d ./scripts ] || ./setup.sh
RUN ./scripts/feeds update -a && ./scripts/feeds install -a || true
RUN make defconfig
RUN make package/podkop-subscriptions-local/podkop-subscriptions/compile V=s
RUN make package/podkop-subscriptions-local/luci-app-podkop-subscriptions/compile V=s

