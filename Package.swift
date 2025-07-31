// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlaylistToAIFFConverter",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "PlaylistToAIFFConverter",
            targets: ["PlaylistToAIFFConverter"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "PlaylistToAIFFConverter",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "PlaylistToAIFFConverterTests",
            dependencies: ["PlaylistToAIFFConverter"],
            path: "Tests"
        ),
    ]
)
