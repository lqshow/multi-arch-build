SHELL := /bin/bash

TIME_LONG	= `date +%Y-%m-%d' '%H:%M:%S`
TIME_SHORT	= `date +%H:%M:%S`
TIME		= $(TIME_SHORT)

BLUE         := $(shell printf "\033[34m")
YELLOW       := $(shell printf "\033[33m")
RED          := $(shell printf "\033[31m")
GREEN        := $(shell printf "\033[32m")
CNone        := $(shell printf "\033[0m")

INFO	= echo ${TIME} ${BLUE}[ .. ]${CNone}
WARN	= echo ${TIME} ${YELLOW}[WARN]${CNone}
ERR		= echo ${TIME} ${RED}[FAIL]${CNone}
OK		= echo ${TIME} ${GREEN}[ OK ]${CNone}
FAIL	= (echo ${TIME} ${RED}[FAIL]${CNone} && false)

# Project version
PROJECT_VERSION := tmp-$(shell git describe --abbrev=8 --always --dirty)

ifneq ($(CI_COMMIT_TAG),)
PROJECT_VERSION := $(CI_COMMIT_TAG)
endif

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifneq (,$(shell which go))
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif
endif

# Image URL to use all building/pushing image targets
TARGETARCH 		?= $(shell go env GOARCH)
IMAGE_REGISTRY 	?= ghcr.io/lqshow/multi-arch-build

IMAGE_NAME 		?= app-1
IMAGE 			:= $(IMAGE_REGISTRY)/$(IMAGE_NAME)
IMAGE_TAG 	    := ${IMAGE}:${PROJECT_VERSION}

# Output type of docker buildx build
OUTPUT_TYPE := registry
TARGETARCHS := amd64 arm64
ALL_OS_ARCH := linux-arm64 linux-amd64
GOLANG_VERSION	?= 1.17-buster


# Linux command settings
BLOCKER_TOOLS ?= staticchecktool golines goimports
