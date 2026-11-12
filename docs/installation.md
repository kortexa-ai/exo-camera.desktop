# Install, repair, and remove Exo Camera

Exo Camera 0.3.1 is an **early alpha**. Everything here uses normal Mac steps: open a package,
click through macOS Installer, and enter your password when macOS asks. You don't need Terminal.

Each [release](https://github.com/kortexa-ai/exo-camera.desktop/releases/tag/v0.3.1) has three packages:

| Package | What it does |
|---|---|
| `ExoCamera-0.3.1.pkg` | Installs or upgrades Exo Camera in Applications. |
| `Uninstall-ExoCamera-0.3.1.pkg` | Removes Exo Camera. |
| `Uninstall-AICamera-0.3.1.pkg` | Removes the old AI Camera app after you move to Exo Camera. |

## Install or upgrade

1. Download `ExoCamera-0.3.1.pkg` from [exo.camera](https://exo.camera) or the
   [GitHub release](https://github.com/kortexa-ai/exo-camera.desktop/releases/tag/v0.3.1).
2. Close calls and Exo Camera Preview tests. Open the package and follow macOS Installer.
   It asks for your password and installs on your startup disk.
3. Open **Exo Camera** in Applications. Its camera icon appears in the menu bar.
4. In the menu panel, choose **Install** for the camera and, if you want it, the microphone.
   Allow camera and microphone access. When macOS asks, turn on Exo Camera under
   **System Settings → General → Login Items & Extensions**.
5. Select **Exo Camera** and, optionally, **Exo Camera Microphone** in your call app.

An upgrade keeps your settings, downloaded models, login, and installed camera and microphone.
Open the package over your existing copy; you don't need to remove it first. The installer only
replaces the app. It doesn't change your camera or microphone, and it doesn't need a restart.

If the app offers an **Update** for the camera or microphone, that is a separate step. macOS may ask
for approval or a restart for a camera update. If you can't restart now, keep using the working
camera and update it later.

## Coming from AI Camera

Exo Camera was called AI Camera through 0.2.1. It is a new app with its own camera and microphone,
so it installs beside AI Camera instead of replacing it. When Exo Camera first opens, it moves your
AI Camera settings, notes, Codex login, and models over. macOS may ask once to let Exo Camera read
an API key that AI Camera saved.

To remove AI Camera:

1. Open AI Camera. In **Settings → General → Virtual Devices**, choose **Remove** for the camera and
   the microphone. Turn off **Open AI Camera at login**, then choose **Quit** in its menu panel.
2. If AI Camera says the camera removal needs a restart, restart your Mac.
3. Open `Uninstall-AICamera-0.3.1.pkg` and enter your password. It removes the AI Camera app,
   its microphone driver if one is left, and its installation records.
4. Select **Exo Camera** and **Exo Camera Microphone** in your call apps.

## Repair

- **The installer failed:** note the message, then open the same package again. A failed install
  puts the previous app back.
- **No camera:** check **System Settings → General → Login Items & Extensions** and **Settings → General → Virtual
  Devices** in Exo Camera. Reopen your call app. If Exo Camera says a restart is pending, restart
  when you can. Don't keep removing and reinstalling the camera.
- **No microphone:** use the microphone **Repair** action when the app offers it. This restarts Mac
  audio, which briefly interrupts other audio apps, so close calls first. Then reopen your call app.
- **Camera or microphone access denied:** use the link in Exo Camera Settings, or go to
  **System Settings → Privacy & Security → Camera / Microphone**. In Exo Camera Settings, choose a
  real camera and microphone as inputs.
- **The app doesn't open:** install the same or a newer package again. Don't turn off Gatekeeper
  or System Integrity Protection.

## Remove Exo Camera

Exo Camera removes its own camera, and the uninstaller removes the rest:

1. Close apps that use Exo Camera. Stop Preview tests and the agent.
2. In **Settings → General**, turn off **Open Exo Camera at login**.
3. In **Settings → General → Virtual Devices**, choose **Remove** for the camera and the
   microphone, and follow the macOS prompts.
4. If Exo Camera says the camera removal needs a restart, restart your Mac first.
5. Open `Uninstall-ExoCamera-0.3.1.pkg` and enter your password. It quits Exo Camera if it is
   running, then removes the app, its microphone driver if one is left, and its installation records.
6. Reopen your call apps so their camera and microphone lists refresh.

You can't drag Exo Camera to the Trash. The installer locks the app so that other software can't
replace it, and only the signed uninstaller can unlock it.

The uninstaller stops without changing anything if Exo Camera's camera is still registered.
Only Exo Camera can remove its own camera. Go back to step 3, or install Exo Camera again to get
its **Remove** button back. If the camera won't go away, you can also turn it off under
**System Settings → General → Login Items & Extensions**. Don't delete files in
`/Library/SystemExtensions` or turn off System Integrity Protection.

### Settings, models, and sign-in

The uninstaller keeps your settings for a future reinstall. To remove them too:

1. Before you uninstall, choose **Sign Out** for Exo Camera's Codex login and remove its API key in
   Settings. If the app is already gone, install it again to use these controls.
2. After you uninstall, use Finder's **Go → Go to Folder** and move these to the Trash:
   - `~/Library/Application Support/Exo Camera` (settings, downloaded models, Codex login)
   - `~/Library/Preferences/ai.kortexa.exocamera.plist` (quick controls and windows)
   - `~/Library/Caches/ai.kortexa.exocamera`, if it is there

In Keychain Access you can also delete the `ai.kortexa.exocamera` API-key items. Don't delete every
`Codex Auth` item: that can sign other Codex apps out.

Developers: signed builds and local installation are in [development.md](development.md).
