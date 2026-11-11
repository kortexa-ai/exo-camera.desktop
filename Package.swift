// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ExoCamera",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ExoCameraCore", targets: ["ExoCameraCore"]),
    ],
    targets: [
        .target(
            name: "ExoCameraCore",
            path: "Sources/ExoCameraCore"
        ),
        .target(
            name: "ExoCameraShared",
            path: "Sources/ExoCameraShared"
        ),
        .testTarget(
            name: "ExoCameraCoreTests",
            dependencies: ["ExoCameraCore"],
            path: "Tests/ExoCameraCoreTests"
        ),
        .testTarget(
            name: "ExoCameraSharedTests",
            dependencies: ["ExoCameraShared"],
            path: "Tests/ExoCameraSharedTests"
        ),
        // Phase 0 dev tool for the model-rendered overlay layer. Not shipped with the app.
        .executableTarget(
            name: "ExoCameraOverlaySpike",
            path: "Sources/ExoCameraOverlaySpike",
            resources: [.copy("Resources")]
        ),
    ]
)
