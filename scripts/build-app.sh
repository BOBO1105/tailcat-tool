#!/usr/bin/env bash
set -euo pipefail

TASK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
bash "$TASK_ROOT/scripts/build-icon.sh"
swift build -c release --product TailcatManager
TASK_BIN="$(swift build -c release --show-bin-path)"
TASK_APP="$TASK_ROOT/dist/Tailcat Manager.app"
mkdir -p "$TASK_APP/Contents/MacOS" "$TASK_APP/Contents/Resources"
cp "$TASK_BIN/TailcatManager" "$TASK_APP/Contents/MacOS/TailcatManager"
cp "$TASK_ROOT/resources/Info.plist" "$TASK_APP/Contents/Info.plist"
cp "$TASK_ROOT/resources/AppIcon.icns" "$TASK_APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$TASK_APP"
codesign --verify --deep --strict "$TASK_APP"
TASK_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' resources/Info.plist)"
TASK_ZIP="$TASK_ROOT/dist/Tailcat-Manager-${TASK_VERSION}.zip"
ditto -c -k --sequesterRsrc --keepParent "$TASK_APP" "$TASK_ZIP"
printf '%s\n' "$TASK_APP"
printf '%s\n' "$TASK_ZIP"
