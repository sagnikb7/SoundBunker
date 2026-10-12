#!/bin/sh
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TASK_DERIVED_DATA=${POCKET_MUSIC_DERIVED_DATA:-/tmp/PocketMusicRelease}
cd "$TASK_ROOT"
python3 scripts/release.py prepare
xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
  -sdk iphoneos -destination 'generic/platform=iOS' -configuration Release \
  -derivedDataPath "$TASK_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO build
python3 scripts/package_ipa.py \
  "$TASK_DERIVED_DATA/Build/Products/Release-iphoneos/OfflineMusicPlayer.app" \
  dist/SoundBunker-unsigned.ipa
python3 scripts/release.py finalize --app "$TASK_DERIVED_DATA/Build/Products/Release-iphoneos/OfflineMusicPlayer.app"
shasum -a 256 dist/SoundBunker-unsigned.ipa dist/SoundBunker-unsigned.ipa.zip
