// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_litert_flex",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "flutter-litert-flex", targets: ["flutter_litert_flex"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .binaryTarget(
            name: "TensorFlowLiteFlex",
            url: "https://github.com/hugocornellier/flutter_litert/releases/download/flex-v1.1.0/TensorFlowLiteFlex-spm.xcframework.zip",
            checksum: "d79dad540ebc695da7b7217f1b1ff4034dc27a420904473c29f1b55cc4c3c5af"
        ),
        // Separate ObjC target: forces the linker to pull in the flex delegate
        // entry points from TensorFlowLiteFlex, which transitively includes the
        // C++ static initializers that register SELECT_TF_OPS kernels.
        .target(
            name: "flutter_litert_flex_internal",
            dependencies: [.target(name: "TensorFlowLiteFlex")],
            path: "Sources/flutter_litert_flex_internal",
            publicHeadersPath: "",
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("CoreML", .when(platforms: [.iOS])),
                // -all_load ensures ALL .o files from TensorFlowLiteFlex are included
                // so C++ static initializers that register SELECT_TF_OPS kernels run.
                // XNNPack was removed from TFLiteFlex-spm so no duplicate symbols.
                .unsafeFlags(["-all_load"]),
            ]
        ),
        .target(
            name: "flutter_litert_flex",
            dependencies: [
                .target(name: "TensorFlowLiteFlex"),
                .target(name: "flutter_litert_flex_internal"),
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            path: "Sources/flutter_litert_flex",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
