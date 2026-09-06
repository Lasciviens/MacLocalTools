// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacLocalTools",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacLocalTools", targets: ["MacLocalTools"])
    ],
    targets: [
        .executableTarget(
            name: "MacLocalTools"
        ),
        .testTarget(
            name: "MacLocalToolsTests",
            dependencies: ["MacLocalTools"]
        )
    ]
)
