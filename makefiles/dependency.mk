##@ Build Dependencies

TOOLS ?=$(BLOCKER_TOOLS)

.PHONY: dependency.install
dependency.install: $(addprefix dependency.install., $(TOOLS))

.PHONY: dependency.install.%
dependency.install.%:
	@$(INFO) "Installing $*"
	@$(MAKE) install.$*

.PHONY: dependency.verify.%
dependency.verify.%:
	@if ! which $* &>/dev/null; then $(MAKE) dependency.install.$*; fi

## Location to install dependencies to
LOCALBIN ?= /usr/local/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Binaries

.PHONY: install.staticchecktool
install.staticchecktool:
ifeq (, $(shell which staticcheck))
	@{ \
	set -e ;\
	echo 'installing honnef.co/go/tools/cmd/staticcheck ' ;\
	GO111MODULE=on go get honnef.co/go/tools/cmd/staticcheck@v0.3.0 ;\
	}
STATICCHECK=$(GOBIN)/staticcheck
else
STATICCHECK=$(shell which staticcheck)
endif

.PHONY: install.goimports
install.goimports: ## Download goimports locally if necessary.
ifeq (, $(shell which goimports))
	@{ \
	set -e ;\
	go install golang.org/x/tools/cmd/goimports@latest ;\
	}
GOIMPORTS=$(GOBIN)/goimports
else
GOIMPORTS=$(shell which goimports)
endif

.PHONY: install.golines
install.golines:
ifeq (, $(shell which golines))
	@{ \
	set -e ;\
	go install github.com/segmentio/golines@v0.9.0 ;\
	}
GOLINES=$(GOBIN)/golines
else
GOLINES=$(shell which golines)
endif