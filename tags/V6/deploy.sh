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

# this lousy upload script doesn't work, it gives permission
# denied every time

echo +++ But the upload script is broken, so you will have to do it through the web interface

#python googlecode-upload.py \
#    -s "Current Release" \
#    -p "maclive" \
#    -u "$1" \
#    -l "Featured,Type-Executable,Type-Archive,OpSys-OSX" \
#    "build/Release/MacLive_V${2}.zip"

echo +++ All Done!
