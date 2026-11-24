SDK_IMAGE ?= openwrt/sdk:mediatek-filogic-25.12.6

.PHONY: build
build:
	docker build -f Dockerfile --build-arg SDK_IMAGE=$(SDK_IMAGE) -t podkop-subscriptions-sdk ..
	docker run --rm podkop-subscriptions-sdk

