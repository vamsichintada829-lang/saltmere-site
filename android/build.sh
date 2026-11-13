#!/usr/bin/env bash
# Builds Pinecrest Rally APK from ../rally/index.html (no Gradle needed).
# Needs: ANDROID_SDK (platforms;android-34, build-tools;34.0.0), JDK 17+, curl.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SDK="${ANDROID_SDK:-/root/android/sdk}"
BT="$SDK/build-tools/35.0.0"; JAR="$SDK/platforms/android-34/android.jar"
OUT="$HERE/build"; KS="${KEYSTORE:-$HOME/.android/pinecrest-release.jks}"
rm -rf "$OUT"; mkdir -p "$OUT/assets/www" "$OUT/res" "$OUT/classes" "$OUT/dex"

# 1. web assets: full HTML document, three.js bundled for offline play
curl -sSfL -o "$OUT/assets/www/three.min.js" https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js
{ printf '<!doctype html>\n<html lang="en"><head><meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">\n'
  sed 's|https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js|three.min.js|' "$HERE/../rally/index.html"
  printf '\n</html>\n'; } > "$OUT/assets/www/index.html"

# 2. resources + manifest
"$BT/aapt2" compile --dir "$HERE/res" -o "$OUT/res.zip"
"$BT/aapt2" link -o "$OUT/base.apk" -I "$JAR" --manifest "$HERE/AndroidManifest.xml" -A "$OUT/assets" "$OUT/res.zip" --min-sdk-version 24 --target-sdk-version 34

# 3. code
javac -nowarn -Xlint:-options -source 8 -target 8 -bootclasspath "$JAR" -d "$OUT/classes" $(find "$HERE/src" -name '*.java')
(cd "$OUT/classes" && jar cf "$OUT/classes.jar" .)
"$BT/d8" --release --min-api 24 --lib "$JAR" --output "$OUT/dex" "$OUT/classes.jar"
(cd "$OUT/dex" && zip -q -j "$OUT/base.apk" classes.dex)

# 4. align + sign
if [ ! -f "$KS" ]; then mkdir -p "$(dirname "$KS")"
  keytool -genkeypair -keystore "$KS" -storepass pinecrest -keypass pinecrest -alias rally -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Pinecrest Rally" >/dev/null 2>&1; fi
"$BT/zipalign" -f -p 4 "$OUT/base.apk" "$OUT/aligned.apk"
"$BT/apksigner" sign --ks "$KS" --ks-pass pass:pinecrest --key-pass pass:pinecrest --ks-key-alias rally --out "$HERE/PinecrestRally.apk" "$OUT/aligned.apk"
"$BT/apksigner" verify "$HERE/PinecrestRally.apk" && ls -lh "$HERE/PinecrestRally.apk"
