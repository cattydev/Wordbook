// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Wordbook",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "Wordbook", targets: ["Wordbook"]),
    ],
    targets: [
        .executableTarget(
            name: "Wordbook",
            path: "Sources/Wordbook"
        ),
        .testTarget(
            name: "WordbookTests",
            dependencies: ["Wordbook"],
            path: "Tests/WordbookTests"
        ),
    ]
)
