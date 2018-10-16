#!/bin/bash

set -x

source roku.env

REKEYPKG=$1
if [ "x$REKEYPKG" == "x" ]; then
	echo "Usage: $0 <rekey pkg>"
	exit 1
fi

curl \
  -v \
  --user "rokudev:${ROKU_DEV_PASSWORD}" \
  --digest \
  -F "mysubmit=Rekey" \
  -F "passwd=${ROKU_PKG_PASSWORD}" \
  -F "archive=@${REKEYPKG}" \
  "http://${ROKU_DEV_TARGET}/plugin_inspect" > /dev/null


# Response HTML should contain:
#
#     <font color="red">Success.</font>
#
