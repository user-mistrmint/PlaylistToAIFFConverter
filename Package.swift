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
        // Add external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "PlaylistToAIFFConverter",
            dependencies: [
                "PlaylistParser",
                "AudioConverter",
                "FileLocator"
            ]
        ),
        .target(
            name: "PlaylistParser",
            dependencies: []
        ),
        .target(
            name: "AudioConverter",
            dependencies: []
        ),
        .target(
            name: "FileLocator",
            dependencies: []
        ),
        .testTarget(
            name: "PlaylistToAIFFConverterTests",
            dependencies: ["PlaylistToAIFFConverter"]
        ),
    ]
)

