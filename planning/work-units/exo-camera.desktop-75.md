# Exo Camera Microphone in WhatsApp for Mac

Issue: https://github.com/kortexa-ai/exo-camera.desktop/issues/75

WhatsApp for Mac (Catalyst, 26.x) enumerates CoreAudio devices itself in `mac_audio_hardware.mm`
and skips any device whose `kAudioDevicePropertyTransportType` is Virtual, Aggregate, or 0. Inputs
also need an input stream whose terminal type is not a speaker type; outputs only need an output
stream. The driver therefore reports PCI instead of Virtual. The host must not identify its own
loopback by transport, so `VirtualMicrophonePolicy` recognizes Exo Camera Microphone by UID and
other loopbacks (BlackHole) by Virtual transport. Driver 0.2.1 (14), host 0.3.2 (60).
Acceptance needs WhatsApp's microphone picker on snappy after the driver update.
