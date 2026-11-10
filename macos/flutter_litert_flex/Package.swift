// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_litert_flex",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "flutter-litert-flex", targets: ["flutter_litert_flex"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // flutter_litert_flex.framework bundles libtensorflowlite_flex-mac.dylib
        // as a resource. The Dart code loads it at runtime from:
        //   Frameworks/flutter_litert_flex.framework/Versions/A/Resources/
        // The dylib (arm64) needs macOS 12.0 or newer at run time.
        .binaryTarget(
            name: "flutter_litert_flex_framework",
            url: "https://github.com/hugocornellier/flutter_litert/releases/download/flex-v2.0.0/flutter_litert_flex-macos-spm.xcframework.zip",
            checksum: "4191066d79b2a13155fa21b155aebe640d0b3fe0156b0bda62a7195a0cb5085d"
        ),
        .target(
            name: "flutter_litert_flex",
            dependencies: [
                .target(name: "flutter_litert_flex_framework"),
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/flutter_litert_flex",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
