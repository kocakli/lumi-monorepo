// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "lumi-android",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LumiAndroid", type: .dynamic, targets: ["LumiAndroid"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.8.13"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0"),
        .package(url: "https://github.com/skiptools/skip-firebase.git", from: "0.9.0"),
        .package(url: "https://github.com/skiptools/skip-motion.git", from: "0.7.2"),
    ],
    targets: [
        .target(name: "LumiAndroid", dependencies: [
            .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
            .product(name: "SkipFirebaseCore", package: "skip-firebase"),
            .product(name: "SkipFirebaseAuth", package: "skip-firebase"),
            .product(name: "SkipFirebaseFirestore", package: "skip-firebase"),
            .product(name: "SkipFirebaseFunctions", package: "skip-firebase"),
            .product(name: "SkipFirebaseMessaging", package: "skip-firebase"),
            .product(name: "SkipMotion", package: "skip-motion"),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
