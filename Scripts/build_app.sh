#!/bin/bash
# Builds AirLLM.app and installs it into ~/Applications, or the folder given as $1.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/build/AirLLM.app"
DEST="${1:-$HOME/Applications}"
RESOURCES="$APP/Contents/Resources"

swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$RESOURCES/backend"
cp .build/release/AirLLMMac "$APP/Contents/MacOS/AirLLMMac"
cp backend/*.py "$RESOURCES/backend/"
cp Resources/AirLLMLogo.png "$RESOURCES/"
cp -R Resources/logos "$RESOURCES/logos"

ICONSET="$ROOT/build/AppIcon.iconset"
rm -rf "$ICONSET"
swift Scripts/make_icon.swift Resources/AirLLMLogo.png "$ICONSET"
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"

# NSAllowsLocalNetworking lets the app reach its own server on 127.0.0.1 over plain HTTP.
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>AirLLM</string>
  <key>CFBundleDisplayName</key><string>AirLLM</string>
  <key>CFBundleIdentifier</key><string>local.airllm.chat</string>
  <key>CFBundleExecutable</key><string>AirLLMMac</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsLocalNetworking</key><true/></dict>
</dict>
</plist>
PLIST

# Ad hoc signing, so macOS runs it locally without a developer account.
codesign --force --deep --sign - "$APP"
mkdir -p "$DEST"
rm -rf "$DEST/AirLLM.app"
cp -R "$APP" "$DEST/"
echo "Installed $DEST/AirLLM.app"
