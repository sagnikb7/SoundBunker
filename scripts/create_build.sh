#!/bin/sh
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TASK_PLATFORM=ipod
while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform=*) TASK_PLATFORM=${1#--platform=} ;;
    --platform)
      shift
      if [ "$#" -eq 0 ]; then printf '%s\n' 'Missing value for --platform (ipod or mac).' >&2; exit 2; fi
      TASK_PLATFORM=$1 ;;
    -h|--help)
      printf '%s\n' 'Usage: ./build [--platform=ipod|mac]' 'Default: ipod. iPod produces IPA; Mac produces a local ad-hoc signed .app.'
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
case "$TASK_PLATFORM" in ipod|mac) ;; *) printf 'Unsupported platform: %s (use ipod or mac).\n' "$TASK_PLATFORM" >&2; exit 2 ;; esac
cd "$TASK_ROOT"
mkdir -p dist
TASK_LOCK="$TASK_ROOT/dist/.build-lock"
if ! mkdir "$TASK_LOCK" 2>/dev/null; then
  printf '%s\n' 'Another release build is running. Build platforms sequentially. If a process was killed, remove dist/.build-lock only after confirming no build is running.' >&2
  exit 1
fi
trap 'rmdir "$TASK_LOCK"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
python3 scripts/update_project_metadata.py
python3 scripts/release.py prepare --platform "$TASK_PLATFORM"
TASK_VERSION=$(python3 -c 'import json; print(json.load(open("dist/.release-state.json"))["version"])')
if [ "$TASK_PLATFORM" = ipod ]; then
  TASK_DERIVED_DATA=${POCKET_MUSIC_DERIVED_DATA:-/tmp/PocketMusicRelease}
  TASK_APP="$TASK_DERIVED_DATA/Build/Products/Release-iphoneos/OfflineMusicPlayer.app"
  TASK_IPA="dist/Cassette-unsigned-$TASK_VERSION.ipa"
  xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
    -sdk iphoneos -destination 'generic/platform=iOS' -configuration Release \
    -derivedDataPath "$TASK_DERIVED_DATA" CODE_SIGNING_ALLOWED=NO build
  python3 scripts/package_ipa.py "$TASK_APP" "$TASK_IPA"
  python3 scripts/verify_repository.py --platform ipod --app "$TASK_APP" --ipa "$TASK_IPA"
  python3 scripts/release.py finalize --platform ipod --app "$TASK_APP"
  shasum -a 256 "$TASK_IPA"
else
  TASK_DERIVED_DATA=${CASSETTE_MAC_DERIVED_DATA:-/tmp/CassetteMacRelease}
  TASK_APP="$TASK_DERIVED_DATA/Build/Products/Release-maccatalyst/OfflineMusicPlayer.app"
  TASK_MAC_APP="dist/Cassette.app"
  xcodebuild -project OfflineMusicPlayer.xcodeproj -scheme OfflineMusicPlayer \
    -configuration Release -destination 'platform=macOS,variant=Mac Catalyst' \
    -derivedDataPath "$TASK_DERIVED_DATA" ONLY_ACTIVE_ARCH=NO ARCHS='arm64 x86_64' \
    CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual ENABLE_HARDENED_RUNTIME=NO build
  python3 scripts/package_mac.py "$TASK_APP" "$TASK_MAC_APP"
  python3 scripts/verify_repository.py --platform mac --app "$TASK_MAC_APP"
  python3 scripts/release.py finalize --platform mac --app "$TASK_MAC_APP"
  shasum -a 256 "$TASK_MAC_APP/Contents/MacOS/OfflineMusicPlayer"
fi
