// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MeepAPI",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "MeepAPI",
            targets: ["MeepAPI"]
        ),
    ],
    dependencies: [
        // Any external dependencies, e.g.:
        // .package(url: "https://github.com/org/OtherPackage.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MeepAPI",
            dependencies: []
        ),
        .testTarget(
            name: "MeepAPITests",
            dependencies: ["MeepAPI"]
        ),
    ]
)
