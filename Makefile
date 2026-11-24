.PHONY: test sdk-build

test:
	./tests/run.sh

sdk-build:
	$(MAKE) -C docker build

