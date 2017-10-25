ZIP=zip --quiet -x Makefile -9 -r
CURL=curl
MAKE=make
TOOL_CLI=node tools/cli.js
LANG=C

NAME=tubi
REMOTE_LOAD_NAME=tubi_remote_components
SRC_DIR=src/channel
BUILD_DIR=build
BUILD_HOTPATCH_DIR=build/hotpatch
TARGET_DIR=$(BUILD_DIR)/local
TARGET_REMOTE_DIR=$(BUILD_DIR)/remote
TARGET_HOTPATCH_DIR=$(BUILD_DIR)/hotpatch
REMOTE_LOAD_PORT=8090
REMOTE_LOAD_IMAGE_WHITELIST=
REMOTE_LOAD_RSYNC_INCLUDE=--include 'source' \
  --include 'source/lib' \
  --include 'source/lib/**' \
  --include 'source/3rdparty' \
  --include 'source/3rdparty/**' \
  --include 'components' \
  --include 'components/**' \
  --include-from=new_images_since_2_3_1 \
  --exclude '*'
DEV_PORT=8085
DEV_PASSWORD?=1234
PKG_PASSWORD?=ABCD
ROKU_PROFILE?=dev
SETTING_FILE=source/Settings.brs
MANIFEST_FILE=manifest
ORIGINAL_MANIFEST_NAME=manifest
REMOTE_LOAD_NAME_MANIFEST_NAME=component_library_manifest
TESTS=source/tests
S3_STAGING_ADDR=s3://adrise-bryan-playground/roku-staging
S3_COMPONENTS_DIR=components

ifeq ($(ROKU_PROFILE), production)
RSYNC_EXCLUDE=--exclude source/tests --exclude '.keep'
else
RSYNC_EXCLUDE=--exclude '.keep'
endif

build: clean rsync gen zip
	@echo "Project $(VERSIONED_TARGET) is built with profile $(ROKU_PROFILE)."

zip:
	@$(TOOL_CLI) zip-files $(TARGET_DIR)
	@$(TOOL_CLI) zip-files $(TARGET_REMOTE_DIR)

