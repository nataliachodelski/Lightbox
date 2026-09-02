#!/bin/sh

set -e
cd "$(dirname "$0")"

./regenerate.sh

VERSION=$(sed -n 's/.*MARKETING_VERSION: "\(.*\)".*/\1/p' project.yml)
[ -n "$VERSION" ] || { echo "Could not read MARKETING_VERSION from project.yml"; exit 1; }

rm -rf build/release dist
mkdir -p dist

xcodebuild \
  -project Lightbox.xcodeproj \
  -scheme Lightbox \
  -configuration Release \
  -derivedDataPath build/release \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
  build

APP=build/release/Build/Products/Release/Lightbox.app
ZIP="dist/Lightbox-$VERSION-macOS.zip"

codesign --verify --strict "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

echo
echo "Built Lightbox $VERSION ($(lipo -archs "$APP/Contents/MacOS/Lightbox"))"
echo "Packaged $ZIP"
