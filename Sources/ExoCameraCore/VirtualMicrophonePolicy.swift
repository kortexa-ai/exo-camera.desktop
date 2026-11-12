import Foundation

/// Decides which duplex audio devices Exo Camera can publish its microphone mix into.
public enum VirtualMicrophonePolicy {
    private static let virtualTransport: UInt32 = 0x7669_7274 // 'virt'

    /// Exo Camera Microphone is recognized by UID because its driver reports a non-virtual
    /// transport (call apps such as WhatsApp hide Virtual devices). Other loopback devices,
    /// such as BlackHole, still qualify by their Virtual transport.
    public static func isPublishingDestination(
        uid: String?,
        ownDeviceUID: String,
        hasInputStreams: Bool,
        hasOutputStreams: Bool,
        transportType: UInt32?
    ) -> Bool {
        guard hasInputStreams && hasOutputStreams else { return false }
        return uid == ownDeviceUID || transportType == virtualTransport
    }
}
