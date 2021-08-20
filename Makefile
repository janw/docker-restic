
VERSION = $(shell cat VERSION)
DOCKER_TAG = ghcr.io/janw/restic

.PHONY: version
version:
	@echo $(VERSION)

.PHONY: build
build:
	docker build --build-arg=VERSION_RESTIC=$(VERSION) -t $(DOCKER_TAG) .
