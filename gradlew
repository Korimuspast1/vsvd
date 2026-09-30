#!/bin/sh
# Lightweight Gradle bootstrap for this repository. It intentionally keeps the
# distribution outside the checkout, like the regular Gradle wrapper.
set -eu

GRADLE_VERSION="8.11.1"
GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
DIST_DIR="$GRADLE_USER_HOME/wrapper/dists/vsvd-gradle-$GRADLE_VERSION"
GRADLE_HOME="$DIST_DIR/gradle-$GRADLE_VERSION"
ARCHIVE="$DIST_DIR/gradle-$GRADLE_VERSION-bin.zip"

if [ ! -x "$GRADLE_HOME/bin/gradle" ]; then
    mkdir -p "$DIST_DIR"
    if [ ! -f "$ARCHIVE" ]; then
        URL="https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip"
        echo "Downloading Gradle $GRADLE_VERSION..." >&2
        if command -v curl >/dev/null 2>&1; then
            curl --fail --location --retry 3 --output "$ARCHIVE.part" "$URL"
        elif command -v wget >/dev/null 2>&1; then
            wget --output-document="$ARCHIVE.part" "$URL"
        else
            echo "curl or wget is required to download Gradle." >&2
            exit 1
        fi
        mv "$ARCHIVE.part" "$ARCHIVE"
    fi
    command -v unzip >/dev/null 2>&1 || {
        echo "unzip is required to extract Gradle." >&2
        exit 1
    }
    unzip -q -o "$ARCHIVE" -d "$DIST_DIR"
fi

exec "$GRADLE_HOME/bin/gradle" -p "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)" "$@"
