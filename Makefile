ZIP=zip --quiet -x Makefile -9 -r
CURL=curl
MAKE=make
TOOL_CLI=node tools/cli.js

NAME=tubitv_roku
REMOTE_LOAD_NAME=tubitv_remote_components
SRC_DIR=src
BUILD_DIR=build
TARGET_DIR=$(BUILD_DIR)/local
TARGET_REMOTE_DIR=$(BUILD_DIR)/remote
TARGET=$(NAME).zip
REMOTE_LOAD_ZIP=$(REMOTE_LOAD_NAME).zip
REMOTE_LOAD_PKG=$(REMOTE_LOAD_NAME).pkg
REMOTE_LOAD_PORT=8090
REMOTE_LOAD_RSYNC_INCLUDE=--include 'source' \
  --include 'source/lib' \
  --include 'source/lib/**' \
  --include 'source/3rdparty' \
  --include 'source/3rdparty/**' \
  --include 'components' \
  --include 'components/**' \
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

ifeq ($(ROKU_PROFILE), production)
RSYNC_EXCLUDE=--exclude source/tests --exclude '.keep'
else
RSYNC_EXCLUDE=--exclude '.keep'
endif

build: rsync gen zip
	@echo "Project $(TARGET) is built with profile $(ROKU_PROFILE)."

zip:
	@rm -f ./$(BUILD_DIR)/$(TARGET)
	@rm -f ./$(BUILD_DIR)/$(REMOTE_LOAD_ZIP)

	@cd $(TARGET_DIR); $(ZIP) ../$(TARGET) .
	@cd $(TARGET_REMOTE_DIR); $(ZIP) ../$(REMOTE_LOAD_ZIP) .


rsync:
	@mkdir -p ./$(TARGET_DIR)
	@mkdir -p ./$(TARGET_REMOTE_DIR)
	@rm -rf ./$(TARGET_DIR)/$(TESTS)
	@rm -f ./$(TARGET_DIR)/$(SETTING_FILE)
	@rsync -arvq $(RSYNC_EXCLUDE) $(SRC_DIR)/* $(TARGET_DIR)
	@rsync -arvq $(REMOTE_LOAD_RSYNC_INCLUDE) $(SRC_DIR)/* $(TARGET_REMOTE_DIR)
	@find ./$(TARGET_REMOTE_DIR)/components -name '*.xml' | xargs sed -i '' 's|<script type="text/brightscript" uri="pkg:|<script type="text/brightscript" uri="libpkg:|'

gen:
	@$(TOOL_CLI) create-config $(ROKU_PROFILE) $(TARGET_DIR)/$(SETTING_FILE)
	@$(TOOL_CLI) create-manifest $(ROKU_PROFILE) $(TARGET_DIR)/$(MANIFEST_FILE) $(ORIGINAL_MANIFEST_NAME)
	@$(TOOL_CLI) create-manifest $(ROKU_PROFILE) $(TARGET_REMOTE_DIR)/$(MANIFEST_FILE) $(REMOTE_LOAD_NAME_MANIFEST_NAME)
	@touch $(TARGET_REMOTE_DIR)/source/main.brs

host:
	@$(TOOL_CLI) host-components $(BUILD_DIR)/$(REMOTE_LOAD_PKG) $(REMOTE_LOAD_PORT)

install: env build pkg-components
	@echo "Installing $(NAME) to host $(ROKU_DEV_TARGET)...(this might take up to a minute)"
	@#$(CURL)  -H 'Connection: close' --digest -u "rokudev:1234" -F "mysubmit=Install" -F "archive=@$(TARGET_DIR)/$(TARGET)" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"
	@$(TOOL_CLI) upload $(BUILD_DIR)/$(TARGET) $(ROKU_DEV_TARGET) $(DEV_PASSWORD)
	@$(MAKE) -j2 dev host

pkg-components:
	@echo "Signing $(REMOTE_LOAD_ZIP) on host $(ROKU_DEV_TARGET)"
	@$(TOOL_CLI) upload $(BUILD_DIR)/$(REMOTE_LOAD_ZIP) $(ROKU_DEV_TARGET) $(DEV_PASSWORD)
	@$(TOOL_CLI) sign-package $(ROKU_DEV_TARGET) $(DEV_PASSWORD) $(PKG_PASSWORD) $(REMOTE_LOAD_NAME) $(BUILD_DIR)

pkg: pkg-components
	@echo "Signing $(TARGET) on host $(ROKU_DEV_TARGET)"
	@$(TOOL_CLI) upload $(BUILD_DIR)/$(TARGET) $(ROKU_DEV_TARGET) $(DEV_PASSWORD)
	@$(TOOL_CLI) sign-package $(ROKU_DEV_TARGET) $(DEV_PASSWORD) $(PKG_PASSWORD) $(NAME) $(BUILD_DIR)

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

release: clean verifyrepo
	@$(TOOL_CLI) increment-build-number
	@git commit -m "incrementbuild: Bump build number" config/build.yml
	@echo "Tagging $$($(TOOL_CLI) get-build-tag)"
	@$(TOOL_CLI) get-build-tag | xargs git tag
	@$(MAKE) ROKU_PROFILE=production build pkg
	@$(TOOL_CLI) get-build-tag | xargs -I %% mv ./$(BUILD_DIR)/$(TARGET) ./$(BUILD_DIR)/$(NAME)_%%.zip
	@$(TOOL_CLI) get-build-tag | xargs -I %% mv ./$(BUILD_DIR)/$(REMOTE_LOAD_ZIP) ./$(BUILD_DIR)/$(REMOTE_LOAD_NAME)_%%.zip
	@echo
	@echo "If you are intending this to be a formal release, create a pull request for the current branch"
	@echo "    git branch release_$$($(TOOL_CLI) get-build-tag)"
	@echo "    git push origin release_$$($(TOOL_CLI) get-build-tag)"
	@echo "Remember to push the new tag to remote with 'git push --tags origin'"
	@echo

.PHONY: build zip rsync install dev gen discover test clean verifyrepo release pkg
