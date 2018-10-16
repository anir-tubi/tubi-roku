#!/bin/bash

set -x

ROKU_SERVER_IP=4.35.162.155
ROKU_SERVER_PORT=1110
ROKU_SERVER_PATH="~/roku-build"
ROKU_SERVER_USER="roku-server"

ZIP=$1
if [ "x$ZIP" == "x" ]; then
  echo "Usage: $0 <input zip> <output pkg>"
  exit 1
fi

PKG=$1.pkg
if [ "x$PKG" == "x" ]; then
  echo "Usage: $0 <input zip> <output pkg>"
  exit 1
fi

APPNAMEVERSION="tubi/1.0.0"
SSH_OPTIONS=-oStrictHostKeyChecking=no

# First get build output to the server
scp ${SSH_OPTIONS} -P ${ROKU_SERVER_PORT} "${ZIP}" "${ROKU_SERVER_USER}@${ROKU_SERVER_IP}:${ROKU_SERVER_PATH}/app.zip"

# Then install and sign the app
ssh ${SSH_OPTIONS} -p ${ROKU_SERVER_PORT} "${ROKU_SERVER_USER}@${ROKU_SERVER_IP}" "cd ${ROKU_SERVER_PATH} && bash install.sh app.zip"
ssh ${SSH_OPTIONS} -p ${ROKU_SERVER_PORT} "${ROKU_SERVER_USER}@${ROKU_SERVER_IP}" "cd ${ROKU_SERVER_PATH} && bash package.sh \"${APPNAMEVERSION}\""

# Finally, retrieve the signed pkg
scp ${SSH_OPTIONS} -P ${ROKU_SERVER_PORT} "${ROKU_SERVER_USER}@${ROKU_SERVER_IP}:${ROKU_SERVER_PATH}/app.pkg" "${PKG}"

