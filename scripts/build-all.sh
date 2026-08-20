#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="2.0.1"
DIST="$ROOT/dist"
WEB="$ROOT/cross-platform/web"
ELEC="$ROOT/cross-platform/electron"
AND="$ROOT/cross-platform/android"

echo "==> Bundle web"
bash "$ROOT/cross-platform/scripts/bundle-web.sh"

echo "==> Sync web to Electron"
rm -rf "$ELEC/web"
mkdir -p "$ELEC/web"
cp -R "$WEB/css" "$WEB/js" "$WEB/index.packaged.html" "$ELEC/web/"
mv "$ELEC/web/index.packaged.html" "$ELEC/web/index.packaged.html"
# keep packaged html name
cp "$WEB/index.packaged.html" "$ELEC/web/index.packaged.html"
cp -R "$WEB/css" "$ELEC/web/"
cp -R "$WEB/js" "$ELEC/web/"

echo "==> Sync web to Android assets"
rm -rf "$AND/app/src/main/assets/www"
mkdir -p "$AND/app/src/main/assets/www"
cp -R "$WEB/css" "$WEB/js" "$AND/app/src/main/assets/www/"
cp "$WEB/index.packaged.html" "$AND/app/src/main/assets/www/"

echo "==> Electron Windows build"
cd "$ELEC"
npm install --no-fund --no-audit 2>&1 | tail -3
npx electron-builder --win portable --x64 2>&1 | tail -15
WIN_OUT=$(find "$ELEC/dist" -name "ZapIPTV-${VER}-win-x64.exe" 2>/dev/null | head -1)
echo "Windows: $WIN_OUT"

echo "==> Android APK"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/Cellar/openjdk/26.0.1/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
cd "$AND"
if [ ! -f gradlew ]; then
  gradle wrapper --gradle-version 8.11.1 2>&1 | tail -3
fi
chmod +x gradlew
./gradlew assembleRelease 2>&1 | tail -20
APK="$AND/app/build/outputs/apk/release/app-release-unsigned.apk"
echo "Android APK: $APK"

echo "==> Mac Universal DMG"
cd "$ROOT"
xcodegen generate >/dev/null
xcodebuild -project ZapIPTV.xcodeproj -scheme ZapIPTV -configuration Release \
  -destination 'platform=macOS' -derivedDataPath /tmp/zapiptv-universal-200 \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO VALID_ARCHS='arm64 x86_64' \
  CODE_SIGN_IDENTITY='-' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E 'BUILD SUCCEEDED|BUILD FAILED'
APP=$(find /tmp/zapiptv-universal-200/Build/Products/Release -name ZapIPTV.app -maxdepth 3 | head -1)
lipo -info "$APP/Contents/MacOS/ZapIPTV"
mkdir -p "$DIST"
STAGING="/tmp/zapiptv-dmg-200"
rm -rf "$STAGING" && mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/ZapIPTV.app"
ln -s /Applications "$STAGING/Applications"
DMG="$DIST/ZapIPTV-${VER}-universal-installer.dmg"
rm -f "$DMG"
hdiutil create -volname "ZapIPTV $VER" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

mkdir -p "$DIST"
[ -n "$WIN_OUT" ] && cp "$WIN_OUT" "$DIST/"
[ -f "$APK" ] && cp "$APK" "$DIST/ZapIPTV-${VER}-android.apk"

ls -lh "$DIST"
echo "Done $VER"
