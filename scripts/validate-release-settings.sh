#!/bin/bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." >/dev/null 2>&1 && pwd -P)"
cd "$ROOT"
RELEASE_COMMIT=080cf1958c82956df716b65d8f2474eb9c8b4f68
test "$(git rev-parse 'v0.2.0^{commit}')" = "$RELEASE_COMMIT" || {
    echo "The local v0.2.0 tag does not match the pinned public release." >&2
    exit 1
}
FRAMEWORKS="$ROOT/build/DerivedData-Validation/Build/Products/Debug"
test -d "$FRAMEWORKS/ExoCameraCore.framework" || {
    echo "Run scripts/validate.sh before the release-settings fixture." >&2
    exit 1
}
umask 077
COMPAT_TMP="$(mktemp -d "${TMPDIR:-/tmp}/exocamera-release-settings.XXXXXX")"
trap 'rm -rf "${COMPAT_TMP:?}"' EXIT
# The pinned 0.2.0 release predates the Exo Camera rename; keep its historical source path.
git archive "$RELEASE_COMMIT" Sources/AICameraCore | tar -xf - -C "$COMPAT_TMP"
xcrun swiftc -parse-as-library -O -swift-version 5 \
    -emit-library -emit-module -module-name ExoCameraReleaseCore \
    "$COMPAT_TMP"/Sources/AICameraCore/*.swift \
    -emit-module-path "$COMPAT_TMP/ExoCameraReleaseCore.swiftmodule" \
    -o "$COMPAT_TMP/libExoCameraReleaseCore.dylib"
xcrun swiftc -parse-as-library -O \
    -F "$FRAMEWORKS" -framework ExoCameraCore -Xlinker -rpath -Xlinker "$FRAMEWORKS" \
    -I "$COMPAT_TMP" -L "$COMPAT_TMP" -lExoCameraReleaseCore \
    -Xlinker -rpath -Xlinker "$COMPAT_TMP" \
    scripts/validate-release-settings.swift -o "$COMPAT_TMP/check"
"$COMPAT_TMP/check" "$COMPAT_TMP/synthetic-settings.json"
