#!/bin/sh -x

SOURCE_DIR="/Users/stormacq/Documents/amazon/code/amplify/amplify-ios-workshop/BOA332/instructions"
DESTINATION_DIR="/Users/stormacq/Documents/amazon/te/2022/reinvent/BOA332 iOS workshop/workshop/amplify-ios-workshop"
docker run --rm -it \
           -v $(pwd):/src \
           -v "${SOURCE_DIR}":/workshop-src \
           -v "${DESTINATION_DIR}":/workshop-dst \
       swift:5.7-amazonlinux2 \
       /bin/bash