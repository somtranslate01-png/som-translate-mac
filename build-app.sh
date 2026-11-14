#!/bin/bash
# Builds "Som Translate.app" (Apple Silicon + Intel) and a zip of it. Run on a Mac with Xcode or the Command Line Tools.
set -e
cd "$(dirname "$0")"
swift build -c release --arch arm64 --arch x86_64
APP="build/Som Translate.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS"
cp .build/apple/Products/Release/SomTranslateMac "$APP/Contents/MacOS/SomTranslateMac"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"   # (ad-hoc: no Developer account yet; macOS will warn on first open)
(cd build && zip -qr SomTranslateMac.zip "Som Translate.app")
echo "done: build/SomTranslateMac.zip"
