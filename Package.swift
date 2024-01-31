// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftRater",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SwiftRater",
            targets: ["SwiftRater"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftRater",
            path: "SwiftRater",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "SwiftRaterTests",
            dependencies: ["SwiftRater"],
            path: "SwiftRaterTests",
            exclude: ["Info.plist"]
        ),
    ]
)
