#!/bin/bash
#
# Convert a Tubi CMS thumbnail sprite strip into a Roku-compatible BIF thumbnail file.
# This is for demostration and only and will only process one sprite strip.
#
#
# Sample Tubi CMS sprite URL: http://images.adrise.tv/mHqxdM3p0GZhXrkz3ICH49arh5g=/img.adrise.tv/301333/5x-0.jpg
#
# Depends on:
#   1) `biftool` from https://sdkdocs.roku.com/display/sdkdoc/Trick+Mode+Support
#   2) `convert` command from ImageMagick
#   3) curl

set -x

SPRITE_URL=$1

if [ "x${SPRITE_URL}" == "x" ]; then
  echo "Usage: $0 <sprite url>"
  exit 1
fi


TMPDIR=`mktemp -d`
BASENAME=`basename "${SPRITE_URL}"`
SPRITE_WIDTH=220
SPRITE_HEIGHT=92


# Download the source sprite image
curl -v "${SPRITE_URL}" > ${BASENAME}

# Chop the sprite into individual frames
convert 5x-0.jpg -crop ${SPRITE_WIDTH}x${SPRITE_HEIGHT} ${TMPDIR}/%08d.jpg

./biftool -v -t 5000 ${TMPDIR}

