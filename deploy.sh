#!/bin/bash

# Build and deploy MacLive to the Google code download page

if [ $# -ne "1" ] ; then
    echo "Usage: $0 <google code username>"
    exit 1
fi

echo +++ Building ...

xcodebuild -project MacLive.xcodeproj -target MacLive -configuration Release

echo +++ Zipping ...

cd build/Release
zip -qr MacLive.zip MacLive.app
cd ../..

echo +++ Uploading ...

python googlecode-upload.py \
    -s "Current Release" \
    -p "maclive" \
    -u "$1" \
    -l "Featured,Type-Executable,Type-Archive,OpSys-OSX" \
    build/Release/MacLive.zip

echo +++ All Done!
