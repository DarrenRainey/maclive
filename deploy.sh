#!/bin/bash

# Build and deploy MacLive to the Google code download page

if [ $# -ne "2" ] ; then
    echo "Usage: $0 <google code username> <current version #>"
    exit 1
fi

echo +++ Building ...

xcodebuild -project MacLive.xcodeproj -target MacLive -configuration Release

echo +++ Zipping ...

cd build/Release
zip -qr "MacLive_V${2}.zip" MacLive.app
cd ../..

echo +++ Uploading ...

python googlecode-upload.py \
    -s "Current Release" \
    -p "maclive" \
    -u "$1" \
    -l "Featured,Type-Executable,Type-Archive,OpSys-OSX" \
    "build/Release/MacLive_V${2}.zip"

echo +++ All Done!
