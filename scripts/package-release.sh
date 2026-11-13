#!/bin/bash
set -euo pipefail

# Build and notarize release artifacts only. This never installs the app, changes
# repository visibility, pushes a tag, or publishes a GitHub release.
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
cd "$ROOT"
if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Release input must be a clean, reviewed commit." >&2
    exit 1
fi
RELEASE_COMMIT="$(git rev-parse HEAD)"
RELEASE_VERSION="$(awk '/MARKETING_VERSION:/ {gsub(/"/, "", $2); print $2; exit}' project.yml)"
RELEASE_BUILD="$(awk '/CURRENT_PROJECT_VERSION:/ {gsub(/"/, "", $2); print $2; exit}' project.yml)"
[[ "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$RELEASE_BUILD" =~ ^[0-9]+$ ]]
NOTARY_PROFILE="${EXOCAMERA_NOTARY_PROFILE:-notarytool}"
INSTALLER_IDENTITY="${EXOCAMERA_INSTALLER_IDENTITY:-}"
if [[ -z "$INSTALLER_IDENTITY" ]]; then
    INSTALLER_IDENTITY="$(security find-identity -v -p basic | sed -n 's/.*"\(Developer ID Installer:.*\)"/\1/p')"
fi
[[ -n "$INSTALLER_IDENTITY" && "$INSTALLER_IDENTITY" != *$'\n'* ]]
mkdir -p "$ROOT/build"
RELEASE_OUTPUT="$(mktemp -d "$ROOT/build/release-$RELEASE_VERSION.XXXXXX")"
echo "Release artifacts: $RELEASE_OUTPUT"
printf '%s\n' "$RELEASE_COMMIT" > "$RELEASE_OUTPUT/source-commit.txt"
scripts/validate.sh > "$RELEASE_OUTPUT/validation.log" 2>&1
scripts/bootstrap.sh
xcodebuild -project ExoCamera.xcodeproj -scheme ExoCamera -configuration Release \
    -destination 'generic/platform=macOS' -archivePath "$RELEASE_OUTPUT/ExoCamera.xcarchive" \
    -allowProvisioningUpdates archive > "$RELEASE_OUTPUT/archive.log" 2>&1
ARCHIVED_APP="$RELEASE_OUTPUT/ExoCamera.xcarchive/Products/Applications/Exo Camera.app"
RELEASE_TEAM="$(codesign -d --verbose=4 "$ARCHIVED_APP" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
[[ "$RELEASE_TEAM" =~ ^[A-Z0-9]+$ ]]
[[ "$INSTALLER_IDENTITY" == *"($RELEASE_TEAM)" ]]
python3 - "$RELEASE_OUTPUT/ExportOptions.plist" "$RELEASE_TEAM" <<'PY'
import plistlib,sys
with open(sys.argv[1],'wb') as f:
    plistlib.dump({'method':'developer-id','signingStyle':'automatic','teamID':sys.argv[2]},f)
PY
xcodebuild -exportArchive -archivePath "$RELEASE_OUTPUT/ExoCamera.xcarchive" \
    -exportPath "$RELEASE_OUTPUT/export" -exportOptionsPlist "$RELEASE_OUTPUT/ExportOptions.plist" \
    -allowProvisioningUpdates > "$RELEASE_OUTPUT/export.log" 2>&1
RELEASE_APP="$RELEASE_OUTPUT/export/Exo Camera.app"
python3 scripts/verify-release.py "$RELEASE_APP" --version "$RELEASE_VERSION" --build "$RELEASE_BUILD" \
    > "$RELEASE_OUTPUT/app-verification.json"

notarize() {
    local artifact="$1" name="$2" submission
    xcrun notarytool submit "$artifact" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json \
        > "$RELEASE_OUTPUT/$name-notary.json"
    submission="$(python3 - "$RELEASE_OUTPUT/$name-notary.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1])); print(r['id'])
PY
)"
    xcrun notarytool log "$submission" --keychain-profile "$NOTARY_PROFILE" \
        "$RELEASE_OUTPUT/$name-notary-log.json"
    python3 - "$RELEASE_OUTPUT/$name-notary.json" <<'PY'
import json,sys
assert json.load(open(sys.argv[1]))['status']=='Accepted', 'Notarization was not accepted'
PY
}

# Staple the inner app before building the final package, giving both their own
# offline tickets. Notarizing the package also scans its nested application code.
ditto -c -k --keepParent "$RELEASE_APP" "$RELEASE_OUTPUT/app-submission.zip"
notarize "$RELEASE_OUTPUT/app-submission.zip" app
xcrun stapler staple "$RELEASE_APP"
xcrun stapler validate "$RELEASE_APP"
spctl --assess --type execute --verbose=2 "$RELEASE_APP"

