#!/usr/bin/env bash
# Bundle web app into a single JS file for Electron / Android WebView
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB="$ROOT/cross-platform/web"
OUT="$WEB/js/app.all.js"

cat > "$OUT" << 'BUNDLE_HEAD'
(function () {
'use strict';
BUNDLE_HEAD

# Strip export keywords and append modules
for f in catalog m3u chinese i18n; do
  sed -E 's/^export (const|function)/\1/g; s/^export \{[^}]+\};//g' "$WEB/js/$f.js" >> "$OUT"
  echo "" >> "$OUT"
done

# Append main app without imports
sed -E '/^import /d' "$WEB/js/app.js" >> "$OUT"

echo "})();" >> "$OUT"
echo "Bundled -> $OUT"

# Packaged index uses bundled script
cp "$WEB/index.html" "$WEB/index.packaged.html"
sed 's|type="module" src="js/app.js"|src="js/app.all.js"|' "$WEB/index.packaged.html" > "$WEB/index.packaged.html.tmp"
mv "$WEB/index.packaged.html.tmp" "$WEB/index.packaged.html"
