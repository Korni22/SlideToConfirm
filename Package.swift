// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SlideToConfirm",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "SlideToConfirm", targets: ["SlideToConfirm"])
    ],
    targets: [
        .target(name: "SlideToConfirm"),
        .testTarget(
            name: "SlideToConfirmTests",
            dependencies: ["SlideToConfirm"]
        )
    ]
)
