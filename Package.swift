// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "ReceiptBrain",
    platforms: [
        .iOS(.v18),
        .macOS(.v13),
    ],
    products: [
        .library(name: "ReceiptBrain", targets: ["ReceiptBrain"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ReceiptBrain",
            dependencies: [
            ],
            path: "ReceiptBrain"
        ),
        .testTarget(
            name: "ReceiptBrainTests",
            dependencies: ["ReceiptBrain"],
            path: "ReceiptBrainTests"
        ),
    ]
)
