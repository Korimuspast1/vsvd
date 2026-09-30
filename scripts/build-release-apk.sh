#!/bin/sh
# Produces the VSVD release APK after the developer has installed the Android
# toolchain and created the ignored vsvd-signing.properties file.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM="$ROOT/upstream/telegram-android"

"$ROOT/scripts/apply-vsvd-patches.sh"

if ! command -v java >/dev/null 2>&1; then
    echo "Java is required. Install JDK 17 and set JAVA_HOME before building." >&2
    exit 1
fi
if [ ! -f "$ROOT/vsvd-signing.properties" ]; then
    echo "Missing vsvd-signing.properties. Copy vsvd-signing.properties.example and configure your own release key." >&2
    exit 1
fi

cd "$UPSTREAM"
exec ./gradlew :TMessagesProj_App:assembleAfatRelease
