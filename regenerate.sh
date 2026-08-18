#!/bin/sh
# Regenerates SVGScratch.xcodeproj from project.yml.
#
# Always use this instead of a bare `xcodegen generate`: XcodeGen doesn't yet know
# about Apple's Icon Composer ".icon" format (introduced in Xcode 16.2 / macOS 26)
# and emits a generic `lastKnownFileType = folder;` for "App Icon.icon", which Xcode's
# build system doesn't recognize as an app icon source (actool silently ignores it).
# The correct type, `folder.iconcomposer.icon`, is confirmed straight from Xcode's own
# StandardFileTypes.xcspec — this patches it in after every regeneration.

set -e
cd "$(dirname "$0")"

xcodegen generate

sed -i '' '/App Icon\.icon/{s/lastKnownFileType = folder;/lastKnownFileType = folder.iconcomposer.icon;/;}' SVGScratch.xcodeproj/project.pbxproj

echo "Patched App Icon.icon file type in project.pbxproj"
