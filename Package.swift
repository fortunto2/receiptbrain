// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "ReceiptBrain",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "ReceiptBrain", targets: ["ReceiptBrain"]),
    ],
    dependencies: [
        .package(url: "https://github.com/posthog/posthog-ios.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "ReceiptBrain",
            dependencies: [
                .product(name: "PostHog", package: "posthog-ios"),
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
