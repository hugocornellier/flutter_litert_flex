// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_litert_flex",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flutter-litert-flex", targets: ["flutter_litert_flex"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // This is a *static-library* xcframework (libTensorFlowLiteFlex.a), NOT a
        // `.framework`, and that's deliberate. The flex delegate entry points
        // (tflite_plugin_create_delegate / _destroy_delegate) are only resolved at
        // runtime via DynamicLibrary.process(), so they must be force-loaded into the
        // app or the linker strips them. `-all_load` (below) force-loads `-l` static
        // libraries — but it does NOT reach `-framework`-linked frameworks, and SPM
        // only *embeds* a framework xcframework rather than linking it, so shipping a
        // `.framework` left those symbols undefined under SPM. A static-library
        // xcframework makes SPM link it with `-l`, so `-all_load` pulls in the
        // SELECT_TF_OPS registrars. (The slice binary is already an `ar` archive, so
        // repackaging is just: rename it to libTensorFlowLiteFlex.a and run
        // `xcodebuild -create-xcframework -library`.)
        //
        // Consumers must also link `flutter_litert` — the delegate references core
        // TFLite symbols (TfLiteTensor*, XNNPack) that flutter_litert provides.
        // Simulator slice is arm64-only (Apple Silicon); see flutter_litert's README
        // for the x86_64-simulator note.
        .binaryTarget(
            name: "TensorFlowLiteFlex",
            url: "https://github.com/hugocornellier/flutter_litert/releases/download/flex-v1.1.1/TensorFlowLiteFlex-spm.xcframework.zip",
            checksum: "7815ab08883f04e94225ab7d0c4af0d5ee6c60c86e587491ec8361c5d0728c9f"
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
