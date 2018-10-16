#!/bin/bash

set -x

source roku.env

APPNAMEVERSION=$1
if [ "x$APPNAMEVERSION" == "x" ]; then
	echo "Usage: $0 <app name and version>"
	exit 1
fi
APPPKG=./app.pkg
NOW=$(date +%s)
PKGTIME=$(expr ${NOW} * 1000)

curl \
  -v \
  --user "rokudev:${ROKU_DEV_PASSWORD}" \
  --digest \
  -F "mysubmit=Package" \
  -F "app_name=${APPNAMEVERSION}" \
  -F "passwd=${ROKU_PKG_PASSWORD}" \
  -F "pkg_time=${PKGTIME}" \
  "http://${ROKU_DEV_TARGET}/plugin_package" > /dev/null


# Response HTML should contain:
#
#     <font color="red">Success.

PKGNAME=$(curl -v --user "rokudev:${ROKU_DEV_PASSWORD}" --digest "http://${ROKU_DEV_TARGET}/plugin_package" | grep -o '[a-zA-Z0-9]\+\.pkg' | head -n 1)

echo "PKGNAME = ${PKGNAME}"

# Expect:
#
# <label>Currently Packaged Application:</label><div><font face="Courier"><a href="pkgs//Pc12497aa387325f7b55e91bb767b0883.pkg">Pc12497aa387325f7b55e91bb767b0883.pkg</a> <br> package file (2727088 bytes)</font></div>';
# 

curl \
  -v \
  --user "rokudev:${ROKU_DEV_PASSWORD}" \
  --digest \
  -o "${APPPKG}" \
  "http://10.16.80.3/pkgs/${PKGNAME}" > /dev/null
