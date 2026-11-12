# Exo Camera rebrand and 0.3.0 release

Issue: https://github.com/kortexa-ai/exo-camera.desktop/issues/76

Rename AI Camera to Exo Camera across the app, camera extension, HAL driver, app group, device
names/IDs, modules, scripts, installer, and docs. Regenerate the camera device and driver factory
UUIDs so the new devices cannot collide with a legacy extension that stays loaded until restart.
Move the former support folder and Keychain item once on first launch. Release 0.3.0 as a notarized
prerelease, install it on snappy, then remove the legacy AI Camera app, extension, and driver.
The website moves to exo.camera (kortexa-ai/exo.camera#3); this repository no longer deploys Pages.

Follow-up 0.3.1: the locked app can be removed only by a package signed by the same team, so
ship `Uninstall-ExoCamera` and `Uninstall-AICamera` packages, and rewrite the installation guide
without Terminal steps. The developer signing and installation notes move to docs/development.md.
