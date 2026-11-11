import CoreMediaIO
import Foundation
import XCTest
@testable import ExoCameraShared

final class MediaDemandStateTests: XCTestCase {
    func testCustomPropertyAddressContract() {
        XCTAssertEqual(
            ExoCameraMediaDemandState.cameraDemandProperty.rawValue,
            "4cc_aicd_glob_0000"
        )
        XCTAssertEqual(
            ExoCameraMediaDemandState.cameraDemandSelector,
            CMIOObjectPropertySelector(0x61696364)
        )
    }

    func testCameraSnapshotRoundTrip() throws {
        let snapshot = ExoCameraCameraDemandSnapshot(
            extensionRunID: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            generation: 42,
            sourceClientCount: 2,
            updatedAt: Date(timeIntervalSinceReferenceDate: 123_456.25)
        )
        let data = try XCTUnwrap(ExoCameraMediaDemandState.encodeCameraSnapshot(snapshot))
        XCTAssertFalse(data.isEmpty)
        XCTAssertLessThanOrEqual(
            data.count,
            ExoCameraMediaDemandState.maximumCameraSnapshotBytes
        )
        XCTAssertEqual(ExoCameraMediaDemandState.decodeCameraSnapshot(data), snapshot)
    }

    func testCameraSnapshotRejectsInvalidData() throws {
        XCTAssertNil(ExoCameraMediaDemandState.decodeCameraSnapshot(Data()))
        XCTAssertNil(ExoCameraMediaDemandState.decodeCameraSnapshot(Data("not-json".utf8)))
        XCTAssertNil(ExoCameraMediaDemandState.decodeCameraSnapshot(
            Data(
                repeating: 0,
                count: ExoCameraMediaDemandState.maximumCameraSnapshotBytes + 1
            )
        ))

        let negative = ExoCameraCameraDemandSnapshot(
            extensionRunID: UUID(),
            generation: 0,
            sourceClientCount: -1,
            updatedAt: Date()
        )
        XCTAssertNil(ExoCameraMediaDemandState.encodeCameraSnapshot(negative))
        let negativeData = try JSONEncoder().encode(negative)
        XCTAssertNil(ExoCameraMediaDemandState.decodeCameraSnapshot(negativeData))
    }

    func testCameraSnapshotRejectsNonfiniteDate() {
        let snapshot = ExoCameraCameraDemandSnapshot(
            extensionRunID: UUID(),
            generation: 0,
            sourceClientCount: 0,
            updatedAt: Date(timeIntervalSinceReferenceDate: .infinity)
        )
        XCTAssertNil(ExoCameraMediaDemandState.encodeCameraSnapshot(snapshot))
    }
}
