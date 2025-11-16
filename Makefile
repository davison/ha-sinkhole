# Get all subdirs with a Containerfile or Dockerfile
# This finds 'dns-node/Containerfile', etc.
IMAGE_DIRS := $(wildcard */Containerfile */Dockerfile)

# This strips off the '/Containerfile' part to get just the dir names
# Result: 'dns-node', 'vip-manager', 'blocklist-updater'
#IMAGE_NAMES := $(patsubst %/Containerfile,%,$(patsubst %/Dockerfile,%,$(IMAGE_DIRS)))

# --- Configurable Variables ---
TAG_PREFIX ?= $(shell basename `pwd`)
TAG_VERSION ?= local
# Get the container command (podman or docker)
CONTAINER_CMD ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)

DANGLING ?= $(shell $(CONTAINER_CMD) images --filter "dangling=true" -q --no-trunc)

# --- Main Targets ---

# 'make all' or just 'make' will build all images it finds
.SILENT:
all: $(foreach img,$(IMAGE_DIRS),build-$(patsubst %/Containerfile,%,$(patsubst %/Dockerfile,%,$(img))))

# Generic pattern rule to build an image
# e.g., 'make build-dns-node'
.SILENT:
build-%:
	@echo ">> Building $(TAG_PREFIX)/$*:$(TAG_VERSION)"
	@$(CONTAINER_CMD) build --build-arg BUILD_VERSION=0.0.0 -t "$(TAG_PREFIX)/$*":$(TAG_VERSION) "$*" $(NO_CACHE) > /dev/null

# 'make no-cache' will re-build all images with --no-cache
.SILENT:
no-cache:
	@$(MAKE) all NO_CACHE=--no-cache

.SILENT:
clean:
	@echo ">> Cleaning built images"
	$(foreach img,$(IMAGE_DIRS),del-$(patsubst %/Containerfile,%,$(patsubst %/Dockerfile,%,$(img))))
	@echo ">> Cleaning dangling images"
	@$(CONTAINER_CMD) rmi $(DANGLING) > /dev/null 2>&1

.SILENT:
del-%:
	@echo ">> Deleting image $(TAG_PREFIX)/$*:$(TAG_VERSION)"
	@$(CONTAINER_CMD) rmi "$(TAG_PREFIX)/$*":$(TAG_VERSION) > /dev/null

# Tell make these aren't actual files
.SILENT:
.PHONY: all no-cache $(foreach img,$(IMAGE_NAMES),build-$(patsubst %/Containerfile,%,$(patsubst %/Dockerfile,%,$(img)))) $(foreach img,$(IMAGE_NAMES),del-$(patsubst %/Containerfile,%,$(patsubst %/Dockerfile,%,$(img))))
