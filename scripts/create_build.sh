#!/bin/sh
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TASK_DERIVED_DATA=${POCKET_MUSIC_DERIVED_DATA:-/tmp/PocketMusicRelease}
cd "$TASK_ROOT"
python3 scripts/update_project_metadata.py
python3 scripts/release.py prepare
TASK_VERSION=$(python3 -c 'import json; print(json.load(open("dist/.release-state.json"))["version"])')
TASK_IPA="dist/SoundBunker-unsigned-$TASK_VERSION.ipa"
xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
  -sdk iphoneos -destination 'generic/platform=iOS' -configuration Release \
  -derivedDataPath "$TASK_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO build
python3 scripts/package_ipa.py \
  "$TASK_DERIVED_DATA/Build/Products/Release-iphoneos/OfflineMusicPlayer.app" \
  "$TASK_IPA"
python3 scripts/release.py finalize --app "$TASK_DERIVED_DATA/Build/Products/Release-iphoneos/OfflineMusicPlayer.app"
shasum -a 256 "$TASK_IPA" "$TASK_IPA.zip"
