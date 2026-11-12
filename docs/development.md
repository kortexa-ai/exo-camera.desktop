# Development builds

Development requires Xcode, XcodeGen, and your own Apple development team and provisioning profiles.
Copy `Config/Local.example.xcconfig` to ignored `Config/Local.xcconfig` and configure signing there.
The host needs the system-extension installation capability; host and extension share matching
application-group entitlements and signing team.

```sh
scripts/bootstrap.sh
scripts/validate.sh                 # No signing, installation, or activation
SIGNING=1 scripts/build.sh           # Signed development build, no installation
scripts/install-app.sh               # Protected signed host installation
```

The development and production installers use the same protected transaction. It validates nested
identity before and after private staging, safely replaces only the fixed app, locks the installed
root and generation marker, and rolls back catchable failures. See [the release process](release.md)
for Developer ID archive/export, notarization, and production packaging.

macOS App Management lets only software signed by the app's own team change the locked app. Plain
`sudo chflags`/`rm`, Finder, and unsigned packages fail with `Operation not permitted`. Update with
a signed Installer package that runs the existing postinstall and protected transaction, and remove
with the signed uninstaller packages built by `scripts/package-release.sh`. Don't change privacy
permissions, copy over the app, or remove the camera extension to get around a denial.
