#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Building Statify ($CONFIG)"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
swift build -c "$CONFIG"

APP="$ROOT/build/Statify.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/Statify" "$APP/Contents/MacOS/Statify"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

if [ -f "$ROOT/Resources/Statify.icns" ]; then
	cp "$ROOT/Resources/Statify.icns" "$APP/Contents/Resources/Statify.icns"
fi

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "$APP"

echo "==> Built $APP"
