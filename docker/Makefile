SDK_IMAGE ?= openwrt/sdk:mediatek-filogic-25.12.6

.PHONY: build
build:
	docker buildx build -f Dockerfile --build-arg SDK_IMAGE=$(SDK_IMAGE) --output type=local,dest=../bin ..

