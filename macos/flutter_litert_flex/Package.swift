// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_litert_flex",
    platforms: [
        .macOS("10.14")
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
        .binaryTarget(
            name: "flutter_litert_flex_framework",
            url: "https://github.com/hugocornellier/flutter_litert/releases/download/flex-v1.1.0/flutter_litert_flex-macos-spm.xcframework.zip",
            checksum: "36b1a080a0f9be92aa2eb85fcebff49a63957f84c2f64f4b0464320cdf72bcfc"
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
