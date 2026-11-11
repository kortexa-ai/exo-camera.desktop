import Foundation

/// One-time carry-over from the app's former "AI Camera" identity.
enum LegacyAICameraMigration {
    static let legacyKeychainService = "ai.kortexa.aicamera"
    static let legacyAudioDeviceUID = "ai.kortexa.aicamera.audio.device"

    /// Moves the former support folder (profile, notes, Codex login, downloaded models) once,
    /// then points a saved virtual-microphone selection at the renamed device. Runs before any
    /// controller opens the folder. A failed move leaves the legacy folder untouched.
    static func migrateSupportDirectory(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let legacy = base.appendingPathComponent("AI Camera", isDirectory: true)
        let current = base.appendingPathComponent("Exo Camera", isDirectory: true)
        guard fileManager.fileExists(atPath: legacy.path),
              !fileManager.fileExists(atPath: current.path),
              (try? fileManager.moveItem(at: legacy, to: current)) != nil else { return }

        let profile = current.appendingPathComponent("profile.json")
        guard let text = try? String(contentsOf: profile, encoding: .utf8),
              text.contains(legacyAudioDeviceUID) else { return }
        let migrated = text.replacingOccurrences(of: legacyAudioDeviceUID, with: ExoCameraAudioDevice.uid)
        try? migrated.write(to: profile, atomically: true, encoding: .utf8)
    }
}
