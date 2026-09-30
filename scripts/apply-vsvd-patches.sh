#!/bin/sh
# Applies VSVD's small, reviewable patch set to the pinned official Telegram
# Android source. It never downloads code and refuses an unexpected upstream.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM="$ROOT/upstream/telegram-android"
PATCH="$ROOT/patches/telegram-android/0001-vsvd-brand-credentials-and-features.patch"
EXPECTED_REVISION="dc780e81ed1261c369c27870e8e0999a1eb0b600"

if [ ! -d "$UPSTREAM/.git" ] && [ ! -f "$UPSTREAM/.git" ]; then
    echo "Official source is not initialized. Run: git submodule update --init --recursive" >&2
    exit 1
fi

ACTUAL_REVISION=$(git -C "$UPSTREAM" rev-parse HEAD)
if [ "$ACTUAL_REVISION" != "$EXPECTED_REVISION" ]; then
    echo "Refusing to apply patches to an unexpected Telegram revision." >&2
    echo "Expected: $EXPECTED_REVISION" >&2
    echo "Actual:   $ACTUAL_REVISION" >&2
    exit 1
fi

# A zero-context patch avoids carrying upstream trailing whitespace into this
# repository, so detect its explicit VSVD marker instead of reverse-applying it.
if [ -f "$UPSTREAM/TMessagesProj/src/main/java/org/telegram/vsvd/VsvdBadge.java" ] && \
   grep -q "BuildConfig.VSVD_TELEGRAM_API_ID" "$UPSTREAM/TMessagesProj/src/main/java/org/telegram/messenger/BuildVars.java"; then
    echo "VSVD patches are already applied."
    exit 0
fi

if [ -n "$(git -C "$UPSTREAM" status --porcelain)" ]; then
    echo "Official source has local changes. Start from a clean submodule before applying VSVD patches." >&2
    exit 1
fi

git -C "$UPSTREAM" apply --unidiff-zero --whitespace=error "$PATCH"
echo "Applied VSVD patches to Telegram Android $EXPECTED_REVISION."
