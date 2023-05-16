#!/bin/sh -x
BASE_DIR="/Users/stormacq/Documents/amazon/code/amplify/amplify-ios-workshop"
SOURCE_DIR="${BASE_DIR}/workshop-hugo/instructions"
DESTINATION_DIR="${BASE_DIR}/workshop-aws/amplify-ios-workshop"
docker run --rm -it \
           -v $(pwd):/src \
           -v "${SOURCE_DIR}":/workshop-src \
           -v "${DESTINATION_DIR}":/workshop-dst \
       swift:5.7-amazonlinux2 \
       /bin/bash