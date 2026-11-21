// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AirLLMMac",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AirLLMMac",
            path: "Sources/AirLLMMac"
        ),
        .testTarget(
            name: "AirLLMMacTests",
            dependencies: ["AirLLMMac"],
            path: "Tests/AirLLMMacTests"
        ),
    ]
)