PACKAGE_SCRIPTS="$RELEASE_OUTPUT/package-scripts"
PACKAGE_RESOURCES="$RELEASE_OUTPUT/package-resources"
mkdir -p "$PACKAGE_SCRIPTS" "$PACKAGE_RESOURCES"
ditto "$RELEASE_APP" "$PACKAGE_SCRIPTS/Exo Camera.app"
cp scripts/installer-transaction.applescript "$PACKAGE_SCRIPTS/"
cp Resources/Installer/postinstall "$PACKAGE_SCRIPTS/"
chmod 755 "$PACKAGE_SCRIPTS/postinstall"
cp Resources/Installer/welcome.html Resources/Installer/conclusion.html LICENSE "$PACKAGE_RESOURCES/"
pkgbuild --nopayload --scripts "$PACKAGE_SCRIPTS" --identifier ai.kortexa.exocamera.installer \
    --version "$RELEASE_VERSION" --sign "$INSTALLER_IDENTITY" --timestamp \
    "$RELEASE_OUTPUT/Exo Camera Component.pkg"
RELEASE_PACKAGE="$RELEASE_OUTPUT/ExoCamera-$RELEASE_VERSION.pkg"
productbuild --distribution Resources/Installer/Distribution.xml --resources "$PACKAGE_RESOURCES" \
    --package-path "$RELEASE_OUTPUT" --sign "$INSTALLER_IDENTITY" --timestamp "$RELEASE_PACKAGE"
python3 scripts/validate-installer-package.py "$RELEASE_PACKAGE" --version "$RELEASE_VERSION" --build "$RELEASE_BUILD"
notarize "$RELEASE_PACKAGE" installer
xcrun stapler staple "$RELEASE_PACKAGE"
xcrun stapler validate "$RELEASE_PACKAGE"
pkgutil --check-signature "$RELEASE_PACKAGE"
spctl --assess --type install --verbose=2 "$RELEASE_PACKAGE"
python3 scripts/verify-release.py "$RELEASE_APP" --version "$RELEASE_VERSION" --build "$RELEASE_BUILD" \
    > "$RELEASE_OUTPUT/app-verification.json"

# Payload-free uninstallers let a regular user remove the protected app with Installer and
# a password prompt. They must be signed by the same team as the app they remove.
build_uninstaller() {
    local product="$1" name="$2" identifier="$3" output="$4" work="$RELEASE_OUTPUT/uninstaller-$1"
    mkdir -p "$work/scripts" "$work/resources"
    cp "Resources/Uninstaller/$product/postinstall" Resources/Uninstaller/uninstall-product.sh "$work/scripts/"
    chmod 755 "$work/scripts/postinstall" "$work/scripts/uninstall-product.sh"
    cp "Resources/Uninstaller/$product/welcome.html" "Resources/Uninstaller/$product/conclusion.html" "$work/resources/"
    pkgbuild --nopayload --scripts "$work/scripts" --identifier "$identifier" --version 1 \
        --sign "$INSTALLER_IDENTITY" --timestamp "$work/$name Uninstaller Component.pkg"
    productbuild --distribution "Resources/Uninstaller/$product/Distribution.xml" --resources "$work/resources" \
        --package-path "$work" --sign "$INSTALLER_IDENTITY" --timestamp "$RELEASE_OUTPUT/$output"
    python3 scripts/validate-installer-package.py "$RELEASE_OUTPUT/$output" --uninstaller "$product"
    notarize "$RELEASE_OUTPUT/$output" "uninstaller-$product"
    xcrun stapler staple "$RELEASE_OUTPUT/$output"
    xcrun stapler validate "$RELEASE_OUTPUT/$output"
    spctl --assess --type install --verbose=2 "$RELEASE_OUTPUT/$output"
}
EXO_UNINSTALLER="Uninstall-ExoCamera-$RELEASE_VERSION.pkg"
build_uninstaller ExoCamera "Exo Camera" ai.kortexa.exocamera.uninstaller "$EXO_UNINSTALLER"
# The legacy AI Camera uninstaller ships once, in the standalone `uninstall-aicamera` release,
# not with every Exo Camera release. To rebuild it, call:
#   build_uninstaller AICamera "AI Camera" ai.kortexa.aicamera.uninstaller Uninstall-AICamera.pkg
cp "docs/releases/$RELEASE_VERSION.md" "$RELEASE_OUTPUT/RELEASE-NOTES.md"
cp NOTICE "$RELEASE_OUTPUT/NOTICE"
(cd "$RELEASE_OUTPUT" && shasum -a 256 "ExoCamera-$RELEASE_VERSION.pkg" "$EXO_UNINSTALLER" > SHA256SUMS)
echo "Verified and notarized: $RELEASE_PACKAGE"
