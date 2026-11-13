#!/usr/bin/env bash
# Builds apk/StreetRush.apk from game/index.html without Gradle.
# Needs: Android SDK with platforms;android-34 and build-tools;34.0.0 (set ANDROID_SDK), JDK, npm, curl.
# Signing: set KEYSTORE, KS_ALIAS and KS_PASS (keep the same keystore for every update).
set -euo pipefail
cd "$(dirname "$0")"
SDK=${ANDROID_SDK:?set ANDROID_SDK}; BT=$SDK/build-tools/34.0.0; JAR=$SDK/platforms/android-34/android.jar
rm -rf build && mkdir -p build/assets build/gen build/classes build/dex
python3 make_offline_html.py ../game/index.html build/assets/index.html
"$BT/aapt2" compile --dir res -o build/res.zip
"$BT/aapt2" link -o build/base.apk -I "$JAR" --manifest AndroidManifest.xml -A build/assets --java build/gen \
  --min-sdk-version 24 --target-sdk-version 34 --version-code 1 --version-name 1.0 build/res.zip
javac -nowarn -Xlint:none -source 8 -target 8 -bootclasspath "$JAR" -classpath "$JAR" -d build/classes \
  build/gen/com/wheelsmart/streetrush/R.java src/com/wheelsmart/streetrush/MainActivity.java
"$BT/d8" --release --lib "$JAR" --min-api 24 --output build/dex $(find build/classes -name '*.class')
cp build/base.apk build/unsigned.apk && (cd build/dex && zip -q -j ../unsigned.apk classes.dex)
"$BT/zipalign" -f -p 4 build/unsigned.apk build/aligned.apk
mkdir -p ../apk
"$BT/apksigner" sign --ks "${KEYSTORE:?}" --ks-key-alias "${KS_ALIAS:?}" --ks-pass "pass:${KS_PASS:?}" --out ../apk/StreetRush.apk build/aligned.apk
echo "built ../apk/StreetRush.apk"
