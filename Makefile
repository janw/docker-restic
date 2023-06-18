
VERSION = $(shell cat VERSION)
IMAGE_TAG ?= $(VERSION)-dev
IMAGE_NAME ?= ghcr.io/janw/restic:$(VERSION)-dev

.PHONY: build
build:
	docker build --build-arg=VERSION_RESTIC=$(VERSION) -t $(IMAGE_NAME) .

.PHONY: version
version:
	@echo $(VERSION)


TEST_DATA = $(CURDIR)/tests/data
TEST_TARGET = $(CURDIR)/tests/repo
TEST_PASSWORD = very-complicated-password
TEST_HEALTHCHECK = https://hc-ping.com/e67ac092-6bc2-417e-b785-3751f7bee4eb

.PHONY: test-init
test-init:
	mkdir -p $(TEST_TARGET)
	mkdir -p $(TEST_DATA)
	docker run --rm \
	-v $(TEST_TARGET):/target \
	-e RESTIC_PASSWORD=$(TEST_PASSWORD) \
	--entrypoint restic \
	$(IMAGE_NAME) \
	init

.PHONY: test
test:
	touch $(TEST_DATA)/$$RANDOM.txt
	docker run --rm \
	-v $(TEST_DATA):/data \
	-v $(TEST_TARGET):/target \
	-e HEALTHCHECK_URL=$(TEST_HEALTHCHECK) \
	-e RESTIC_PASSWORD=$(TEST_PASSWORD) \
	$(IMAGE_NAME)

.PHONY: clean
clean:
	rm -rf $(CURDIR)/tests
