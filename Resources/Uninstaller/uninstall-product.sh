#!/bin/bash
# Shared root-side removal for the signed, payload-free uninstaller packages.
# Installer runs it as root from the package's private script payload. It removes only
# the exact, identity-checked paths passed in by the product's postinstall wrapper.
# User settings, models, and Keychain items are kept.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

: "${PRODUCT_NAME:?}" "${HOST_APP:?}" "${HOST_ID:?}" "${HOST_PROCESS:?}" "${EXTENSION_ID:?}"
: "${DRIVER_PATH:?}" "${DRIVER_ID:?}" "${MARKER_DIR:?}" "${RECEIPT_ID:?}"

if [[ "${TARGET_VOLUME:-}" != "/" || "$(id -u)" != "0" ]]; then
    echo "$PRODUCT_NAME can only be removed from the running macOS startup volume." >&2
    exit 1
fi

# A camera extension can only be removed by its own host app. Deleting the host first
# would orphan it, so stop before changing anything if macOS still lists it.
if systemextensionsctl list 2>/dev/null | grep -F -q "$EXTENSION_ID"; then
    echo "$PRODUCT_NAME's camera is still registered. Remove it in $PRODUCT_NAME first, and restart if asked." >&2
    exit 1
fi

bundle_id() {
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null || true
}

# Verify every target before removing anything.
if [[ -d "$HOST_APP" ]]; then
    found="$(bundle_id "$HOST_APP")"
    if [[ -z "$found" ]]; then
        # An interrupted Finder removal can leave only the locked root and an empty Contents.
        left="$(find "$HOST_APP" -mindepth 1 ! -path "$HOST_APP/Contents" | head -1)"
        [[ -z "$left" ]] || { echo "Unexpected contents in $HOST_APP" >&2; exit 1; }
    elif [[ "$found" != "$HOST_ID" ]]; then
        echo "Unexpected app at $HOST_APP: $found" >&2
        exit 1
    fi
fi
if [[ -d "$DRIVER_PATH" && "$(bundle_id "$DRIVER_PATH")" != "$DRIVER_ID" ]]; then
    echo "Unexpected audio driver at $DRIVER_PATH" >&2
    exit 1
fi

if pgrep -x "$HOST_PROCESS" >/dev/null; then
    pkill -x "$HOST_PROCESS" || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -x "$HOST_PROCESS" >/dev/null || break
        sleep 1
    done
    pkill -9 -x "$HOST_PROCESS" || true
fi

if [[ -d "$DRIVER_PATH" ]]; then
    rm -rf "$DRIVER_PATH"
    # Restarting Core Audio drops the removed microphone from device lists.
    killall coreaudiod 2>/dev/null || true
fi
if [[ -e "$HOST_APP" ]]; then
    chflags -R nouchg,noschg "$HOST_APP"
    rm -rf "$HOST_APP"
fi
if [[ -d "$MARKER_DIR" ]]; then
    chflags nouchg,noschg "$MARKER_DIR/install-generation" 2>/dev/null || true
    rm -f "$MARKER_DIR/install-generation"
    rmdir "$MARKER_DIR" 2>/dev/null || echo "Left nonempty $MARKER_DIR in place." >&2
fi
pkgutil --forget "$RECEIPT_ID" >/dev/null 2>&1 || true
echo "$PRODUCT_NAME removed."
