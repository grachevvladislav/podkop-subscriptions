.PHONY: test test-openwrt sdk-build

test:
	./tests/run.sh

test-openwrt:
	docker build -f docker/preview.Dockerfile -t podkop-luci-preview .
	@set -eu; for test in openwrt-smoke overlap; do \
	  docker run --rm -v "$(CURDIR)/tests/$$test.sh:/test.sh:ro" podkop-luci-preview sh /test.sh; \
	done

sdk-build:
	$(MAKE) -C docker build