rsync:
	@mkdir -p ./$(TARGET_DIR)
	@mkdir -p ./$(TARGET_REMOTE_DIR)
	@mkdir -p ./$(TARGET_HOTPATCH_DIR)
	@rm -rf ./$(TARGET_DIR)/$(TESTS)
	@rm -f ./$(TARGET_DIR)/$(SETTING_FILE)
	@rsync -arvq $(RSYNC_EXCLUDE) $(SRC_DIR)/* $(TARGET_DIR)
	@rsync -arvq $(REMOTE_LOAD_RSYNC_INCLUDE) $(SRC_DIR)/* $(TARGET_REMOTE_DIR)

	# Swap script references from pkg:/ to libpkg:/
	@find ./$(TARGET_REMOTE_DIR)/components -name '*.xml' | xargs sed -i '' 's|<script type="text/brightscript" uri="pkg:|<script type="text/brightscript" uri="libpkg:|'

	# Swap only whitelisted image references from pkg:/ to libpkg:/
	@for path in `egrep "(png|jpg)" new_images_since_2_3_1`; do \
    echo "Redirecting whitelisted image $$path"; \
    find ./$(TARGET_REMOTE_DIR)/components -type file | xargs sed -E -i '' "s|pkg:/+$$path|libpkg:/$$path|"; \
  done

	# Remove $$RES$$ autosub since it doesn't work for remote components
	@find ./$(TARGET_REMOTE_DIR)/components -name '*.xml' | xargs sed -i '' 's|\$$\$$RES\$$\$$|fhd|'

gen:
	@$(TOOL_CLI) create-config $(ROKU_PROFILE) $(TARGET_DIR)/$(SETTING_FILE)
	@$(TOOL_CLI) create-manifest $(ROKU_PROFILE) $(TARGET_DIR)/$(MANIFEST_FILE) $(ORIGINAL_MANIFEST_NAME)
	@$(TOOL_CLI) create-manifest $(ROKU_PROFILE) $(TARGET_REMOTE_DIR)/$(MANIFEST_FILE) $(REMOTE_LOAD_NAME_MANIFEST_NAME)
	@$(TOOL_CLI) create-hotpatch $(ROKU_PROFILE) 
	@touch $(TARGET_REMOTE_DIR)/source/main.brs

stage: set-build
  ifeq ($(ROKU_PROFILE), staging)
		@echo "Uploading components and hotpatches to s3 staging."
		@aws s3 cp $(BUILD_DIR)/$(VERSIONED_REMOTE_LOAD_PKG) $(S3_STAGING_ADDR)/$(S3_COMPONENTS_DIR)/$(VERSIONED_REMOTE_LOAD_PKG)
		@aws s3 cp $(BUILD_HOTPATCH_DIR)/$(VERSIONED_OLDUI_HOTPATCH) $(S3_STAGING_ADDR)/$(VERSIONED_OLDUI_HOTPATCH)
		@aws s3 cp $(BUILD_HOTPATCH_DIR)/$(VERSIONED_NEWUI_HOTPATCH) $(S3_STAGING_ADDR)/$(VERSIONED_NEWUI_HOTPATCH)
  endif

set-build:
BUILD_VERSION?=$$($(TOOL_CLI) get-build-tag false false)
MINOR_VERSION_DOT?=$$($(TOOL_CLI) get-build-tag true true)
VERSIONED_REMOTE_LOAD_NAME?=$(REMOTE_LOAD_NAME)_$(BUILD_VERSION)
VERSIONED_REMOTE_LOAD_ZIP?=$(VERSIONED_REMOTE_LOAD_NAME).zip
VERSIONED_REMOTE_LOAD_PKG?=$(VERSIONED_REMOTE_LOAD_NAME).pkg
VERSIONED_TARGET?=$(NAME)_$(BUILD_VERSION).zip
VERSIONED_NAME?=$(NAME)_$(BUILD_VERSION)
VERSIONED_OLDUI_HOTPATCH=$(MINOR_VERSION_DOT).oldui.brs
VERSIONED_NEWUI_HOTPATCH=$(MINOR_VERSION_DOT).newui.brs

host:
	@$(TOOL_CLI) host-components $(BUILD_DIR) $(REMOTE_LOAD_PORT)

install: env build pkg-components stage
	@echo "Installing $(NAME) to host $(ROKU_DEV_TARGET)...(this might take up to a minute)"
	@$(TOOL_CLI) upload $(BUILD_DIR)/$(VERSIONED_TARGET) $(ROKU_DEV_TARGET) $(DEV_PASSWORD)
	@$(MAKE) -j2 dev host

pkg-components: set-build
	@echo "Signing $(VERSIONED_REMOTE_LOAD_ZIP) on host $(ROKU_DEV_TARGET)"
	@$(TOOL_CLI) upload $(BUILD_DIR)/$(VERSIONED_REMOTE_LOAD_ZIP) $(ROKU_DEV_TARGET) $(DEV_PASSWORD)
	@$(TOOL_CLI) sign-package $(ROKU_DEV_TARGET) $(DEV_PASSWORD) $(PKG_PASSWORD) $(VERSIONED_REMOTE_LOAD_NAME) $(BUILD_DIR)

pkg: pkg-components
	@echo "Signing $(VERSIONED_TARGET) on host $(ROKU_DEV_TARGET)"
	@$(TOOL_CLI) upload $(BUILD_DIR)/$(VERSIONED_TARGET) $(ROKU_DEV_TARGET) $(DEV_PASSWORD)
	@$(TOOL_CLI) sign-package $(ROKU_DEV_TARGET) $(DEV_PASSWORD) $(PKG_PASSWORD) $(VERSIONED_NAME) $(BUILD_DIR)

dev: env
	@echo "Telnet to $(ROKU_DEV_TARGET) 8085"
	@telnet $(ROKU_DEV_TARGET) 8085

env:
ifndef ROKU_DEV_TARGET
	$(error ROKU_DEV_TARGET is not set. Please use "export ROKU_DEV_TARGET=<roku-ip>" to set it)
endif

discover:
	@$(TOOL_CLI) discover

test:
	NODE_PATH=${PWD}/tools/node_modules jasmine

clean:
	@rm -rf ./$(BUILD_DIR)

verifyrepo:
	@clean=$$(git status --porcelain); \
  if test "x$${clean}" != x; then \
    echo Working directory is dirty >&2; \
		exit 1; \
  fi

release: verifyrepo set-build
	@$(TOOL_CLI) increment-build-number
	@git commit -m "incrementbuild: Bump build number" config/build.yml
	@echo "Tagging $$($(TOOL_CLI) get-build-tag false false)"
	@$(TOOL_CLI) get-build-tag false false | xargs git tag
	@$(MAKE) ROKU_PROFILE=production build pkg
	@echo
	@echo "If you are intending this to be a formal release, create a pull request for the current branch"
	@echo "    git branch release_$$($(TOOL_CLI) get-build-tag false false)"
	@echo "    git push origin release_$$($(TOOL_CLI) get-build-tag false false)"
	@echo "Remember to push the new tag to remote with 'git push --tags origin'"
	@echo

.PHONY: build zip rsync install dev gen discover test clean verifyrepo release pkg pkg-components stage set-build
