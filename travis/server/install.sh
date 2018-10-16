#!/bin/bash

set -x

source roku.env

ZIP=$1
if [ "x$ZIP" == "x" ]; then
	echo "Usage: $0 <app zip>"
	exit 1
fi

curl \
  -v \
  --user "rokudev:${ROKU_DEV_PASSWORD}" \
  --digest \
  -F "mysubmit=Install" \
  -F "passwd=" \
  -F "archive=@${ZIP}" \
  "http://${ROKU_DEV_TARGET}/plugin_install" > /dev/null


# Response HTML should contain:
#
#     <font color="red">Install Success.</font>
#
