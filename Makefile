ZIP=zip --quiet -x Makefile -9 -r
CURL=curl
MAKE=make
TOOL_CLI=node tools/cli.js

NAME=tubitv_roku
SRC_DIR=src
TARGET_DIR=build
TARGET=$(NAME).zip
DEV_PORT=8085
DEV_PASSWORD?=1234
ROKU_PROFILE?=dev
SETTING_FILE=source/Settings.brs
MANIFEST_FILE=manifest
TESTS=source/tests

ifeq ($(ROKU_PROFILE), production)
RSYNC_EXCLUDE=--exclude source/tests --exclude '.keep'
else
RSYNC_EXCLUDE=--exclude '.keep'
endif

build: rsync gen zip
	@echo "Project $(TARGET) is built with profile $(ROKU_PROFILE)."

zip:
	@rm -f ./$(TARGET_DIR)/$(TARGET)
	@cd $(TARGET_DIR); $(ZIP) $(TARGET) .

rsync:
	@rm -rf ./$(TARGET_DIR)/$(TESTS)
	@rm -f ./$(TARGET_DIR)/$(SETTING_FILE)
	@rsync -arvq $(RSYNC_EXCLUDE) $(SRC_DIR)/* $(TARGET_DIR)

gen:
	@$(TOOL_CLI) create-config $(ROKU_PROFILE) $(TARGET_DIR)/$(SETTING_FILE)
	@$(TOOL_CLI) create-manifest $(ROKU_PROFILE) $(TARGET_DIR)/$(MANIFEST_FILE)

install: env build
	@echo "Installing $(NAME) to host $(ROKU_DEV_TARGET)...(this might take up to a minute)"
	@#$(CURL)  -H 'Connection: close' --digest -u "rokudev:1234" -F "mysubmit=Install" -F "archive=@$(TARGET_DIR)/$(TARGET)" http://$(ROKU_DEV_TARGET)/plugin_install | grep "<font color" | sed "s/<font color=\"red\">//"
	@$(TOOL_CLI) upload $(TARGET_DIR)/$(TARGET) $(ROKU_DEV_TARGET) $(DEV_PASSWORD)
	@$(MAKE) dev

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

.PHONY: build zip rsync install dev gen discover test
