import ExoCameraCore
import XCTest

final class VirtualMicrophonePolicyTests: XCTestCase {
    private let ownUID = "ai.kortexa.exocamera.audio.device"

    func testOwnDeviceQualifiesByUIDWhateverItsTransport() {
        for transport: UInt32? in [fourCC("pci "), fourCC("virt"), nil] {
            XCTAssertTrue(isDestination(uid: ownUID, transport: transport))
        }
    }

    func testOtherDuplexDevicesNeedVirtualTransport() {
        XCTAssertTrue(isDestination(uid: "BlackHole2ch_UID", transport: fourCC("virt")))
        XCTAssertFalse(isDestination(uid: "BlackHole2ch_UID", transport: fourCC("pci ")))
        XCTAssertFalse(isDestination(uid: "usb-headset", transport: fourCC("usb ")))
        XCTAssertFalse(isDestination(uid: nil, transport: fourCC("usb ")))
    }

    func testDestinationNeedsBothDirections() {
        XCTAssertFalse(isDestination(uid: ownUID, transport: fourCC("pci "), input: false))
        XCTAssertFalse(isDestination(uid: ownUID, transport: fourCC("pci "), output: false))
        XCTAssertFalse(isDestination(uid: "BlackHole2ch_UID", transport: fourCC("virt"), output: false))
    }

    private func isDestination(
        uid: String?,
        transport: UInt32?,
        input: Bool = true,
        output: Bool = true
    ) -> Bool {
        VirtualMicrophonePolicy.isPublishingDestination(
            uid: uid,
            ownDeviceUID: ownUID,
            hasInputStreams: input,
            hasOutputStreams: output,
            transportType: transport
        )
    }

    private func fourCC(_ value: String) -> UInt32 {
        value.utf8.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }
}
