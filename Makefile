.PHONY: setup watch test

setup:
	./tool/bootstrap.sh

watch:
	./tool/watch.sh

test:
	./tool/test.sh
