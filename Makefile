include makefiles/const.mk
include makefiles/dependency.mk

# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.DEFAULT_GOAL := all
all: tidy build

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_.0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: version
version: ## Display multi arch demo driver version.
	@echo $(PROJECT_VERSION)

.PHONY: tidy
tidy:
	@go mod tidy

.PHONY: build
build: ## Build multi arch demo binary
	hack/gobuild/gobuild.sh cmd/app
	@$(OK) build multi arch app binary succeed

.PHONY: docker-build
docker-build: ## Build docker image.
	docker buildx build \
		--output=type=$(OUTPUT_TYPE) \
		--platform linux/$(TARGETARCH) \
		--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
		--build-arg TARGETARCH=$(TARGETARCH) \
		-t $(IMAGE_TAG)-linux-$(TARGETARCH) \
		-f Dockerfile .
	@$(OK)

.PHONY: docker-push
docker-push: ## Push docker image.
	docker manifest create --amend $(IMAGE_TAG) $(foreach osarch, $(ALL_OS_ARCH), $(IMAGE_TAG)-${osarch})
	docker manifest push --purge $(IMAGE_TAG)
	docker manifest inspect $(IMAGE_TAG)

.PHONY: builder-instance
builder-instance:
	docker buildx rm multi-arch-builder || true
	docker buildx create --use --name=multi-arch-builder

.PHONY: multi-arch-builder
multi-arch-builder: builder-instance ## Build multi-arch docker image.
	for arch in $(TARGETARCHS); do \
		TARGETARCH=$${arch} $(MAKE) docker-build; \
	done

.PHONY: build.clean
build.clean:
	@rm -rf bin
	@$(OK) clean succeed

.PHONY: clean
clean: build.clean
