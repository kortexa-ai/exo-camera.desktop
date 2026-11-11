import CoreMedia
import CoreVideo
import XCTest
@testable import ExoCameraShared

final class VirtualCameraConstantsTests: XCTestCase {
    func testSourceFormatIsCameraNativeYUVWhileFeederStaysBGRA() {
        XCTAssertEqual(ExoCameraVirtualCamera.sourcePixelFormat, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        XCTAssertEqual(ExoCameraVirtualCamera.pixelFormat, kCVPixelFormatType_32BGRA)
    }

    func testSourceFrameDurationIsContinuousBetweenOneAndSixtyFramesPerSecond() {
        XCTAssertEqual(ExoCameraVirtualCamera.sourceFrameDuration(clamping: CMTime(value: 1, timescale: 24)),
                       CMTime(value: 1, timescale: 24))
        XCTAssertEqual(ExoCameraVirtualCamera.sourceFrameDuration(clamping: CMTime(value: 1_000_000, timescale: 30_000_000)),
                       CMTime(value: 1_000_000, timescale: 30_000_000))
        XCTAssertEqual(ExoCameraVirtualCamera.sourceFrameDuration(clamping: CMTime(value: 1, timescale: 120)),
                       ExoCameraVirtualCamera.sourceMinFrameDuration)
        XCTAssertEqual(ExoCameraVirtualCamera.sourceFrameDuration(clamping: CMTime(value: 5, timescale: 1)),
                       ExoCameraVirtualCamera.sourceMaxFrameDuration)
    }

    func testUnusableSourceFrameDurationsAreRejected() {
        XCTAssertNil(ExoCameraVirtualCamera.sourceFrameDuration(clamping: .invalid))
        XCTAssertNil(ExoCameraVirtualCamera.sourceFrameDuration(clamping: .zero))
        XCTAssertNil(ExoCameraVirtualCamera.sourceFrameDuration(clamping: CMTime(value: -1, timescale: 30)))
        XCTAssertNil(ExoCameraVirtualCamera.sourceFrameDuration(clamping: .positiveInfinity))
    }

    func testFeederFrameRatesStayWithinTheSourceRange() {
        for rate in ExoCameraVirtualCamera.supportedFrameRates {
            let duration = CMTime.exocameraFrameDuration(rate: rate)
            XCTAssertEqual(ExoCameraVirtualCamera.sourceFrameDuration(clamping: duration), duration)
        }
    }
}
